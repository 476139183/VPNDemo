import Foundation

/// 路由策略由所选节点类型推导，不再由用户手动切换模式。
enum VPNMode: String, Codable, CaseIterable {
    case smart = "smart"
    case globalOutbound = "globalOutbound"
    case globalInbound = "globalInbound"

    var displayName: String {
        switch self {
        case .smart: return "智能分流"
        case .globalOutbound: return "全球出国"
        case .globalInbound: return "全球回国"
        }
    }

    var subtitle: String {
        switch self {
        case .smart: return "国内直连，国外走 VPN"
        case .globalOutbound: return "所有流量经海外节点转发"
        case .globalInbound: return "所有流量经国内节点转发"
        }
    }

    /// 出国节点 → 智能分流；回国节点 → 全球回国。
    static func inferred(from serverType: ServerType) -> VPNMode {
        switch serverType {
        case .outbound: return .smart
        case .inbound: return .globalInbound
        }
    }
}

extension ServerType {
    var routingHint: String {
        switch self {
        case .outbound: return "出国节点：国内直连，国外流量走此节点"
        case .inbound: return "回国节点：流量经此节点访问国内网络"
        }
    }
}
