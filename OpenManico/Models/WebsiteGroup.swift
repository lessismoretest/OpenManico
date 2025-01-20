import Foundation

/**
 * 网站分组模型
 */
struct WebsiteGroup: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var websiteIds: [UUID]
    
    init(id: UUID = UUID(), name: String, websiteIds: [UUID] = []) {
        self.id = id
        self.name = name
        self.websiteIds = websiteIds
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: WebsiteGroup, rhs: WebsiteGroup) -> Bool {
        lhs.id == rhs.id
    }
} 