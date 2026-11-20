import NetworkExtension
import Foundation

final class PacketTunnelProvider: NEPacketTunnelProvider {

    private var udpSession: NWUDPSession?
    private var providerConfig: [String: Any] = [:]
    private var isDemo = true
    private var bytesSent: Int64 = 0
    private var bytesReceived: Int64 = 0
    private var statsTimer: DispatchSourceTimer?

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let proto = protocolConfiguration as? NETunnelProviderProtocol,
              let conf = proto.providerConfiguration else {
            completionHandler(NSError(
                domain: "PacketTunnel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "缺少隧道配置"]
            ))
            return
        }

        providerConfig = conf
        isDemo = (conf[TunnelIdentity.ConfigKey.isDemo] as? Bool) ?? true
        let remote = (conf[TunnelIdentity.ConfigKey.serverAddress] as? String)
            ?? protocolConfiguration.serverAddress
            ?? "127.0.0.1"
        let mode = (conf[TunnelIdentity.ConfigKey.mode] as? String) ?? "smart"
        let port = (conf[TunnelIdentity.ConfigKey.serverPort] as? Int) ?? 51820
        let mtu = (conf[TunnelIdentity.ConfigKey.mtu] as? Int) ?? 1400
        let tunnelIP = (conf[TunnelIdentity.ConfigKey.tunnelIPv4] as? String) ?? "10.7.0.2"
        let subnet = (conf[TunnelIdentity.ConfigKey.tunnelSubnet] as? String) ?? "255.255.255.0"
        let dns = (conf[TunnelIdentity.ConfigKey.dnsServers] as? [String]) ?? ["8.8.8.8", "1.1.1.1"]
        let included = (conf[TunnelIdentity.ConfigKey.includedCIDRs] as? [String]) ?? []
        let excluded = loadExcludedCIDRs()

        let settings = TunnelRouteBuilder.buildSettings(
            remoteAddress: remote,
            mode: mode,
            isDemo: isDemo,
            includedCIDRs: included,
            excludedCIDRs: excluded,
            dnsServers: dns,
            tunnelIPv4: tunnelIP,
            tunnelSubnet: subnet,
            mtu: mtu
        )

        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self = self else { return }
            if let error {
                completionHandler(error)
                return
            }

            if !self.isDemo {
                self.udpSession = self.createUDPSession(
                    to: NWHostEndpoint(hostname: remote, port: String(port)),
                    from: nil
                )
                self.readPacketsFromUDP()
            }

            self.readPacketsFromTUN()
            self.startStatsTimer()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        statsTimer?.cancel()
        statsTimer = nil
        udpSession?.cancel()
        udpSession = nil
        persistStats()
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        persistStats()
        let payload: [String: Any] = [
            TunnelIdentity.ConfigKey.bytesSent: bytesSent,
            TunnelIdentity.ConfigKey.bytesReceived: bytesReceived
        ]
        let data = try? JSONSerialization.data(withJSONObject: payload)
        completionHandler?(data)
    }

    // MARK: - Packet loops

    private func readPacketsFromTUN() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            for (index, packet) in packets.enumerated() {
                self.bytesSent += Int64(packet.count)
                if !self.isDemo, let session = self.udpSession {
                    // 演示级转发：未加自定义加密，真实产品应在此封装协议
                    session.writeDatagram(packet) { _ in }
                }
                _ = protocols[index]
            }
            self.readPacketsFromTUN()
        }
    }

    private func readPacketsFromUDP() {
        udpSession?.setReadHandler({ [weak self] packets, _ in
            guard let self = self, let packets, !packets.isEmpty else { return }
            var protocols: [NSNumber] = []
            var out: [Data] = []
            for packet in packets {
                self.bytesReceived += Int64(packet.count)
                out.append(packet)
                protocols.append(NSNumber(value: AF_INET))
            }
            self.packetFlow.writePackets(out, withProtocols: protocols)
        }, maxDatagrams: NSIntegerMax)
    }

    // MARK: - Helpers

    private func loadExcludedCIDRs() -> [String] {
        guard let url = TunnelIdentity.sharedContainerURL?
            .appendingPathComponent(TunnelIdentity.ConfigKey.excludedCIDRsFile),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains("/") }
    }

    private func startStatsTimer() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in
            self?.persistStats()
        }
        timer.resume()
        statsTimer = timer
    }

    private func persistStats() {
        let defaults = TunnelIdentity.sharedDefaults
        defaults?.set(bytesSent, forKey: TunnelIdentity.ConfigKey.bytesSent)
        defaults?.set(bytesReceived, forKey: TunnelIdentity.ConfigKey.bytesReceived)
    }
}
