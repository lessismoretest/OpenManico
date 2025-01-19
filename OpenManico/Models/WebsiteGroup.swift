import Foundation

/**
 * 网站分组模型
 */
struct WebsiteGroup: Identifiable, Codable, Hashable {
    /// 唯一标识符
    let id: UUID
    /// 分组名称
    var name: String
    /// 分组中的网站ID列表
    private var _websiteIds: Set<UUID>
    
    var websiteIds: [UUID] {
        Array(_websiteIds)
    }
    
    /// 获取分组中的网站数量
    var count: Int {
        _websiteIds.count
    }
    
    /// 添加网站ID
    mutating func addWebsite(_ websiteId: UUID) {
        print("[WebsiteGroup] 添加网站ID: \(websiteId)")
        print("[WebsiteGroup] - 当前网站IDs: \(websiteIds)")
        _websiteIds.insert(websiteId)
        print("[WebsiteGroup] - 添加后网站IDs: \(websiteIds)")
    }
    
    /// 移除网站ID
    mutating func removeWebsite(_ websiteId: UUID) {
        print("[WebsiteGroup] 移除网站ID: \(websiteId)")
        _websiteIds.remove(websiteId)
    }
    
    /// 更新网站ID列表
    mutating func updateWebsiteIds(_ ids: [UUID]) {
        print("[WebsiteGroup] 更新网站IDs")
        print("[WebsiteGroup] - 当前网站IDs: \(websiteIds)")
        print("[WebsiteGroup] - 新的网站IDs: \(ids)")
        _websiteIds = Set(ids)
    }
    
    /// 验证网站ID是否有效
    func validateWebsiteIds() -> [UUID] {
        let validIds = WebsiteManager.shared.websites.map { $0.id }
        return websiteIds.filter { validIds.contains($0) }
    }
    
    init(name: String, websiteIds: [UUID] = []) {
        self.id = UUID()
        self.name = name
        self._websiteIds = Set(websiteIds)
        print("[WebsiteGroup] 创建新分组: \(name)")
        print("[WebsiteGroup] - ID: \(id)")
        print("[WebsiteGroup] - 网站IDs: \(websiteIds)")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, _websiteIds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        _websiteIds = try container.decode(Set<UUID>.self, forKey: ._websiteIds)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(_websiteIds, forKey: ._websiteIds)
    }
}

/**
 * 网站分组管理器
 */
class WebsiteGroupManager: ObservableObject {
    /// 单例
    static let shared = WebsiteGroupManager()
    
    /// 分组列表
    @Published private(set) var groups: [WebsiteGroup] = [] {
        didSet {
            saveGroups()
        }
    }
    
    private let groupsKey = "WebsiteGroups"
    
    private init() {
        print("[WebsiteGroupManager] 初始化")
        loadGroups()
    }
    
    /// 加载保存的分组
    private func loadGroups() {
        print("[WebsiteGroupManager] 开始加载分组")
        guard let data = UserDefaults.standard.data(forKey: groupsKey) else {
            print("[WebsiteGroupManager] 没有已保存的分组数据")
            return
        }
        
        do {
            let loadedGroups = try JSONDecoder().decode([WebsiteGroup].self, from: data)
            print("[WebsiteGroupManager] 成功加载 \(loadedGroups.count) 个分组")
            groups = loadedGroups
            cleanInvalidWebsiteIds()
        } catch {
            print("[WebsiteGroupManager] ❌ 加载分组失败: \(error)")
        }
    }
    
    /// 清理无效的网站ID
    private func cleanInvalidWebsiteIds() {
        let validIds = Set(WebsiteManager.shared.websites.map { $0.id })
        var updatedGroups = groups
        var hasChanges = false
        
        for i in 0..<updatedGroups.count {
            let originalIds = Set(updatedGroups[i].websiteIds)
            let validGroupIds = originalIds.intersection(validIds)
            
            if validGroupIds.count != originalIds.count {
                print("[WebsiteGroupManager] 清理分组 '\(updatedGroups[i].name)' 的无效ID")
                print("[WebsiteGroupManager] - 原有: \(originalIds.count) 个")
                print("[WebsiteGroupManager] - 有效: \(validGroupIds.count) 个")
                var group = updatedGroups[i]
                group.updateWebsiteIds(Array(validGroupIds))
                updatedGroups[i] = group
                hasChanges = true
            }
        }
        
        if hasChanges {
            groups = updatedGroups
        }
    }
    
    /// 保存分组
    private func saveGroups() {
        do {
            let data = try JSONEncoder().encode(groups)
            UserDefaults.standard.set(data, forKey: groupsKey)
            print("[WebsiteGroupManager] ✅ 保存 \(groups.count) 个分组")
        } catch {
            print("[WebsiteGroupManager] ❌ 保存分组失败: \(error)")
        }
    }
    
    /// 添加新分组
    func addGroup(name: String) {
        print("[WebsiteGroupManager] 添加分组: \(name)")
        let group = WebsiteGroup(name: name)
        groups.append(group)
    }
    
    /// 更新分组
    func updateGroup(_ group: WebsiteGroup) {
        print("[WebsiteGroupManager] 更新分组: \(group.name), ID: \(group.id)")
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            saveGroups()
        } else {
            print("[WebsiteGroupManager] ❌ 未找到要更新的分组")
        }
    }
    
    /// 删除分组
    func deleteGroup(_ group: WebsiteGroup) {
        print("[WebsiteGroupManager] 删除分组: \(group.name)")
        groups.removeAll { $0.id == group.id }
    }
    
    /// 添加网站到分组
    func addWebsite(_ websiteId: UUID, to groupId: UUID) {
        guard WebsiteManager.shared.websites.contains(where: { $0.id == websiteId }) else {
            print("[WebsiteGroupManager] ❌ 无效的网站ID: \(websiteId)")
            return
        }
        
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else {
            print("[WebsiteGroupManager] ❌ 未找到分组")
            return
        }
        
        var updatedGroups = groups
        var group = updatedGroups[index]
        group.addWebsite(websiteId)
        updatedGroups[index] = group
        groups = updatedGroups
        
        print("[WebsiteGroupManager] ✅ 已添加网站到分组 '\(group.name)'")
    }
    
    /// 从分组中移除网站
    func removeWebsite(_ websiteId: UUID, from groupId: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else {
            return
        }
        
        var updatedGroups = groups
        var group = updatedGroups[index]
        group.removeWebsite(websiteId)
        updatedGroups[index] = group
        groups = updatedGroups
    }
    
    /// 获取网站所属的分组
    func getGroups(for websiteId: UUID) -> [WebsiteGroup] {
        return groups.filter { $0.websiteIds.contains(websiteId) }
    }
} 