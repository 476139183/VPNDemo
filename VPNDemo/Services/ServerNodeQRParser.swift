import Foundation

enum ServerNodeQRParseError: LocalizedError {
    case empty
    case invalidFormat
    case missingRequiredFields
    case subscriptionEmpty
    case subscriptionFetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .empty: return "二维码内容为空"
        case .invalidFormat:
            return "无法识别该二维码。支持：订阅链接(http/https)、ss/vmess/vless/trojan、或节点 JSON"
        case .missingRequiredFields: return "节点信息不完整（需要服务器地址）"
        case .subscriptionEmpty: return "订阅内容为空或没有可用节点"
        case .subscriptionFetchFailed(let msg): return "拉取订阅失败：\(msg)"
        }
    }
}

enum ServerNodeQRParser {

    /// 同步解析：JSON / 单节点 URI / 多行 URI。订阅 URL 请用 `parseAsync`。
    static func parse(_ raw: String) throws -> [ServerNode] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ServerNodeQRParseError.empty }

        if looksLikeSubscriptionURL(trimmed) {
            throw ServerNodeQRParseError.invalidFormat
        }

        if let nodes = tryParseJSON(trimmed), !nodes.isEmpty {
            return nodes
        }

        if let node = tryParseURI(trimmed) {
            return [node]
        }

        // 多行 URI（base64 解码后常见）
        let lines = trimmed.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        if lines.count > 1 {
            let nodes = lines.compactMap { tryParseURI($0) }
            if !nodes.isEmpty { return nodes }
        }

        if let decoded = decodeBase64Flexible(trimmed), decoded != trimmed {
            return try parse(decoded)
        }

        throw ServerNodeQRParseError.invalidFormat
    }

    /// 异步解析：支持订阅链接拉取。
    static func parseAsync(_ raw: String, completion: @escaping (Result<[ServerNode], Error>) -> Void) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(.failure(ServerNodeQRParseError.empty))
            return
        }

        if looksLikeSubscriptionURL(trimmed) {
            fetchSubscription(trimmed, completion: completion)
            return
        }

        do {
            let nodes = try parse(trimmed)
            completion(.success(nodes))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Subscription

    private static func looksLikeSubscriptionURL(_ text: String) -> Bool {
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return false
        }
        return true
    }

    private static func fetchSubscription(_ urlString: String, completion: @escaping (Result<[ServerNode], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(ServerNodeQRParseError.invalidFormat))
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("ClashMeta/1.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(ServerNodeQRParseError.subscriptionFetchFailed(error.localizedDescription)))
                }
                return
            }
            guard let data, !data.isEmpty else {
                DispatchQueue.main.async {
                    completion(.failure(ServerNodeQRParseError.subscriptionEmpty))
                }
                return
            }

            do {
                let nodes = try parseSubscriptionBody(data)
                DispatchQueue.main.async {
                    if nodes.isEmpty {
                        completion(.failure(ServerNodeQRParseError.subscriptionEmpty))
                    } else {
                        completion(.success(nodes))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    private static func parseSubscriptionBody(_ data: Data) throws -> [ServerNode] {
        let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .ascii)
            ?? ""

        // Clash YAML proxies
        let clashNodes = parseClashProxies(from: text)
        if !clashNodes.isEmpty { return clashNodes }

        // Base64 节点列表
        if let decoded = decodeBase64Flexible(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
            let fromDecoded = parseURIList(decoded)
            if !fromDecoded.isEmpty { return fromDecoded }
            let clashFromDecoded = parseClashProxies(from: decoded)
            if !clashFromDecoded.isEmpty { return clashFromDecoded }
        }

        // 明文 URI 列表
        let fromPlain = parseURIList(text)
        if !fromPlain.isEmpty { return fromPlain }

        throw ServerNodeQRParseError.subscriptionEmpty
    }

    private static func parseURIList(_ text: String) -> [ServerNode] {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap { tryParseURI($0) }
    }

    /// 轻量 Clash proxies 解析（不依赖 YAML 库）
    private static func parseClashProxies(from text: String) -> [ServerNode] {
        guard text.contains("proxies:") || text.contains("- name:") else { return [] }

        var nodes: [ServerNode] = []
        // 简化：逐行扫描 name/server/port
        var currentName: String?
        var currentServer: String?
        var currentPort: Int?
        var currentType: String?

        func flush() {
            guard let server = currentServer, !server.isEmpty else {
                currentName = nil; currentServer = nil; currentPort = nil; currentType = nil
                return
            }
            let name = currentName ?? server
            nodes.append(
                makeNode(
                    name: name,
                    address: server,
                    port: currentPort ?? 443,
                    meta: currentType ?? "clash"
                )
            )
            currentName = nil; currentServer = nil; currentPort = nil; currentType = nil
        }

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("- name:") || (line.hasPrefix("-") && line.contains("name:")) {
                if currentServer != nil { flush() }
            }
            if let v = yamlValue(line, key: "name") { currentName = v }
            if let v = yamlValue(line, key: "server") { currentServer = v }
            if let v = yamlValue(line, key: "port"), let p = Int(v) { currentPort = p }
            if let v = yamlValue(line, key: "type") { currentType = v }
        }
        flush()

        // 行内 JSON-ish: - { name: xx, server: yy, port: zz, type: ss }
        let inline = text
        let regex = try? NSRegularExpression(pattern: #"\{[^{}]*name:\s*([^,}]+)[^{}]*server:\s*([^,}]+)[^{}]*port:\s*(\d+)"#, options: [])
        let ns = inline as NSString
        regex?.enumerateMatches(in: inline, options: [], range: NSRange(location: 0, length: ns.length)) { match, _, _ in
            guard let match, match.numberOfRanges >= 4 else { return }
            let name = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
            let server = ns.substring(with: match.range(at: 2)).trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
            let port = Int(ns.substring(with: match.range(at: 3))) ?? 443
            nodes.append(makeNode(name: name, address: server, port: port, meta: "clash"))
        }

        // 去重
        var seen = Set<String>()
        return nodes.filter { node in
            let key = "\(node.address):\(node.port):\(node.name)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    private static func yamlValue(_ line: String, key: String) -> String? {
        let prefixes = ["\(key):", "- \(key):"]
        for prefix in prefixes {
            if line.hasPrefix(prefix) {
                var v = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                if v.hasPrefix("\"") && v.hasSuffix("\"") { v = String(v.dropFirst().dropLast()) }
                if v.hasPrefix("'") && v.hasSuffix("'") { v = String(v.dropFirst().dropLast()) }
                return v.isEmpty ? nil : v
            }
            // inline "- { name: x"
            if let range = line.range(of: "\(key):") {
                var v = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if let comma = v.firstIndex(of: ",") { v = String(v[..<comma]) }
                if let brace = v.firstIndex(of: "}") { v = String(v[..<brace]) }
                v = v.trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
                return v.isEmpty ? nil : v
            }
        }
        return nil
    }

    // MARK: - JSON

    private static func tryParseJSON(_ trimmed: String) -> [ServerNode]? {
        guard let data = trimmed.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        if let nodes = try? decoder.decode([QRNodePayload].self, from: data) {
            return nodes.compactMap { $0.toServerNode() }
        }
        if let payload = try? decoder.decode(QRNodePayload.self, from: data),
           let node = payload.toServerNode() {
            return [node]
        }
        return nil
    }

    // MARK: - URI schemes

    private static func tryParseURI(_ raw: String) -> ServerNode? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()
        if lower.hasPrefix("ss://") { return parseShadowsocks(text) }
        if lower.hasPrefix("vmess://") { return parseVMess(text) }
        if lower.hasPrefix("vless://") { return parseVLESS(text) }
        if lower.hasPrefix("trojan://") { return parseTrojan(text) }
        if lower.hasPrefix("ssr://") { return parseSSR(text) }
        return nil
    }

    /// ss://method:password@host:port#name 或 ss://base64
    private static func parseShadowsocks(_ text: String) -> ServerNode? {
        let body = String(text.dropFirst("ss://".count))
        let (main, fragment) = splitFragment(body)

        // userinfo@host:port
        if main.contains("@") {
            let parts = main.split(separator: "@", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            var userInfo = parts[0]
            if let decoded = decodeBase64Flexible(userInfo) { userInfo = decoded }
            let hostPort = parts[1].split(separator: "?", maxSplits: 1).first.map(String.init) ?? parts[1]
            guard let (host, port) = splitHostPort(hostPort) else { return nil }
            let name = fragment.flatMap(urlDecode) ?? "SS \(host)"
            return makeNode(name: name, address: host, port: port, meta: "ss:\(userInfo)")
        }

        // legacy base64
        if let decoded = decodeBase64Flexible(main) {
            // method:password@host:port
            if decoded.contains("@") {
                return parseShadowsocks("ss://\(decoded)#\(fragment ?? "")")
            }
        }
        return nil
    }

    private static func parseVMess(_ text: String) -> ServerNode? {
        let body = String(text.dropFirst("vmess://".count))
        guard let decoded = decodeBase64Flexible(body),
              let data = decoded.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let host = (json["add"] as? String) ?? (json["host"] as? String) ?? ""
        guard !host.isEmpty else { return nil }
        let port: Int
        if let p = json["port"] as? Int {
            port = p
        } else if let p = json["port"] as? String, let v = Int(p) {
            port = v
        } else {
            port = 443
        }
        let name = (json["ps"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "VMess \(host)"
        return makeNode(name: name, address: host, port: port, meta: "vmess")
    }

    private static func parseVLESS(_ text: String) -> ServerNode? {
        // vless://uuid@host:port?params#name
        let body = String(text.dropFirst("vless://".count))
        let (main, fragment) = splitFragment(body)
        guard let at = main.firstIndex(of: "@") else { return nil }
        let hostPortQuery = String(main[main.index(after: at)...])
        let hostPort = hostPortQuery.split(separator: "?", maxSplits: 1).first.map(String.init) ?? hostPortQuery
        guard let (host, port) = splitHostPort(hostPort) else { return nil }
        let name = fragment.flatMap(urlDecode) ?? "VLESS \(host)"
        return makeNode(name: name, address: host, port: port, meta: "vless")
    }

    private static func parseTrojan(_ text: String) -> ServerNode? {
        // trojan://password@host:port?params#name
        let body = String(text.dropFirst("trojan://".count))
        let (main, fragment) = splitFragment(body)
        guard let at = main.firstIndex(of: "@") else { return nil }
        let hostPortQuery = String(main[main.index(after: at)...])
        let hostPort = hostPortQuery.split(separator: "?", maxSplits: 1).first.map(String.init) ?? hostPortQuery
        guard let (host, port) = splitHostPort(hostPort) else { return nil }
        let name = fragment.flatMap(urlDecode) ?? "Trojan \(host)"
        return makeNode(name: name, address: host, port: port, meta: "trojan")
    }

    private static func parseSSR(_ text: String) -> ServerNode? {
        let body = String(text.dropFirst("ssr://".count))
        guard let decoded = decodeBase64Flexible(body) else { return nil }
        // host:port:protocol:method:obfs:password_base64/...
        let parts = decoded.split(separator: ":", maxSplits: 5).map(String.init)
        guard parts.count >= 6 else { return nil }
        let host = parts[0]
        let port = Int(parts[1]) ?? 443
        return makeNode(name: "SSR \(host)", address: host, port: port, meta: "ssr")
    }

    // MARK: - Helpers

    private static func makeNode(name: String, address: String, port: Int, meta: String) -> ServerNode {
        let inferredType: ServerType = {
            let n = name.lowercased()
            if n.contains("回国") || n.contains("cn") || n.contains("国内") { return .inbound }
            return .outbound
        }()
        return ServerNode(
            id: "scanned-\(UUID().uuidString.prefix(8))",
            name: name,
            country: inferredType == .inbound ? "China" : "Overseas",
            countryCode: inferredType == .inbound ? "CN" : "UN",
            address: address,
            port: port,
            publicKey: meta,
            allowedIPs: "0.0.0.0/0",
            serverType: inferredType,
            isSelected: false,
            latency: nil
        )
    }

    private static func splitFragment(_ text: String) -> (String, String?) {
        if let idx = text.firstIndex(of: "#") {
            let main = String(text[..<idx])
            let frag = String(text[text.index(after: idx)...])
            return (main, frag)
        }
        return (text, nil)
    }

    private static func splitHostPort(_ text: String) -> (String, Int)? {
        // [ipv6]:port or host:port
        if text.hasPrefix("[") {
            guard let end = text.firstIndex(of: "]") else { return nil }
            let host = String(text[text.index(after: text.startIndex)..<end])
            let rest = String(text[text.index(after: end)...])
            let port = Int(rest.trimmingCharacters(in: CharacterSet(charactersIn: ":"))) ?? 443
            return (host, port)
        }
        guard let idx = text.lastIndex(of: ":") else { return nil }
        let host = String(text[..<idx])
        let port = Int(String(text[text.index(after: idx)...])) ?? 443
        guard !host.isEmpty else { return nil }
        return (host, port)
    }

    private static func urlDecode(_ text: String) -> String {
        text.removingPercentEncoding ?? text
    }

    private static func decodeBase64Flexible(_ text: String) -> String? {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let pad = (4 - s.count % 4) % 4
        if pad > 0 { s += String(repeating: "=", count: pad) }
        guard let data = Data(base64Encoded: s, options: [.ignoreUnknownCharacters]) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

/// 扫码 JSON 字段；除 address 外均可选。
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
