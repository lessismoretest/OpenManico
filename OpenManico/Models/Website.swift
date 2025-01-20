import Foundation
import AppKit

/**
 * 网站模型
 */
struct Website: Identifiable, Codable {
    let id: UUID
    var url: String
    var name: String
    
    // 并发控制
    private static let semaphore = DispatchSemaphore(value: 3) // 最多同时加载3个图标
    private static var loadingQueue = Set<String>() // 正在加载的URL集合
    private static let queueLock = NSLock() // 用于保护loadingQueue的锁
    
    init(id: UUID = UUID(), url: String, name: String) {
        self.id = id
        self.url = url
        self.name = name
    }
    
    func fetchIcon(completion: @escaping (NSImage?) -> Void) async {
        // 检查是否正在加载
        Website.queueLock.lock()
        if Website.loadingQueue.contains(url) {
            Website.queueLock.unlock()
            return
        }
        Website.loadingQueue.insert(url)
        Website.queueLock.unlock()
        
        defer {
            Website.queueLock.lock()
            Website.loadingQueue.remove(url)
            Website.queueLock.unlock()
        }
        
        // 使用信号量限制并发
        Website.semaphore.wait()
        defer { Website.semaphore.signal() }
        
        guard let url = URL(string: self.url) else {
            completion(nil)
            return
        }
        
        let startTime = Date()
        
        // 创建带超时的 URLSession 配置
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5 // 5秒超时
        let session = URLSession(configuration: config)
        
        // 尝试从网站根目录获取 favicon.ico
        if let faviconURL = URL(string: "\(url.scheme ?? "https")://\(url.host ?? "")/favicon.ico") {
            do {
                let (data, _) = try await session.data(from: faviconURL)
                if let image = NSImage(data: data) {
                    await WebIconManager.shared.setIcon(image, for: self.id)
                    completion(image)
                    return
                }
            } catch {
                // 错误处理，但不打印日志
            }
        }
        
        // 如果从根目录获取失败，尝试从 Google 获取图标
        if let host = url.host,
           let googleFaviconURL = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64") {
            do {
                let (data, _) = try await session.data(from: googleFaviconURL)
                if let image = NSImage(data: data) {
                    await WebIconManager.shared.setIcon(image, for: self.id)
                    completion(image)
                    return
                }
            } catch {
                // 错误处理，但不打印日志
            }
        }
        
        completion(nil)
    }
}

// NSImage 扩展，添加 PNG 数据转换功能
extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
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