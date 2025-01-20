import Foundation
import SwiftUI

/**
 * 网站分组管理器
 */
class WebsiteGroupManager: ObservableObject {
    static let shared = WebsiteGroupManager()
    
    @Published var groups: [WebsiteGroup] = []
    
    private init() {
        loadGroups()
    }
    
    /**
     * 添加网站到分组
     */
    func addWebsite(_ websiteId: UUID, to groupId: UUID) {
        // 先从所有分组中移除该网站
        for index in groups.indices {
            groups[index].websiteIds.removeAll { $0 == websiteId }
        }
        // 然后添加到指定分组
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].websiteIds.append(websiteId)
            saveGroups()
        }
    }
    
    /**
     * 从分组中移除网站
     */
    func removeWebsite(_ websiteId: UUID, from groupId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].websiteIds.removeAll { $0 == websiteId }
            saveGroups()
        }
    }
    
    /**
     * 添加新分组
     */
    func addGroup(name: String) {
        print("[WebsiteGroupManager] 添加分组: \(name)")
        let group = WebsiteGroup(name: name)
        groups.append(group)
        print("[WebsiteGroupManager] - 分组ID: \(group.id)")
        print("[WebsiteGroupManager] - 当前分组数量: \(groups.count)")
        saveGroups()
    }
    
    /**
     * 更新分组
     */
    func updateGroup(_ group: WebsiteGroup) {
        print("[WebsiteGroupManager] 更新分组: \(group.name)")
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            print("[WebsiteGroupManager] - 更新成功")
            saveGroups()
        } else {
            print("[WebsiteGroupManager] ❌ 未找到要更新的分组")
        }
    }
    
    /**
     * 删除分组
     */
    func deleteGroup(_ group: WebsiteGroup) {
        print("[WebsiteGroupManager] 删除分组: \(group.name)")
        groups.removeAll { $0.id == group.id }
        print("[WebsiteGroupManager] - 当前分组数量: \(groups.count)")
        saveGroups()
    }
    
    /**
     * 获取网站所在的分组
     */
    func getGroups(for websiteId: UUID) -> [WebsiteGroup] {
        let result = groups.filter { $0.websiteIds.contains(websiteId) }
        print("[WebsiteGroupManager] 获取网站(\(websiteId))的分组:")
        for group in result {
            print("- \(group.name)")
        }
        return result
    }
    
    /**
     * 更新分组列表
     */
    func updateGroups(_ newGroups: [WebsiteGroup]) {
        // 确保"常用"分组始终在第一位
        var updatedGroups = newGroups
        if let defaultGroupIndex = updatedGroups.firstIndex(where: { $0.name == "常用" }),
           defaultGroupIndex != 0 {
            let defaultGroup = updatedGroups.remove(at: defaultGroupIndex)
            updatedGroups.insert(defaultGroup, at: 0)
        }
        groups = updatedGroups
        saveGroups()
    }
    
    /**
     * 保存分组数据
     */
    private func saveGroups() {
        print("[WebsiteGroupManager] 保存分组数据")
        if let data = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(data, forKey: "groups")
            print("[WebsiteGroupManager] ✅ 保存成功")
            print("[WebsiteGroupManager] 当前分组状态:")
            for group in groups {
                print("- \(group.name):")
                print("  - ID: \(group.id)")
                print("  - 网站数量: \(group.websiteIds.count)")
                print("  - 网站IDs: \(group.websiteIds)")
            }
        } else {
            print("[WebsiteGroupManager] ❌ 保存失败")
        }
    }
    
    /**
     * 加载分组数据
     */
    private func loadGroups() {
        print("[WebsiteGroupManager] 加载分组数据")
        if let data = UserDefaults.standard.data(forKey: "groups"),
           let loadedGroups = try? JSONDecoder().decode([WebsiteGroup].self, from: data) {
            groups = loadedGroups
            print("[WebsiteGroupManager] ✅ 加载成功")
            print("[WebsiteGroupManager] 加载的分组:")
            for group in groups {
                print("- \(group.name):")
                print("  - ID: \(group.id)")
                print("  - 网站数量: \(group.websiteIds.count)")
                print("  - 网站IDs: \(group.websiteIds)")
            }
        } else {
            print("[WebsiteGroupManager] ⚠️ 没有找到保存的分组数据")
        }
    }
} 