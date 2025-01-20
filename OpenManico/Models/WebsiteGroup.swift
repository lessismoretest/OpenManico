import Foundation

/**
 * 网站分组模型
 */
struct WebsiteGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var websiteIds: [UUID]
    
    init(id: UUID = UUID(), name: String, websiteIds: [UUID] = []) {
        self.id = id
        self.name = name
        self.websiteIds = websiteIds
    }
} 