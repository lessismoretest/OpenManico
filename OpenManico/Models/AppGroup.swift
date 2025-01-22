import Foundation

/**
 * 应用分组模型
 */
struct AppGroup: Codable, Identifiable {
    let id: UUID
    var name: String
    var apps: [AppGroupItem]
    
    init(id: UUID = UUID(), name: String, apps: [AppGroupItem]) {
        self.id = id
        self.name = name
        self.apps = apps
    }
}

/**
 * 分组中的应用项
 */
struct AppGroupItem: Codable {
    let bundleId: String
    let name: String
} 