import Foundation
import AppKit

/**
 * 网站模型
 */
struct Website: Identifiable, Codable, Hashable {
    /// 唯一标识符
    let id: UUID
    /// 网站URL
    var url: String {
        didSet {
            print("[Website] URL 已更新: \(url)")
        }
    }
    /// 网站名称
    var name: String {
        didSet {
            print("[Website] 名称已更新: \(name)")
        }
    }
    
    init(url: String, name: String) {
        self.url = url
        self.name = name
        // 使用 URL 生成固定的 UUID
        let urlData = url.data(using: .utf8) ?? Data()
        let hash = urlData.map { String(format: "%02x", $0) }.joined()
        let uuidString = hash.prefix(32)
        let index1 = uuidString.index(uuidString.startIndex, offsetBy: 8)
        let index2 = uuidString.index(uuidString.startIndex, offsetBy: 12)
        let index3 = uuidString.index(uuidString.startIndex, offsetBy: 16)
        let index4 = uuidString.index(uuidString.startIndex, offsetBy: 20)
        let index5 = uuidString.index(uuidString.startIndex, offsetBy: 32)
        
        let part1 = uuidString[..<index1]
        let part2 = uuidString[index1..<index2]
        let part3 = uuidString[index2..<index3]
        let part4 = uuidString[index3..<index4]
        let part5 = uuidString[index4..<uuidString.index(uuidString.startIndex, offsetBy: min(32, uuidString.count))]
        
        let formatted = "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
        self.id = UUID(uuidString: formatted) ?? UUID()
        print("[Website] 创建网站: \(name)")
        print("[Website] - URL: \(url)")
        print("[Website] - ID: \(id)")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, url, name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        name = try container.decode(String.self, forKey: .name)
        print("[Website] 从数据解码网站: \(name)")
        print("[Website] - URL: \(url)")
        print("[Website] - ID: \(id)")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(name, forKey: .name)
        print("[Website] 编码网站: \(name)")
        print("[Website] - URL: \(url)")
        print("[Website] - ID: \(id)")
    }
    
    /// 获取网站图标
    func fetchIcon(completion: @escaping (NSImage?) -> Void) {
        guard let url = URL(string: self.url),
              let host = url.host else {
            completion(nil)
            return
        }
        
        // 首先尝试从网站直接获取 favicon
        let faviconURL = "\(url.scheme ?? "https")://\(host)/favicon.ico"
        guard let faviconRequestURL = URL(string: faviconURL) else {
            completion(nil)
            return
        }
        
        // 创建一个高优先级的队列来处理图标获取
        let queue = DispatchQueue(label: "com.openmanico.favicon", qos: .userInitiated)
        
        queue.async {
            let directFaviconTask = URLSession.shared.dataTask(with: faviconRequestURL) { data, response, error in
                if let data = data,
                   let image = NSImage(data: data),
                   image.size.width > 0 { // 验证图片是否有效
                    DispatchQueue.main.async {
                        completion(image)
                    }
                } else {
                    // 如果直接获取失败，尝试从 Google 获取
                    let googleFaviconURL = "https://www.google.com/s2/favicons?domain=\(host)&sz=64"
                    guard let googleURL = URL(string: googleFaviconURL) else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    
                    let googleFaviconTask = URLSession.shared.dataTask(with: googleURL) { data, response, error in
                        if let data = data,
                           let image = NSImage(data: data),
                           image.size.width > 0 {
                            DispatchQueue.main.async {
                                completion(image)
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(nil)
                            }
                        }
                    }
                    googleFaviconTask.resume()
                }
            }
            directFaviconTask.resume()
        }
    }
}

/**
 * 网站管理器
 */
class WebsiteManager: ObservableObject {
    /// 单例
    static let shared = WebsiteManager()
    
    /// 网站列表
    @Published var websites: [Website] = [] {
        didSet {
            print("[WebsiteManager] 网站列表已更新，当前有 \(websites.count) 个网站")
            for website in websites {
                print("[WebsiteManager] - 网站: \(website.name), ID: \(website.id)")
            }
        }
    }
    
