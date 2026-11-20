import Foundation
import NetworkExtension
import UIKit
import KeychainAccess

enum VPNError: LocalizedError {
    case noServerSelected
    case permissionDenied
    case configurationFailed(String)
    case connectionFailed(String)
    case notSupported
    case alreadyConnecting

    var errorDescription: String? {
        switch self {
        case .noServerSelected: return "请先选择一个节点"
        case .permissionDenied: return "需要 VPN 权限，请前往设置允许"
        case .configurationFailed(let msg): return "配置失败: \(msg)"
        case .connectionFailed(let msg): return "连接失败: \(msg)"
        case .notSupported: return "当前设备不支持"
        case .alreadyConnecting: return "正在连接中，请稍候"
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
    private(set) var isDemoMode = true

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
    private var trafficTimer: Timer?
    private var pendingConnectCompletion: ((Result<Void, Error>) -> Void)?
    private var connectTimeoutWorkItem: DispatchWorkItem?

    private init() {
        observeNEStatus()
        observeRulesChanges()
        syncStatusFromSystem()
        routingManager.preloadChinaIPs()
    }

    // MARK: - Public

    func connect(to server: ServerNode, mode: VPNMode, completion: @escaping (Result<Void, Error>) -> Void) {
        guard status != .connecting else {
            completion(.failure(VPNError.alreadyConnecting))
            return
        }

        currentServer = server
        currentMode = mode
        applyRouting(mode: mode)

        let useReal = shouldUseRealVPN(for: server)
        isDemoMode = !useReal
        updateStatus(.connecting)

        if useReal {
            connectReal(server: server, mode: mode, completion: completion)
        } else {
            connectMock(completion: completion)
        }
    }

    func disconnect(completion: (() -> Void)? = nil) {
        cancelConnectTimeout()
        pendingConnectCompletion = nil
        updateStatus(.disconnecting)

        if isDemoMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.finishDisconnected()
                completion?()
            }
        } else {
            let manager = NEVPNManager.shared()
            manager.loadFromPreferences { [weak self] _ in
                manager.connection.stopVPNTunnel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if self?.status != .disconnected {
                        self?.finishDisconnected()
                    }
                    completion?()
                }
            }
        }
    }

    /// 已连接时切换模式 / 规则变更后刷新分流配置；真连时会重连。
    func refreshRouting(completion: ((Result<Void, Error>) -> Void)? = nil) {
        applyRouting(mode: currentMode)
        guard status == .connected || status == .connecting, let server = currentServer else {
            completion?(.success(()))
            return
        }
        if isDemoMode {
            completion?(.success(()))
            return
        }
        disconnect { [weak self] in
            self?.connect(to: server, mode: self?.currentMode ?? .smart, completion: { result in
                completion?(result)
            })
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
        return config
    }

    private func shouldUseRealVPN(for server: ServerNode) -> Bool {
        if UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.useRealVPN) as? Bool == false {
            return false
        }
        if UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.useRealVPN) {
            return vpnKeychainSecret() != nil
        }
        // 自动：非示例域名且已有共享密钥时走真连
        guard !server.address.contains("example.com") else { return false }
        return vpnKeychainSecret() != nil
    }
}

// MARK: - Mock
private extension VPNManager {
    func connectMock(completion: @escaping (Result<Void, Error>) -> Void) {
        pendingConnectCompletion = completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, self.status == .connecting else { return }
            self.connectedDate = Date()
            self.updateStatus(.connected)
            self.startTrafficSimulation()
            self.pendingConnectCompletion?(.success(()))
            self.pendingConnectCompletion = nil
        }
    }

    func startTrafficSimulation() {
        trafficTimer?.invalidate()
        trafficTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.status == .connected else { return }
            self.currentBytesReceived += Int64.random(in: 1_000...50_000)
            self.currentBytesSent += Int64.random(in: 500...20_000)
        }
    }

    func stopTrafficSimulation() {
        trafficTimer?.invalidate()
        trafficTimer = nil
    }
}

