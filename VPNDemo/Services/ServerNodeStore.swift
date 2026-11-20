import Foundation

enum ServerNodeStore {

    private static let customNodesKey = AppConstants.UserDefaultsKeys.customServerNodes

    static func loadAll() -> [ServerNode] {
        let custom = loadCustom()
        var merged = ServerNode.defaultNodes
        for node in custom where !merged.contains(where: { $0.id == node.id }) {
            merged.append(node)
        }

        if let selectedId = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.selectedServerId) {
            for i in merged.indices {
                merged[i].isSelected = merged[i].id == selectedId
            }
            if !merged.contains(where: { $0.isSelected }), !merged.isEmpty {
                merged[0].isSelected = true
            }
        }
        return merged
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
