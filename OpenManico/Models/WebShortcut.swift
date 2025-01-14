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
        guard let url = URL(string: self.url) else {
            completion(nil)
            return
        }
        
        // 尝试获取网站的favicon
        let faviconURL = url.scheme! + "://" + url.host! + "/favicon.ico"
        
        URLSession.shared.dataTask(with: URL(string: faviconURL)!) { data, response, error in
            if let data = data, let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                // 如果直接获取favicon失败，尝试从Google获取
                let googleFaviconURL = "https://www.google.com/s2/favicons?domain=" + url.host! + "&sz=64"
                URLSession.shared.dataTask(with: URL(string: googleFaviconURL)!) { data, response, error in
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
    private func saveShortcuts() {
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