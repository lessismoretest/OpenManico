import Foundation
import SwiftUI

/**
 * 应用分组管理器
 */
class AppGroupManager: ObservableObject {
    static let shared = AppGroupManager()
    
    @Published var groups: [AppGroup] = [] {
        didSet {
            saveGroups()
        }
    }
    
    private let groupsKey = "AppGroups"
    
    private init() {
        loadGroups()
        
        // 如果没有分组，创建默认分组
        if groups.isEmpty {
            createGroup(name: "默认", apps: [])
        }
    }
    
    /**
     * 创建新分组
     */
    func createGroup(name: String, apps: [AppInfo]) {
        let group = AppGroup(name: name, apps: apps.map { AppGroupItem(bundleId: $0.bundleId, name: $0.name) })
        groups.append(group)
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
     * 更新分组
     */
    func updateGroup(_ group: AppGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            saveGroups()
        }
    }
    
    /**
     * 获取分组应用
     */
    func getApps(groupId: UUID) -> [AppGroupItem] {
        if let group = groups.first(where: { $0.id == groupId }) {
            return group.apps
        }
        return []
    }
    
    /**
     * 加载分组
     */
    private func loadGroups() {
        if let data = UserDefaults.standard.data(forKey: groupsKey) {
            do {
                groups = try JSONDecoder().decode([AppGroup].self, from: data)
            } catch {
                print("Failed to load groups: \(error)")
            }
        }
    }
    
    /**
     * 保存分组
     */
    private func saveGroups() {
        do {
            let data = try JSONEncoder().encode(groups)
            UserDefaults.standard.set(data, forKey: groupsKey)
        } catch {
            print("Failed to save groups: \(error)")
        }
    }
} 