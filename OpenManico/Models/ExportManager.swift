import Foundation

/**
 * 导出数据管理器
 */
struct ExportData: Codable {
    var websites: [Website]
    var groups: [WebsiteGroup]
    var timestamp: Date
    var version: String
    
    init(websites: [Website], groups: [WebsiteGroup]) {
        self.websites = websites
        self.groups = groups
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
        let exportData = ExportData(
            websites: websiteManager.getWebsites(mode: .all),
            groups: websiteManager.groups
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
            
            // 先清除现有数据
            websiteManager.groups = []
            websiteManager.websites = []
            
            // 先导入分组
            websiteManager.groups = importedData.groups
            
            // 再导入网站，确保每个网站都被添加到正确的分组中
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