import Foundation

enum ServerNodeQRParseError: LocalizedError {
    case empty
    case invalidJSON
    case missingRequiredFields

    var errorDescription: String? {
        switch self {
        case .empty: return "二维码内容为空"
        case .invalidJSON: return "无法识别的节点二维码"
        case .missingRequiredFields: return "节点信息不完整（需要 address）"
        }
    }
}

enum ServerNodeQRParser {

    /// 解析扫码得到的字符串为节点列表。
    /// 支持单节点 JSON 对象，或节点数组 JSON。
    static func parse(_ raw: String) throws -> [ServerNode] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ServerNodeQRParseError.empty }

        guard let data = trimmed.data(using: .utf8) else {
            throw ServerNodeQRParseError.invalidJSON
        }

        let decoder = JSONDecoder()

        if let nodes = try? decoder.decode([QRNodePayload].self, from: data) {
            let mapped = nodes.compactMap { $0.toServerNode() }
            guard !mapped.isEmpty else { throw ServerNodeQRParseError.missingRequiredFields }
            return mapped
        }

        if let payload = try? decoder.decode(QRNodePayload.self, from: data),
           let node = payload.toServerNode() {
            return [node]
        }

        throw ServerNodeQRParseError.invalidJSON
    }
}

/// 扫码 JSON 字段；除 address 外均可选，缺省会填合理默认值。
private struct QRNodePayload: Decodable {
    let id: String?
    let name: String?
    let country: String?
    let countryCode: String?
    let address: String?
    let port: Int?
    let publicKey: String?
    let allowedIPs: String?
    let serverType: String?

    func toServerNode() -> ServerNode? {
        guard let address = address?.trimmingCharacters(in: .whitespacesAndNewlines),
              !address.isEmpty else {
            return nil
        }

        let type: ServerType
        switch serverType?.lowercased() {
        case "inbound": type = .inbound
        default: type = .outbound
        }

        let resolvedId = id?.isEmpty == false ? id! : "scanned-\(UUID().uuidString.prefix(8))"
        let resolvedName = (name?.isEmpty == false) ? name! : address
        let code = (countryCode?.isEmpty == false) ? countryCode!.uppercased() : "UN"
        let resolvedCountry = (country?.isEmpty == false) ? country! : code

        return ServerNode(
            id: resolvedId,
            name: resolvedName,
            country: resolvedCountry,
            countryCode: code,
            address: address,
            port: port ?? 51820,
            publicKey: publicKey ?? "",
            allowedIPs: allowedIPs ?? "0.0.0.0/0",
            serverType: type,
            isSelected: false,
            latency: nil
        )
    }
}
