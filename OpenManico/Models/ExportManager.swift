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
            websites: websiteManager.websites,
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
            websiteManager.websites = importedData.websites
            websiteManager.groups = importedData.groups
            
            print("[ExportManager] ✅ 导入数据成功")
            return true
        } catch {
            print("[ExportManager] ❌ 导入数据失败: \(error)")
            return false
        }
    }
} 