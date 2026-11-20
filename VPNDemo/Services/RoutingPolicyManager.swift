import Foundation
import NetworkExtension

final class RoutingPolicyManager {

    static let shared = RoutingPolicyManager()

    private var chinaIPRanges: [String] = []
    private let chinaIPCacheKey = "cachedChinaIPRanges"

    private init() {
        if let cached = UserDefaults.standard.stringArray(forKey: chinaIPCacheKey) {
            chinaIPRanges = cached
        }
    }

    func preloadChinaIPs() {
        loadChinaIPs { _ in }
    }

    func loadChinaIPs(completion: @escaping ([String]) -> Void) {
        if !chinaIPRanges.isEmpty {
            completion(chinaIPRanges)
            return
        }

        guard let url = URL(string: "https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/china.txt") else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let ranges = text.components(separatedBy: .newlines).filter { $0.contains("/") }
            DispatchQueue.main.async {
                self?.chinaIPRanges = ranges
                if let key = self?.chinaIPCacheKey {
                    UserDefaults.standard.set(ranges, forKey: key)
                }
                completion(ranges)
            }
        }.resume()
    }

    func loadRules() -> [RoutingRule] {
        if let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.savedRules),
           let saved = try? JSONDecoder().decode([RoutingRule].self, from: data) {
            return saved
        }
        return RoutingRule.defaults
    }

    func saveRules(_ rules: [RoutingRule]) {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: AppConstants.UserDefaultsKeys.savedRules)
        }
        NotificationCenter.default.post(name: .routingRulesDidChange, object: nil)
    }

    func buildRoutingConfig(mode: VPNMode, rules: [RoutingRule]) -> RoutingConfig {
        switch mode {
        case .smart:
            return buildSmartConfig(rules: rules)
        case .globalOutbound:
            return RoutingConfig(
                includedRoutes: ["0.0.0.0/0"],
                excludedRoutes: [],
                matchDomains: proxyDomains(from: rules),
                directDomains: directDomains(from: rules),
                description: "所有流量经海外节点转发"
            )
        case .globalInbound:
            return RoutingConfig(
                includedRoutes: ["0.0.0.0/0"],
                excludedRoutes: [],
                matchDomains: proxyDomains(from: rules),
                directDomains: directDomains(from: rules),
                description: "所有流量经国内节点转发"
            )
        }
    }

    /// 将分流配置转成 PacketTunnel 可用的 IPv4 路由。
    func ipv4Routes(from cidrs: [String]?) -> [NEIPv4Route] {
        (cidrs ?? []).compactMap { NEIPv4Route.fromCIDR($0) }
    }

    /// 写入 App Group，供 PacketTunnel 扩展读取 excludedRoutes。
    func persistExcludedRoutesForTunnel(_ cidrs: [String]) {
        guard let url = TunnelIdentity.sharedContainerURL?
            .appendingPathComponent(TunnelIdentity.ConfigKey.excludedCIDRsFile) else {
            return
        }
        let capped = Array(cidrs.prefix(TunnelRouteBuilder.maxExcludedRoutes))
        try? capped.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        TunnelIdentity.sharedDefaults?.set(capped.count, forKey: "excludedCIDRCount")
    }

    private func buildSmartConfig(rules: [RoutingRule]) -> RoutingConfig {
        var includedRoutes: [String] = []
        var excludedRoutes: [String] = []

        for rule in rules where rule.isEnabled {
            switch (rule.matchType, rule.action) {
            case (.ipCIDR, .proxy):
                includedRoutes.append(rule.value)
            case (.ipCIDR, .direct):
                excludedRoutes.append(rule.value)
            default:
                break
            }
        }

        return RoutingConfig(
            includedRoutes: includedRoutes.isEmpty ? nil : includedRoutes,
            excludedRoutes: excludedRoutes + chinaIPRanges,
            matchDomains: proxyDomains(from: rules),
            directDomains: directDomains(from: rules),
            description: "智能分流: 国内直连 + \(proxyDomains(from: rules).count) 条代理域名"
        )
    }

    private func proxyDomains(from rules: [RoutingRule]) -> [String] {
        rules.filter { $0.isEnabled && $0.action == .proxy && $0.matchType != .ipCIDR }.map(\.value)
    }

    private func directDomains(from rules: [RoutingRule]) -> [String] {
        rules.filter { $0.isEnabled && $0.action == .direct && $0.matchType != .ipCIDR }.map(\.value)
    }
}

struct RoutingConfig {
    let includedRoutes: [String]?
    let excludedRoutes: [String]?
    let matchDomains: [String]
    let directDomains: [String]
    let description: String

    var summaryText: String {
        let proxyCount = matchDomains.count
        let directCount = directDomains.count
        let excludeCount = excludedRoutes?.count ?? 0
        return "\(description)（代理域名 \(proxyCount)，直连域名 \(directCount)，直连 IP 段 \(excludeCount)）"
    }
}