    private let websitesKey = "Websites"
    
    private init() {
        print("[WebsiteManager] 初始化")
        loadWebsites()
    }
    
    /// 加载保存的网站列表
    private func loadWebsites() {
        print("[WebsiteManager] 开始加载网站")
        if let data = UserDefaults.standard.data(forKey: websitesKey) {
            print("[WebsiteManager] 从 UserDefaults 读取到数据: \(data.count) 字节")
            do {
                let websites = try JSONDecoder().decode([Website].self, from: data)
                print("[WebsiteManager] 成功解码 \(websites.count) 个网站")
                for website in websites {
                    print("[WebsiteManager] - 加载网站: \(website.name)")
                    print("[WebsiteManager] - URL: \(website.url)")
                    print("[WebsiteManager] - ID: \(website.id)")
                }
                self.websites = websites
            } catch {
                print("[WebsiteManager] ❌ 解码网站数据失败: \(error)")
                print("[WebsiteManager] 错误详情: \(error.localizedDescription)")
            }
        } else {
            print("[WebsiteManager] UserDefaults 中没有找到网站数据")
            print("[WebsiteManager] Key: \(websitesKey)")
        }
    }
    
    /// 保存网站列表
    private func saveWebsites() {
        print("[WebsiteManager] 开始保存网站，共 \(websites.count) 个")
        do {
            let data = try JSONEncoder().encode(websites)
            print("[WebsiteManager] 编码后数据大小: \(data.count) 字节")
            UserDefaults.standard.set(data, forKey: websitesKey)
            UserDefaults.standard.synchronize()
            print("[WebsiteManager] ✅ 网站保存成功")
            
            // 验证保存
            if let savedData = UserDefaults.standard.data(forKey: websitesKey) {
                print("[WebsiteManager] 验证：保存的数据大小 \(savedData.count) 字节")
                if let savedWebsites = try? JSONDecoder().decode([Website].self, from: savedData) {
                    print("[WebsiteManager] 验证：成功读取 \(savedWebsites.count) 个网站")
                    for website in savedWebsites {
                        print("[WebsiteManager] - 网站: \(website.name), URL: \(website.url)")
                    }
                }
            }
        } catch {
            print("[WebsiteManager] ❌ 保存网站失败: \(error)")
        }
    }
    
    /// 添加新网站
    func addWebsite(_ website: Website) {
        print("[WebsiteManager] 添加新网站: \(website.name), ID: \(website.id)")
        websites.append(website)
        saveWebsites()
    }
    
    /// 更新网站
    func updateWebsite(_ website: Website) {
        print("[WebsiteManager] 更新网站: \(website.name), ID: \(website.id)")
        if let index = websites.firstIndex(where: { $0.id == website.id }) {
            websites[index] = website
            saveWebsites()
        } else {
            print("[WebsiteManager] ❌ 未找到要更新的网站")
        }
    }
    
    /// 删除网站
    func deleteWebsite(_ website: Website) {
        print("[WebsiteManager] 删除网站: \(website.name), ID: \(website.id)")
        websites.removeAll { $0.id == website.id }
        saveWebsites()
    }
    
    /// 根据 URL 查找网站
    func findWebsite(url: String) -> Website? {
        let website = websites.first { $0.url == url }
        print("[WebsiteManager] 根据 URL 查找网站: \(url) -> \(website != nil ? "找到" : "未找到")")
        return website
    }
    
    /// 根据 ID 查找网站
    func findWebsite(id: UUID) -> Website? {
        print("[WebsiteManager] 正在查找网站，ID: \(id)")
        print("[WebsiteManager] 当前所有网站:")
        for website in websites {
            print("- ID: \(website.id), 名称: \(website.name), URL: \(website.url)")
        }
        let website = websites.first { $0.id == id }
        if let website = website {
            print("[WebsiteManager] ✅ 找到网站: \(website.name)")
        } else {
            print("[WebsiteManager] ❌ 未找到网站")
        }
        return website
    }
} 