// MARK: - Real IKEv2
private extension VPNManager {
    func connectReal(server: ServerNode, mode: VPNMode, completion: @escaping (Result<Void, Error>) -> Void) {
        pendingConnectCompletion = completion
        scheduleConnectTimeout()

        let manager = NEVPNManager.shared()
        manager.loadFromPreferences { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.failConnect(VPNError.configurationFailed(error.localizedDescription))
                return
            }

            let protocolConfig = NEVPNProtocolIKEv2()
            protocolConfig.serverAddress = server.address
            protocolConfig.remoteIdentifier = server.address
            protocolConfig.localIdentifier = UIDevice.current.name
            protocolConfig.authenticationMethod = .sharedSecret
            protocolConfig.sharedSecretReference = self.vpnKeychainSecret()
            protocolConfig.username = UserManager.shared.currentUser?.id
            protocolConfig.passwordReference = self.vpnKeychainPassword()
            protocolConfig.useExtendedAuthentication = true
            protocolConfig.disconnectOnSleep = false
            protocolConfig.enablePFS = true
            protocolConfig.deadPeerDetectionRate = .medium

            protocolConfig.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
            protocolConfig.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA384
            protocolConfig.ikeSecurityAssociationParameters.diffieHellmanGroup = .group14
            protocolConfig.ikeSecurityAssociationParameters.lifetimeMinutes = 1440

            protocolConfig.childSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
            protocolConfig.childSecurityAssociationParameters.integrityAlgorithm = .SHA384
            protocolConfig.childSecurityAssociationParameters.diffieHellmanGroup = .group14
            protocolConfig.childSecurityAssociationParameters.lifetimeMinutes = 1440

            manager.protocolConfiguration = protocolConfig
            manager.isEnabled = true
            manager.isOnDemandEnabled = false
            manager.localizedDescription = "VPNDemo - \(server.name)"

            // IKEv2 无法做真正的客户端分流；智能模式配置已写入 currentRouting，供 UI / 后续 PacketTunnel 使用。
            _ = mode

            manager.saveToPreferences { saveError in
                if let saveError = saveError {
                    self.failConnect(VPNError.configurationFailed(saveError.localizedDescription))
                    return
                }
                manager.loadFromPreferences { reloadError in
                    if let reloadError = reloadError {
                        self.failConnect(VPNError.configurationFailed(reloadError.localizedDescription))
                        return
                    }
                    do {
                        try manager.connection.startVPNTunnel()
                        // 真正 connected 由 NEVPNStatus 回调驱动
                    } catch {
                        self.failConnect(VPNError.connectionFailed(error.localizedDescription))
                    }
                }
            }
        }
    }

    func vpnKeychainSecret() -> Data? {
        let keychain = Keychain(service: "com.vpndemo.vpn")
        return keychain[data: "ikev2_shared_secret"]
    }

    func vpnKeychainPassword() -> Data? {
        let keychain = Keychain(service: "com.vpndemo.vpn")
        return keychain[data: "ikev2_password"]
    }

    func observeNEStatus() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(neStatusChanged),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }

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

    func syncStatusFromSystem() {
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences { [weak self] _ in
            self?.mapNEStatus(manager.connection.status)
        }
    }

    @objc func neStatusChanged() {
        let neStatus = NEVPNManager.shared().connection.status
        DispatchQueue.main.async { [weak self] in
            self?.mapNEStatus(neStatus)
        }
    }

    func mapNEStatus(_ neStatus: NEVPNStatus) {
        // Demo 模式不跟系统 VPN 状态
        guard !isDemoMode else { return }

        switch neStatus {
        case .connected:
            cancelConnectTimeout()
            if connectedDate == nil { connectedDate = Date() }
            updateStatus(.connected)
            startTrafficSimulation()
            pendingConnectCompletion?(.success(()))
            pendingConnectCompletion = nil
        case .connecting, .reasserting:
            updateStatus(.connecting)
        case .disconnecting:
            updateStatus(.disconnecting)
        case .disconnected, .invalid:
            cancelConnectTimeout()
            if pendingConnectCompletion != nil {
                failConnect(VPNError.connectionFailed("连接未建立或已断开"))
            } else {
                finishDisconnected()
            }
        @unknown default:
            break
        }
    }

    func scheduleConnectTimeout() {
        cancelConnectTimeout()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.status == .connecting else { return }
            self.failConnect(VPNError.connectionFailed("连接超时"))
            NEVPNManager.shared().connection.stopVPNTunnel()
        }
        connectTimeoutWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: work)
    }

    func cancelConnectTimeout() {
        connectTimeoutWorkItem?.cancel()
        connectTimeoutWorkItem = nil
    }

    func failConnect(_ error: Error) {
        cancelConnectTimeout()
        let completion = pendingConnectCompletion
        pendingConnectCompletion = nil
        finishDisconnected()
        completion?(.failure(error))
    }

    func finishDisconnected() {
        stopTrafficSimulation()
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
