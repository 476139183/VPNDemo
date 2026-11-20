import Foundation

enum ServerType: String, Codable {
    case outbound
    case inbound

    var displayName: String {
        switch self {
        case .outbound: return "出国节点"
        case .inbound: return "回国节点"
        }
    }
}

struct ServerNode: Codable, Identifiable {
    let id: String
    let name: String
    let country: String
    let countryCode: String
    let address: String
    let port: Int
    let publicKey: String
    let allowedIPs: String
    let serverType: ServerType
    var isSelected: Bool
    var latency: Int?

    var displayName: String {
        return "\(countryCodeFlag) \(name)"
    }

    var countryCodeFlag: String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicode))
            }
        }
        return flag
    }

    static let defaultNodes: [ServerNode] = [
        ServerNode(
            id: "hk-001",
            name: "香港 A",
            country: "Hong Kong",
            countryCode: "HK",
            address: "hk01.example.com",
            port: 51820,
            publicKey: "YOUR_HK_PUBLIC_KEY",
            allowedIPs: "0.0.0.0/0",
            serverType: .outbound,
            isSelected: true,
            latency: nil
        ),
        ServerNode(
            id: "jp-001",
            name: "东京 A",
            country: "Japan",
            countryCode: "JP",
            address: "jp01.example.com",
            port: 51820,
            publicKey: "YOUR_JP_PUBLIC_KEY",
            allowedIPs: "0.0.0.0/0",
            serverType: .outbound,
            isSelected: false,
            latency: nil
        ),
        ServerNode(
            id: "us-001",
            name: "洛杉矶 A",
            country: "United States",
            countryCode: "US",
            address: "us01.example.com",
            port: 51820,
            publicKey: "YOUR_US_PUBLIC_KEY",
            allowedIPs: "0.0.0.0/0",
            serverType: .outbound,
            isSelected: false,
            latency: nil
        ),
        ServerNode(
            id: "bj-001",
            name: "北京 A",
            country: "China",
            countryCode: "CN",
            address: "bj01.example.com",
            port: 51820,
            publicKey: "YOUR_BJ_PUBLIC_KEY",
            allowedIPs: "0.0.0.0/0",
            serverType: .inbound,
            isSelected: false,
            latency: nil
        ),
        ServerNode(
            id: "sh-001",
            name: "上海 A",
            country: "China",
            countryCode: "CN",
            address: "sh01.example.com",
            port: 51820,
            publicKey: "YOUR_SH_PUBLIC_KEY",
            allowedIPs: "0.0.0.0/0",
            serverType: .inbound,
            isSelected: false,
            latency: nil
        ),
    ]
}
