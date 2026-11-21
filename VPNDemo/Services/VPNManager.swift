import Foundation
import NetworkExtension
import UIKit

enum VPNError: LocalizedError {
    case noServerSelected
    case permissionDenied
    case configurationFailed(String)
    case connectionFailed(String)
    case notSupported
    case alreadyConnecting
    case needsPaidDeveloperAccount

    var errorDescription: String? {
        switch self {
        case .noServerSelected: return "请先选择一个节点"
        case .permissionDenied: return "需要 VPN 权限，请前往设置允许"
        case .configurationFailed(let msg): return "配置失败: \(msg)"
        case .connectionFailed(let msg): return "连接失败: \(msg)"
        case .notSupported: return "当前设备不支持"
        case .alreadyConnecting: return "正在连接中，请稍候"
        case .needsPaidDeveloperAccount:
            return "无法创建系统 VPN：需要付费 Apple Developer（Individual/$99），并为 App 与 PacketTunnel 开启 Network Extension。免费 Personal Team 不支持。"
        }
    }
}

extension Notification.Name {
    static let vpnStatusDidUpdate = Notification.Name("vpnStatusDidUpdate")
    static let routingRulesDidChange = Notification.Name("routingRulesDidChange")
}

final class VPNManager {

    static let shared = VPNManager()

    private(set) var status: VPNStatus = .disconnected {
        didSet {
            guard oldValue != status else { return }
            notifyStatus()
        }
    }

    private(set) var currentServer: ServerNode?
    private(set) var currentRouting: RoutingConfig?
    /// true = App 内 Mock；false = Packet Tunnel 扩展
    private(set) var isDemoMode = true
    /// 扩展已拉起但节点为示例域名时的「隧道演示」
    private(set) var isTunnelDemo = false

    var currentMode: VPNMode {
        get {
            if let raw = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.selectedMode),
               let mode = VPNMode(rawValue: raw) {
                return mode
            }
            return .smart
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: AppConstants.UserDefaultsKeys.selectedMode)
        }
    }

    var statusDidChange: ((VPNStatus) -> Void)?

    private(set) var currentBytesSent: Int64 = 0
    private(set) var currentBytesReceived: Int64 = 0
    private(set) var connectedDate: Date?

    private let routingManager = RoutingPolicyManager.shared
    private var tunnelManager: NETunnelProviderManager?
    private var trafficTimer: Timer?
    private var pendingConnectCompletion: ((Result<Void, Error>) -> Void)?
    private var connectTimeoutWorkItem: DispatchWorkItem?
    private var statusObserver: NSObjectProtocol?

    private init() {
        observeTunnelStatus()
        observeRulesChanges()
        loadTunnelManager()
        routingManager.preloadChinaIPs()
    }

    // MARK: - Public

    func connect(to server: ServerNode, mode: VPNMode? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        guard status != .connecting else {
            completion(.failure(VPNError.alreadyConnecting))
            return
        }

        let resolvedMode = mode ?? VPNMode.inferred(from: server.serverType)
        currentServer = server
        currentMode = resolvedMode
        applyRouting(mode: resolvedMode)
        updateStatus(.connecting)

        // 只走系统 Packet Tunnel，失败直接报错（不再静默 Mock）
        connectPacketTunnel(server: server, mode: resolvedMode) { result in
            if case .failure = result {
                self.finishDisconnected()
            }
            completion(result)
        }
    }

    func disconnect(completion: (() -> Void)? = nil) {
        cancelConnectTimeout()
        pendingConnectCompletion = nil
        updateStatus(.disconnecting)

        if let session = tunnelManager?.connection as? NETunnelProviderSession,
           session.status != .disconnected && session.status != .invalid {
            session.stopTunnel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.finishDisconnected()
                completion?()
            }
        } else if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.finishDisconnected()
                completion?()
            }
        } else {
            finishDisconnected()
            completion?()
        }
    }

    func refreshRouting(completion: ((Result<Void, Error>) -> Void)? = nil) {
        applyRouting(mode: currentMode)
        guard status == .connected || status == .connecting, let server = currentServer else {
            completion?(.success(()))
            return
        }
        disconnect { [weak self] in
            self?.connect(to: server, mode: self?.currentMode ?? .smart) { result in
                completion?(result)
            }
        }
    }

    func loadRules() -> [RoutingRule] {
        routingManager.loadRules()
    }

    // MARK: - Routing

    @discardableResult
    private func applyRouting(mode: VPNMode) -> RoutingConfig {
        let rules = routingManager.loadRules()
        let config = routingManager.buildRoutingConfig(mode: mode, rules: rules)
        currentRouting = config
        routingManager.persistExcludedRoutesForTunnel(config.excludedRoutes ?? [])
        return config
    }
}

