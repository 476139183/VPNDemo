import Foundation
import NetworkExtension

enum TunnelRouteBuilder {

    /// iOS 对路由条数敏感，国内 IP 列表需截断。
    static let maxExcludedRoutes = 1800

    static func buildSettings(
        remoteAddress: String,
        mode: String,
        isDemo: Bool,
        includedCIDRs: [String],
        excludedCIDRs: [String],
        dnsServers: [String],
        tunnelIPv4: String,
        tunnelSubnet: String,
        mtu: Int
    ) -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: remoteAddress)
        let ipv4 = NEIPv4Settings(addresses: [tunnelIPv4], subnetMasks: [tunnelSubnet])

        if isDemo {
            // 演示模式：不接管默认路由，避免无真实转发时断网
            ipv4.includedRoutes = [
                NEIPv4Route(destinationAddress: "198.18.0.0", subnetMask: "255.254.0.0")
            ]
            ipv4.excludedRoutes = []
        } else if mode == "smart" {
            ipv4.includedRoutes = [NEIPv4Route.default()]
            let capped = Array(excludedCIDRs.prefix(maxExcludedRoutes))
            ipv4.excludedRoutes = capped.compactMap { NEIPv4Route.fromCIDR($0) }
        } else {
            // 全球出国 / 回国：全量进隧道
            if includedCIDRs.isEmpty {
                ipv4.includedRoutes = [NEIPv4Route.default()]
            } else {
                ipv4.includedRoutes = includedCIDRs.compactMap { NEIPv4Route.fromCIDR($0) }
            }
            ipv4.excludedRoutes = []
        }

        settings.ipv4Settings = ipv4
        settings.mtu = NSNumber(value: mtu)
        settings.dnsSettings = NEDNSSettings(servers: dnsServers.isEmpty ? ["8.8.8.8", "1.1.1.1"] : dnsServers)
        settings.dnsSettings?.matchDomains = [""]
        return settings
    }
}
