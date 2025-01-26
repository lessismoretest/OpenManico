import Foundation

/**
 * 导出数据管理器
 */
struct ExportData: Codable {
    var websites: [Website]
    var websiteGroups: [WebsiteGroup]
    var appGroups: [AppGroup]
    var appShortcuts: [AppShortcut]
    var timestamp: Date
    var version: String
    
    init(websites: [Website], websiteGroups: [WebsiteGroup], appGroups: [AppGroup], appShortcuts: [AppShortcut]) {
        self.websites = websites
        self.websiteGroups = websiteGroups
        self.appGroups = appGroups
        self.appShortcuts = appShortcuts
        self.timestamp = Date()
        self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

/**
 * 导出管理器
 */
class ExportManager {
    static let shared = ExportManager()
    
    private init() {}
    
    /// 导出数据
    func exportData() -> Data? {
        let websiteManager = WebsiteManager.shared
        let appGroupManager = AppGroupManager.shared
        let settings = AppSettings.shared
        
        let exportData = ExportData(
            websites: websiteManager.getWebsites(mode: .all),
            websiteGroups: websiteManager.groups,
            appGroups: appGroupManager.groups,
            appShortcuts: settings.shortcuts
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(exportData)
        } catch {
            print("[ExportManager] ❌ 导出数据失败: \(error)")
            return nil
        }
    }
    
    /// 导入数据
    func importData(_ data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedData = try decoder.decode(ExportData.self, from: data)
            
            let websiteManager = WebsiteManager.shared
            let appGroupManager = AppGroupManager.shared
            let settings = AppSettings.shared
            
            // 先清除现有数据
            websiteManager.groups = []
            websiteManager.websites = []
            appGroupManager.groups = []
            settings.shortcuts = []
            
            // 导入网站分组
            websiteManager.groups = importedData.websiteGroups
            
            // 导入应用分组
            appGroupManager.groups = importedData.appGroups
            
            // 导入应用快捷键
            settings.shortcuts = importedData.appShortcuts
            
            // 导入网站
            for website in importedData.websites {
                // 如果网站没有分组，将其添加到默认分组中
                if website.groupIds.isEmpty {
                    if let defaultGroup = websiteManager.groups.first {
                        var updatedWebsite = website
                        updatedWebsite.groupIds = [defaultGroup.id]
                        websiteManager.addWebsite(updatedWebsite)
                    }
                } else {
                    // 确保网站的分组存在
                    var updatedWebsite = website
                    updatedWebsite.groupIds = website.groupIds.filter { groupId in
                        websiteManager.groups.contains { $0.id == groupId }
                    }
                    
                    // 如果过滤后没有有效的分组，添加到默认分组
                    if updatedWebsite.groupIds.isEmpty, let defaultGroup = websiteManager.groups.first {
                        updatedWebsite.groupIds = [defaultGroup.id]
                    }
                    
                    websiteManager.addWebsite(updatedWebsite)
                }
            }
            
            print("[ExportManager] ✅ 导入数据成功")
            return true
        } catch {
            print("[ExportManager] ❌ 导入数据失败: \(error)")
            return false
        }
    }
} 