// MARK: - Packet Tunnel
private extension VPNManager {

    func loadTunnelManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, _ in
            guard let self = self else { return }
            if let existing = managers?.first(where: {
                (($0.protocolConfiguration as? NETunnelProviderProtocol)?
                    .providerBundleIdentifier) == TunnelIdentity.tunnelBundleId
            }) {
                self.tunnelManager = existing
                self.mapSessionStatus(existing.connection.status)
            } else {
                let manager = NETunnelProviderManager()
                let proto = NETunnelProviderProtocol()
                proto.providerBundleIdentifier = TunnelIdentity.tunnelBundleId
                proto.providerConfiguration = [:]
                manager.protocolConfiguration = proto
                manager.localizedDescription = "VPNDemo"
                self.tunnelManager = manager
            }
        }
    }

    func connectPacketTunnel(
        server: ServerNode,
        mode: VPNMode,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        pendingConnectCompletion = completion
        scheduleConnectTimeout()

        let manager = tunnelManager ?? NETunnelProviderManager()
        tunnelManager = manager

        let isExample = server.address.contains("example.com")
        isDemoMode = false
        isTunnelDemo = isExample

        let routing = currentRouting ?? applyRouting(mode: mode)
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = TunnelIdentity.tunnelBundleId
        proto.serverAddress = server.address
        proto.providerConfiguration = [
            TunnelIdentity.ConfigKey.mode: mode.rawValue,
            TunnelIdentity.ConfigKey.serverAddress: server.address,
            TunnelIdentity.ConfigKey.serverPort: server.port,
            TunnelIdentity.ConfigKey.serverName: server.name,
            TunnelIdentity.ConfigKey.isDemo: isExample,
            TunnelIdentity.ConfigKey.mtu: 1400,
            TunnelIdentity.ConfigKey.tunnelIPv4: "10.7.0.2",
            TunnelIdentity.ConfigKey.tunnelSubnet: "255.255.255.0",
            TunnelIdentity.ConfigKey.dnsServers: ["8.8.8.8", "1.1.1.1", "114.114.114.114"],
            TunnelIdentity.ConfigKey.includedCIDRs: routing.includedRoutes ?? ["0.0.0.0/0"]
        ]

        manager.protocolConfiguration = proto
        manager.localizedDescription = "VPNDemo - \(server.name)"
        manager.isEnabled = true
        manager.isOnDemandEnabled = false

        manager.saveToPreferences { [weak self] error in
            guard let self = self else { return }
            if let error {
                self.failTunnelConnect(self.mapTunnelSetupError(error))
                return
            }
            manager.loadFromPreferences { loadError in
                if let loadError {
                    self.failTunnelConnect(self.mapTunnelSetupError(loadError))
                    return
                }
                do {
                    guard let session = manager.connection as? NETunnelProviderSession else {
                        self.failTunnelConnect(VPNError.notSupported)
                        return
                    }
                    try session.startTunnel(options: nil)
                    // connected 由 NEVPNStatus 回调确认
                } catch {
                    self.failTunnelConnect(self.mapTunnelSetupError(error))
                }
            }
        }
    }

    /// 把常见签名 / 权限错误映射成可读提示（免费队最常见）。
    func mapTunnelSetupError(_ error: Error) -> Error {
        let ns = error as NSError
        let text = (ns.localizedDescription + " " + (ns.localizedFailureReason ?? "")).lowercased()
        let entitlementHints = [
            "permission", "entitlement", "missing", "not entitled",
            "configurationinvalid", "plugin", "extension", "neconfiguration"
        ]
        if entitlementHints.contains(where: { text.contains($0) })
            || ns.domain == "NEConfigurationErrorDomain"
            || ns.domain.contains("NEVPN") {
            return VPNError.needsPaidDeveloperAccount
        }
        return VPNError.configurationFailed(error.localizedDescription)
    }

    func failTunnelConnect(_ error: Error) {
        cancelConnectTimeout()
        let completion = pendingConnectCompletion
        pendingConnectCompletion = nil
        completion?(.failure(error))
    }

    func observeTunnelStatus() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            let connection = notification.object as? NEVPNConnection
                ?? self.tunnelManager?.connection
            guard let connection else { return }
            self.mapSessionStatus(connection.status)
        }
    }

    func mapSessionStatus(_ neStatus: NEVPNStatus) {
        // App Mock 期间忽略系统 VPN 状态
        if isDemoMode && tunnelManager?.connection.status == .disconnected {
            return
        }

        switch neStatus {
        case .connected:
            cancelConnectTimeout()
            if connectedDate == nil { connectedDate = Date() }
            isDemoMode = false
            updateStatus(.connected)
            startTrafficPolling()
            pendingConnectCompletion?(.success(()))
            pendingConnectCompletion = nil
        case .connecting, .reasserting:
            updateStatus(.connecting)
        case .disconnecting:
            updateStatus(.disconnecting)
        case .disconnected, .invalid:
            cancelConnectTimeout()
            if pendingConnectCompletion != nil && !isDemoMode {
                // startTunnel 后立刻 disconnected → 交给外层走 Mock
                failTunnelConnect(VPNError.connectionFailed("Packet Tunnel 未能建立"))
                finishDisconnected()
            } else if !isDemoMode {
                finishDisconnected()
            }
        @unknown default:
            break
        }
    }
}

