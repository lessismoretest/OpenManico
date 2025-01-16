import Foundation

/**
 * 导出数据模型
 */
struct ExportData: Codable {
    var appScenes: [Scene]?
    var webScenes: [WebScene]?
    var timestamp: Date
    var version: String
    
    init(appScenes: [Scene]? = nil, webScenes: [WebScene]? = nil) {
        self.appScenes = appScenes
        self.webScenes = webScenes
        self.timestamp = Date()
        self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

/**
 * 导出管理器
 */
class ExportManager {
    static let shared = ExportManager()
    
    private init() {}
    
    /// 导出选中的场景
    func exportScenes(appScenes: [Scene]?, webScenes: [WebScene]?) -> Data? {
        let exportData = ExportData(appScenes: appScenes, webScenes: webScenes)
        return try? JSONEncoder().encode(exportData)
    }
    
    /// 导入场景数据
    func importScenes(from data: Data) -> ExportData? {
        return try? JSONDecoder().decode(ExportData.self, from: data)
    }
} 