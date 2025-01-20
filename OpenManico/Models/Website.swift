import Foundation
import AppKit

/**
 * 网站模型
 */
struct Website: Identifiable, Codable {
    let id: UUID
    var url: String
    var name: String
    var shortcutKey: String?  // 快捷键，可选
    var groupIds: [UUID] = [] // 所属分组ID列表
    var isEnabled: Bool = true // 是否启用
    
    // 并发控制
    private static let semaphore = DispatchSemaphore(value: 3) // 最多同时加载3个图标
    private static var loadingQueue = Set<String>() // 正在加载的URL集合
    private static let queueLock = NSLock() // 用于保护loadingQueue的锁
    
    init(id: UUID = UUID(), url: String, name: String, shortcutKey: String? = nil, groupIds: [UUID] = [], isEnabled: Bool = true) {
        self.id = id
        self.url = url
        self.name = name
        self.shortcutKey = shortcutKey
        self.groupIds = groupIds
        self.isEnabled = isEnabled
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
            saveWebsites()
        }
    }
    
    /// 分组列表
    @Published var groups: [WebsiteGroup] = [] {
        didSet {
            print("[WebsiteManager] 分组列表已更新，当前有 \(groups.count) 个分组")
            saveGroups()
        }
    }
    
    private let websitesKey = "Websites"
    private let groupsKey = "WebsiteGroups"
    
    private init() {
        print("[WebsiteManager] 初始化")
        loadWebsites()
        loadGroups()
    }
    
    // MARK: - 网站管理方法
    
    /// 根据显示模式和分组获取网站列表
    func getWebsites(mode: WebsiteDisplayMode, groupId: UUID? = nil) -> [Website] {
        var filtered = websites
        
        // 按分组筛选
        if let groupId = groupId {
            filtered = filtered.filter { $0.groupIds.contains(groupId) }
        }
        
        // 按显示模式筛选
        switch mode {
        case .shortcutOnly:
            filtered = filtered.filter { $0.shortcutKey != nil }
        case .all:
            break // 显示所有
        }
        
        return filtered.sorted(by: { $0.name < $1.name })
    }
    
    /// 添加新网站
    func addWebsite(_ website: Website) {
        print("[WebsiteManager] 添加新网站: \(website.name)")
        websites.append(website)
    }
    
    /// 更新网站
    func updateWebsite(_ website: Website) {
        print("[WebsiteManager] 更新网站: \(website.name)")
        if let index = websites.firstIndex(where: { $0.id == website.id }) {
            websites[index] = website
        }
    }
    
    /// 删除网站
    func deleteWebsite(_ website: Website) {
        print("[WebsiteManager] 删除网站: \(website.name)")
        websites.removeAll { $0.id == website.id }
    }
    
    /// 设置网站快捷键
    func setShortcut(_ key: String?, for websiteId: UUID) {
        print("[WebsiteManager] 设置网站快捷键: \(key ?? "nil")")
        if let index = websites.firstIndex(where: { $0.id == websiteId }) {
            var website = websites[index]
            website.shortcutKey = key
            websites[index] = website
        }
    }
    
    // MARK: - 分组管理方法
    
    /// 添加新分组
    func addGroup(name: String) {
        print("[WebsiteManager] 添加分组: \(name)")
        let group = WebsiteGroup(name: name, websiteIds: [])
        groups.append(group)
    }
    
    /// 更新分组
    func updateGroup(_ group: WebsiteGroup) {
        print("[WebsiteManager] 更新分组: \(group.name)")
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        }
    }
    
    /// 删除分组
    func deleteGroup(_ group: WebsiteGroup) {
        print("[WebsiteManager] 删除分组: \(group.name)")
        // 从所有网站中移除该分组ID
        for index in websites.indices {
            websites[index].groupIds.removeAll { $0 == group.id }
        }
        groups.removeAll { $0.id == group.id }
    }
    
    /// 添加网站到分组
    func addWebsiteToGroup(_ websiteId: UUID, groupId: UUID) {
        print("[WebsiteManager] 添加网站到分组")
        if let index = websites.firstIndex(where: { $0.id == websiteId }) {
            var website = websites[index]
            if !website.groupIds.contains(groupId) {
                website.groupIds.append(groupId)
                websites[index] = website
            }
        }
    }
    
    /// 从分组中移除网站
    func removeWebsiteFromGroup(_ websiteId: UUID, groupId: UUID) {
        print("[WebsiteManager] 从分组中移除网站")
        if let index = websites.firstIndex(where: { $0.id == websiteId }) {
            var website = websites[index]
            website.groupIds.removeAll { $0 == groupId }
            websites[index] = website
        }
    }
    
    // MARK: - 数据持久化
    
    private func loadWebsites() {
        print("[WebsiteManager] 加载网站数据")
        if let data = UserDefaults.standard.data(forKey: websitesKey) {
            do {
                websites = try JSONDecoder().decode([Website].self, from: data)
                print("[WebsiteManager] 成功加载 \(websites.count) 个网站")
            } catch {
                print("[WebsiteManager] ❌ 加载网站数据失败: \(error)")
            }
        }
    }
    
    private func saveWebsites() {
        print("[WebsiteManager] 保存网站数据")
        do {
            let data = try JSONEncoder().encode(websites)
            UserDefaults.standard.set(data, forKey: websitesKey)
            print("[WebsiteManager] ✅ 网站数据保存成功")
        } catch {
            print("[WebsiteManager] ❌ 保存网站数据失败: \(error)")
        }
    }
    
    private func loadGroups() {
        print("[WebsiteManager] 加载分组数据")
        if let data = UserDefaults.standard.data(forKey: groupsKey) {
            do {
                groups = try JSONDecoder().decode([WebsiteGroup].self, from: data)
                print("[WebsiteManager] 成功加载 \(groups.count) 个分组")
            } catch {
                print("[WebsiteManager] ❌ 加载分组数据失败: \(error)")
            }
        }
        
        // 如果没有分组，创建默认分组
        if groups.isEmpty {
            print("[WebsiteManager] 创建默认分组")
            addGroup(name: "常用")
        }
    }
    
    private func saveGroups() {
        print("[WebsiteManager] 保存分组数据")
        do {
            let data = try JSONEncoder().encode(groups)
            UserDefaults.standard.set(data, forKey: groupsKey)
            print("[WebsiteManager] ✅ 分组数据保存成功")
        } catch {
            print("[WebsiteManager] ❌ 保存分组数据失败: \(error)")
        }
    }
} 