// MARK: - Mock fallback
private extension VPNManager {
    func connectMock(completion: @escaping (Result<Void, Error>) -> Void) {
        isDemoMode = true
        isTunnelDemo = false
        pendingConnectCompletion = nil
        cancelConnectTimeout()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, self.status == .connecting || self.status == .disconnected else { return }
            self.connectedDate = Date()
            self.updateStatus(.connected)
            self.startMockTraffic()
            completion(.success(()))
        }
    }

    func startMockTraffic() {
        trafficTimer?.invalidate()
        trafficTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.status == .connected else { return }
            self.currentBytesReceived += Int64.random(in: 1_000...50_000)
            self.currentBytesSent += Int64.random(in: 500...20_000)
        }
    }

    func startTrafficPolling() {
        trafficTimer?.invalidate()
        trafficTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.status == .connected else { return }
            if self.isDemoMode {
                self.currentBytesReceived += Int64.random(in: 1_000...50_000)
                self.currentBytesSent += Int64.random(in: 500...20_000)
            } else if let defaults = TunnelIdentity.sharedDefaults {
                self.currentBytesSent = Int64(defaults.integer(forKey: TunnelIdentity.ConfigKey.bytesSent))
                self.currentBytesReceived = Int64(defaults.integer(forKey: TunnelIdentity.ConfigKey.bytesReceived))
            }
        }
    }

    func stopTraffic() {
        trafficTimer?.invalidate()
        trafficTimer = nil
    }
}

// MARK: - Common
private extension VPNManager {
    func observeRulesChanges() {
        NotificationCenter.default.addObserver(
            forName: .routingRulesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.status == .connected {
                self.refreshRouting()
            } else {
                self.applyRouting(mode: self.currentMode)
            }
        }
    }

    func scheduleConnectTimeout() {
        cancelConnectTimeout()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.status == .connecting else { return }
            self.failTunnelConnect(VPNError.connectionFailed("连接超时"))
            (self.tunnelManager?.connection as? NETunnelProviderSession)?.stopTunnel()
        }
        connectTimeoutWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: work)
    }

    func cancelConnectTimeout() {
        connectTimeoutWorkItem?.cancel()
        connectTimeoutWorkItem = nil
    }

    func finishDisconnected() {
        stopTraffic()
        currentBytesSent = 0
        currentBytesReceived = 0
        connectedDate = nil
        updateStatus(.disconnected)
    }

    func updateStatus(_ newStatus: VPNStatus) {
        if Thread.isMainThread {
            status = newStatus
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.status = newStatus
            }
        }
    }

    func notifyStatus() {
        statusDidChange?(status)
        NotificationCenter.default.post(name: .vpnStatusDidUpdate, object: status)
    }
}
