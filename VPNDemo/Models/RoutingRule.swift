import Foundation

enum RuleAction: String, Codable, CaseIterable {
    case direct = "direct"
    case proxy = "proxy"

    var displayName: String {
        switch self {
        case .direct: return "直连"
        case .proxy: return "走 VPN"
        }
    }
}

enum RuleMatchType: String, Codable, CaseIterable {
    case domain = "domain"
    case domainSuffix = "domainSuffix"
    case ipCIDR = "ipCIDR"

    var displayName: String {
        switch self {
        case .domain: return "域名"
        case .domainSuffix: return "域名后缀"
        case .ipCIDR: return "IP 段"
        }
    }
}

struct RoutingRule: Codable, Identifiable {
    let id: String
    var matchType: RuleMatchType
    var value: String
    var action: RuleAction
    var note: String
    var isEnabled: Bool

    static let defaults: [RoutingRule] = [
        RoutingRule(
            id: "rule-1",
            matchType: .domainSuffix,
            value: ".github.com",
            action: .proxy,
            note: "GitHub 访问加速",
            isEnabled: true
        ),
        RoutingRule(
            id: "rule-2",
            matchType: .domainSuffix,
            value: ".githubusercontent.com",
            action: .proxy,
            note: "GitHub 资源",
            isEnabled: true
        ),
        RoutingRule(
            id: "rule-3",
            matchType: .domainSuffix,
            value: ".cloudflare.com",
            action: .proxy,
            note: "Cloudflare",
            isEnabled: true
        ),
        RoutingRule(
            id: "rule-4",
            matchType: .domainSuffix,
            value: ".appcenter.ms",
            action: .proxy,
            note: "微软 AppCenter",
            isEnabled: true
        ),
        RoutingRule(
            id: "rule-cn-1",
            matchType: .domainSuffix,
            value: ".qq.com",
            action: .direct,
            note: "腾讯系直连",
            isEnabled: true
        ),
        RoutingRule(
            id: "rule-cn-2",
            matchType: .domainSuffix,
            value: ".163.com",
            action: .direct,
            note: "网易系直连",
            isEnabled: true
        ),
    ]
}
