import Foundation
import SwiftUI
import AppKit

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
        
        // 无论是否有分组，都创建系统应用分组
        createSystemAppsGroup()
    }
    
    /**
     * 创建系统应用分组
     */
    private func createSystemAppsGroup() {
        // 检查是否已存在名为"苹果标志"的分组
        let appleSymbol = "\u{F8FF}" // 苹果标志 Unicode
        let systemGroupExists = groups.contains { $0.name == appleSymbol }
        if systemGroupExists {
            return // 已存在则不重复创建
        }
        
        // 扫描所有应用并筛选系统应用
        let systemApps = scanAllSystemApps()
        
        // 创建分组
        createGroup(name: appleSymbol, apps: systemApps)
    }
    
    /**
     * 扫描所有系统应用
     */
    private func scanAllSystemApps() -> [AppInfo] {
        // 扫描所有可能包含系统应用的目录
        let systemPaths = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            "/Library/PreferencePanes"
        ]
        
        var allApps: [AppInfo] = []
        
        // 1. 扫描系统目录中的应用
        for path in systemPaths {
            let url = URL(fileURLWithPath: path)
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }
            
            for appURL in contents {
                if appURL.pathExtension == "app" || appURL.pathExtension == "prefPane" {
                    guard let isApp = try? appURL.resourceValues(forKeys: [.isApplicationKey]).isApplication, 
                          isApp || appURL.pathExtension == "prefPane" else {
                        continue
                    }
                    
                    if let bundle = Bundle(url: appURL),
                       let bundleId = bundle.bundleIdentifier,
                       !bundleId.isEmpty {
                        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                        let name = getLocalizedAppName(for: bundleId, url: appURL)
                        allApps.append(AppInfo(bundleId: bundleId, name: name, icon: icon, url: appURL))
                    }
                }
            }
        }
        
        // 2. 使用Workspace API查找可能漏掉的系统应用
        if #available(macOS 12.0, *) {
            let workspace = NSWorkspace.shared
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            if let appURLs = workspace.urlsForApplications(toOpen: fileURL) as? [URL] {
                for appURL in appURLs {
                    if let bundle = Bundle(url: appURL),
                       let bundleId = bundle.bundleIdentifier,
                       !bundleId.isEmpty,
                       !allApps.contains(where: { $0.bundleId == bundleId }) {
                        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                        let name = getLocalizedAppName(for: bundleId, url: appURL)
                        allApps.append(AppInfo(bundleId: bundleId, name: name, icon: icon, url: appURL))
                    }
                }
            }
        }
        
        // 3. 检查特殊系统应用，确保不会漏掉重要应用
        let specialSystemApps = [
            "com.apple.finder",
            "com.apple.systempreferences",
            "com.apple.Safari"
        ]
        
        for bundleId in specialSystemApps {
            if !allApps.contains(where: { $0.bundleId == bundleId }),
               let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                let name = getLocalizedAppName(for: bundleId, url: url)
                allApps.append(AppInfo(bundleId: bundleId, name: name, icon: icon, url: url))
            }
        }
        
        // 4. 过滤出系统应用（以com.apple.开头）
        let systemApps = allApps.filter { $0.bundleId.hasPrefix("com.apple.") }
        
        // 按名称排序
        return systemApps.sorted { $0.name < $1.name }
    }
    
    /**
     * 获取应用的本地化名称
     */
    private func getLocalizedAppName(for bundleId: String, url: URL) -> String {
        let localizedNames: [String: String] = [
            "com.apple.finder": "访达",
            "com.apple.systempreferences": "系统设置",
            "com.apple.Safari": "Safari",
            "com.apple.mail": "邮件",
            "com.apple.iCal": "日历",
            "com.apple.Photos": "照片",
            "com.apple.iWork.Pages": "Pages",
            "com.apple.iWork.Numbers": "Numbers",
            "com.apple.iWork.Keynote": "Keynote",
            "com.apple.Notes": "备忘录",
            "com.apple.iMovie": "iMovie",
            "com.apple.Music": "音乐",
            "com.apple.Maps": "地图",
            "com.apple.AppStore": "App Store",
            "com.apple.TextEdit": "文本编辑",
            "com.apple.Terminal": "终端"
        ]
        
        // 首先尝试从字典获取本地化名称
        if let name = localizedNames[bundleId] {
            return name
        }
        
        // 尝试从Bundle获取名称
        if let bundle = Bundle(url: url) {
            if let name = bundle.infoDictionary?["CFBundleName"] as? String {
                return name
            }
            if let name = bundle.infoDictionary?["CFBundleDisplayName"] as? String {
                return name
            }
        }
        
        // 回退到URL中的名称
        return url.deletingPathExtension().lastPathComponent
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