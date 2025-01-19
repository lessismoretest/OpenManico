import Foundation

/**
 * 应用分组模型
 */
struct AppGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var apps: [AppGroupItem]
    var createdAt: Date
    
    init(name: String, apps: [AppGroupItem]) {
        self.id = UUID()
        self.name = name
        self.apps = apps
        self.createdAt = Date()
    }
}

/**
 * 分组中的应用项
 */
struct AppGroupItem: Codable, Identifiable {
    let id: String
    let bundleId: String
    let name: String
    
    init(bundleId: String, name: String) {
        self.id = bundleId
        self.bundleId = bundleId
        self.name = name
    }
} 