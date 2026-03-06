import SwiftUI
import AppKit

/**
 * 网站图标管理器
 * 负责网站图标的加载、缓存和管理
 */
@MainActor
class WebIconManager: ObservableObject {
    /// 单例实例
    static let shared = WebIconManager()
    
    /// 内存中的图标缓存
    @Published private var icons: [UUID: NSImage] = [:]
    
    /// 缓存目录URL
    private let cacheDirectory: URL
    
    /// 正在加载的图标集合
    private var loadingIcons: Set<UUID> = []
    
    /// 加载完成的回调集合
    private var loadCompletionHandlers: [UUID: [(NSImage?) -> Void]] = [:]
    
    /// 预加载队列
    private let preloadQueue = DispatchQueue(label: "com.openmanico.iconpreload", qos: .utility)
    
    /// 私有初始化方法，确保单例模式
    private init() {
        // 获取缓存目录
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheDirectory = cacheDir.appendingPathComponent("website_icons")
        } else {
            // 如果无法获取缓存目录，使用临时目录
            cacheDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("website_icons")
        }
        
        // 创建缓存目录
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // 加载磁盘缓存
        loadCachedIcons()
    }
    
    /**
     * 获取已缓存的图标数量
     */
    func getCachedIconCount() -> Int {
        return icons.count
    }
    
    /**
     * 预加载所有网站图标
     */
    func preloadIcons(for websites: [Website]) {
        let websitesToLoad = websites.filter { website in
            !icons.keys.contains(website.id) && !loadingIcons.contains(website.id)
        }
        
        guard !websitesToLoad.isEmpty else {
            print("[WebIconManager] ✅ 所有图标已缓存，无需预加载")
            return
        }
        
        let startTime = Date()
        print("[WebIconManager] 🔄 开始预加载 \(websitesToLoad.count) 个网站图标")
        print("[WebIconManager] 📊 缓存状态: 内存缓存 \(icons.count) 个，正在加载 \(loadingIcons.count) 个")
        
        var successCount = 0
        var failureCount = 0
        
        for website in websitesToLoad {
            preloadQueue.async {
                Task { @MainActor in
                    await self.loadIcon(for: website) { icon in
                        if icon != nil {
                            successCount += 1
                        } else {
                            failureCount += 1
                        }
                        
                        // 当所有图标都加载完成时，输出统计信息
                        if successCount + failureCount == websitesToLoad.count {
                            let endTime = Date()
                            let totalTime = endTime.timeIntervalSince(startTime)
                            print("[WebIconManager] ✅ 预加载完成 - 成功: \(successCount), 失败: \(failureCount), 总耗时: \(String(format: "%.2f", totalTime))秒")
                        }
                    }
                }
            }
        }
    }
    
    /**
     * 加载磁盘缓存中的图标
     */
    private func loadCachedIcons() {
        guard let enumerator = FileManager.default.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        print("[WebIconManager] 开始加载磁盘缓存的图标")
        var loadedCount = 0
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "png",
                  let websiteId = UUID(uuidString: fileURL.deletingPathExtension().lastPathComponent),
                  let image = NSImage(contentsOf: fileURL) else {
                continue
            }
            icons[websiteId] = image
            loadedCount += 1
        }
        
        print("[WebIconManager] 从磁盘缓存加载了 \(loadedCount) 个图标")
    }
    
    /**
     * 获取指定网站的图标
     * - Parameter websiteId: 网站ID
     * - Returns: 网站图标，如果未加载则返回nil
     */
    func icon(for websiteId: UUID) -> NSImage? {
        if let icon = icons[websiteId] {
            return icon
        }
        
        let iconPath = cacheDirectory.appendingPathComponent("\(websiteId.uuidString).png")
        if let image = NSImage(contentsOf: iconPath) {
            self.icons[websiteId] = image
            return image
        }
        
        return nil
    }
    
    /**
     * 设置网站图标
     * - Parameters:
     *   - icon: 图标图像
     *   - websiteId: 网站ID
     */
    func setIcon(_ icon: NSImage, for websiteId: UUID) {
        // 更新内存缓存
        icons[websiteId] = icon
        
        // 保存到磁盘缓存
        Task.detached {
            let iconPath = self.cacheDirectory.appendingPathComponent("\(websiteId.uuidString).png")
            if let tiffData = icon.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                do {
                    try pngData.write(to: iconPath)
                } catch {
                    print("保存图标失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /**
     * 加载网站图标
     */
    @MainActor
    func loadIcon(for website: Website, completion: ((NSImage?) -> Void)? = nil) {
        // 如果已经有图标，直接回调
        if let icon = icons[website.id] {
            completion?(icon)
            return
        }
        
        let iconPath = cacheDirectory.appendingPathComponent("\(website.id.uuidString).png")
        
        // 尝试从文件缓存加载
        if let image = NSImage(contentsOf: iconPath) {
            self.icons[website.id] = image
            completion?(image)
            return
        }
        
        // 如果已经在加载中，添加到回调列表
        if loadingIcons.contains(website.id) {
            if let completion = completion {
                loadCompletionHandlers[website.id, default: []].append(completion)
            }
            return
        }
        
        // 标记为正在加载
        loadingIcons.insert(website.id)
        if let completion = completion {
            loadCompletionHandlers[website.id, default: []].append(completion)
        }
        
        // 创建后台任务加载图标
        Task {
            defer {
                Task { @MainActor in
                    self.loadingIcons.remove(website.id)
                }
            }
            
            do {
                await website.fetchIcon { [weak self] fetchedIcon in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        if let icon = fetchedIcon {
                            // 更新内存缓存
                            self.icons[website.id] = icon
                            
                            // 调用所有等待的回调
                            self.loadCompletionHandlers[website.id]?.forEach { $0(icon) }
                            self.loadCompletionHandlers[website.id] = nil
                        } else {
                            // 如果加载失败，调用回调并传入 nil
                            self.loadCompletionHandlers[website.id]?.forEach { $0(nil) }
                            self.loadCompletionHandlers[website.id] = nil
                        }
                    }
                }
            } catch {
                // 发生错误时，调用回调并传入 nil
                Task { @MainActor in
                    self.loadCompletionHandlers[website.id]?.forEach { $0(nil) }
                    self.loadCompletionHandlers[website.id] = nil
                }
            }
        }
    }
    
    /**
     * 取消指定网站的图标加载
     * - Parameter websiteId: 要取消加载的网站ID
     */
    func cancelLoading(for websiteId: UUID) {
        loadingIcons.remove(websiteId)
        loadCompletionHandlers[websiteId] = nil
    }
    
    /**
     * 清除所有缓存的图标
     */
    func clearCache() {
        // 清除内存缓存
        icons.removeAll()
        loadingIcons.removeAll()
        loadCompletionHandlers.removeAll()
        
        // 在后台清除文件缓存
        Task.detached {
            try? FileManager.default.removeItem(at: self.cacheDirectory)
            try? FileManager.default.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    /**
     * 获取缓存大小（字节）
     */
    func getCacheSize() async -> Int64 {
        await Task.detached {
            guard let enumerator = FileManager.default.enumerator(at: self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
                return 0
            }
            
            var size: Int64 = 0
            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                      let fileSize = resourceValues.fileSize else {
                    continue
                }
                size += Int64(fileSize)
            }
            return size
        }.value
    }
} 