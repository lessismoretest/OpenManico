import Foundation

/**
 * 应用分组管理器
 */
class AppGroupManager: ObservableObject {
    static let shared = AppGroupManager()
    
    @Published private(set) var groups: [AppGroup] = []
    private let groupsKey = "AppGroups"
    
    private init() {
        loadGroups()
    }
    
    /**
     * 创建新分组
     */
    func createGroup(name: String, apps: [AppInfo]) {
        let groupItems = apps.map { AppGroupItem(bundleId: $0.bundleId, name: $0.name) }
        let newGroup = AppGroup(name: name, apps: groupItems)
        groups.append(newGroup)
        saveGroups()
    }
    
    /**
     * 创建包含单个应用的分组
     */
    func createGroupWithApp(name: String, app: AppInfo) {
        let newGroup = AppGroup(name: name, apps: [AppGroupItem(bundleId: app.bundleId, name: app.name)])
        groups.append(newGroup)
        saveGroups()
    }
    
    /**
     * 删除分组
     */
    func deleteGroup(_ group: AppGroup) {
        groups.removeAll { $0.id == group.id }
        saveGroups()
    }
    
    /**
     * 重命名分组
     */
    func renameGroup(_ group: AppGroup, to newName: String) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            var updatedGroup = group
            updatedGroup.name = newName
            groups[index] = updatedGroup
            saveGroups()
        }
    }
    
    /**
     * 更新分组应用
     */
    func updateGroupApps(_ group: AppGroup, apps: [AppInfo]) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            var updatedGroup = group
            updatedGroup.apps = apps.map { AppGroupItem(bundleId: $0.bundleId, name: $0.name) }
            groups[index] = updatedGroup
            saveGroups()
        }
    }
    
    /**
     * 加载分组
     */
    private func loadGroups() {
        if let data = UserDefaults.standard.data(forKey: groupsKey),
           let decodedGroups = try? JSONDecoder().decode([AppGroup].self, from: data) {
            groups = decodedGroups
        }
    }
    
    /**
     * 保存分组
     */
    private func saveGroups() {
        if let encoded = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(encoded, forKey: groupsKey)
        }
    }
} 