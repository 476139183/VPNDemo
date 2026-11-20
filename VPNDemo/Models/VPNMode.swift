import Foundation

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

    var iconName: String {
        switch self {
        case .smart: return "arrow.triangle.branch"
        case .globalOutbound: return "globe"
        case .globalInbound: return "house"
        }
    }
}
