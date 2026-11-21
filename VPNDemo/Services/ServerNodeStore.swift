import Foundation

enum ServerNodeStore {

    private static let customNodesKey = AppConstants.UserDefaultsKeys.customServerNodes
    private static let subscriptionURLKey = AppConstants.UserDefaultsKeys.subscriptionURL
    private static let configNameKey = AppConstants.UserDefaultsKeys.subscriptionConfigName

    static var configName: String {
        get {
            let name = UserDefaults.standard.string(forKey: configNameKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let name, !name.isEmpty { return name }
            return "默认配置"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: configNameKey)
        }
    }

    static var subscriptionURL: String? {
        get { UserDefaults.standard.string(forKey: subscriptionURLKey) }
        set { UserDefaults.standard.set(newValue, forKey: subscriptionURLKey) }
    }

    static func rememberSubscription(urlString: String) {
        subscriptionURL = urlString
        if let url = URL(string: urlString), let host = url.host, !host.isEmpty {
            configName = host
        } else {
            configName = "订阅配置"
        }
    }

    static func loadAll() -> [ServerNode] {
        let custom = loadCustom()
        var merged = ServerNode.defaultNodes
        for node in custom where !merged.contains(where: { $0.id == node.id }) {
            merged.append(node)
        }

        let selectedId = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.selectedServerId)
        if let selectedId {
            for i in merged.indices {
                merged[i].isSelected = merged[i].id == selectedId
            }
        }
        if !merged.contains(where: { $0.isSelected }), let first = merged.first {
            for i in merged.indices {
                merged[i].isSelected = merged[i].id == first.id
            }
        }
        return merged
    }

    static func setSelectedServerId(_ id: String) {
        UserDefaults.standard.set(id, forKey: AppConstants.UserDefaultsKeys.selectedServerId)
    }

    static func loadCustom() -> [ServerNode] {
        guard let data = UserDefaults.standard.data(forKey: customNodesKey),
              let nodes = try? JSONDecoder().decode([ServerNode].self, from: data) else {
            return []
        }
        return nodes
    }

    @discardableResult
    static func addCustom(_ node: ServerNode) -> [ServerNode] {
        var custom = loadCustom()
        if let index = custom.firstIndex(where: { $0.id == node.id }) {
            custom[index] = node
        } else {
            custom.append(node)
        }
        saveCustom(custom)
        return loadAll()
    }

    @discardableResult
    static func removeCustom(id: String) -> [ServerNode] {
        var custom = loadCustom()
        custom.removeAll { $0.id == id }
        saveCustom(custom)
        return loadAll()
    }

    static func isCustom(id: String) -> Bool {
        loadCustom().contains { $0.id == id }
    }

    private static func saveCustom(_ nodes: [ServerNode]) {
        guard let data = try? JSONEncoder().encode(nodes) else { return }
        UserDefaults.standard.set(data, forKey: customNodesKey)
    }
}
