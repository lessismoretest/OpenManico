import Foundation
import AppKit

/**
 * 网站快捷键配置模型
 */
struct WebShortcut: Identifiable, Codable {
    /// 唯一标识符
    var id = UUID()
    /// 快捷键绑定的按键
    var key: String
    /// 目标网站URL
    var url: String
    /// 网站名称
    var name: String
    /// 是否启用
    var isEnabled: Bool = true
    
    /// 获取网站图标
    func fetchIcon(completion: @escaping (NSImage?) -> Void) {
        guard let url = URL(string: self.url),
              let host = url.host else {
            completion(nil)
            return
        }
        
        // 构建安全的 favicon URL
        let faviconURL = "\(url.scheme ?? "https")://\(host)/favicon.ico"
        guard let faviconRequestURL = URL(string: faviconURL) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: faviconRequestURL) { data, response, error in
            if let data = data, let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                // 如果直接获取favicon失败，尝试从Google获取
                let googleFaviconURL = "https://www.google.com/s2/favicons?domain=\(host)&sz=64"
                guard let googleURL = URL(string: googleFaviconURL) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                URLSession.shared.dataTask(with: googleURL) { data, response, error in
                    if let data = data, let image = NSImage(data: data) {
                        DispatchQueue.main.async {
                            completion(image)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }.resume()
            }
        }.resume()
    }
}

/**
 * 网站快捷键管理器
 */
class WebShortcutManager: ObservableObject {
    /// 已配置的网站快捷键列表
    @Published var shortcuts: [WebShortcut] = []
    
    /// UserDefaults存储键
    private let shortcutsKey = "webShortcuts"
    
    init() {
        loadShortcuts()
    }
    
    /// 加载保存的快捷键配置
    private func loadShortcuts() {
        if let data = UserDefaults.standard.data(forKey: shortcutsKey),
           let shortcuts = try? JSONDecoder().decode([WebShortcut].self, from: data) {
            self.shortcuts = shortcuts
        }
    }
    
    /// 保存快捷键配置
    func saveShortcuts() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: shortcutsKey)
        }
    }
    
    /// 添加新的网站快捷键
    func addShortcut(_ shortcut: WebShortcut) {
        shortcuts.append(shortcut)
        saveShortcuts()
    }
    
    /// 更新现有的网站快捷键
    func updateShortcut(_ shortcut: WebShortcut) {
        if let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            shortcuts[index] = shortcut
            saveShortcuts()
        }
    }
    
    /// 删除网站快捷键
    func deleteShortcut(_ shortcut: WebShortcut) {
        shortcuts.removeAll { $0.id == shortcut.id }
        saveShortcuts()
    }
} 