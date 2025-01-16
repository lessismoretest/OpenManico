import Foundation
import AppKit

/**
 * 网站快捷键配置模型
 */
struct WebShortcut: Identifiable, Codable, Hashable {
    /// 唯一标识符
    let id = UUID()
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

/// 网站快捷键场景模型
struct WebScene: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var shortcuts: [WebShortcut]
    
    static func == (lhs: WebScene, rhs: WebScene) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/**
 * 网站快捷键管理器
 */
class WebShortcutManager: ObservableObject {
    /// 已配置的网站快捷键列表
    @Published var shortcuts: [WebShortcut] = [] {
        didSet {
            // 当快捷键列表发生变化时，自动更新当前场景
            if !isInitializing && !isUpdatingScene {
                updateCurrentSceneShortcuts()
            }
        }
    }
    @Published var scenes: [WebScene] = []
    @Published var currentScene: WebScene?
    
    private var isInitializing = true
    private var isUpdatingScene = false
    
    init() {
        isInitializing = true
        loadShortcuts()
        
        // 初始化场景
        if scenes.isEmpty {
            // 创建默认场景
            let defaultScene = WebScene(name: "默认场景", shortcuts: shortcuts)
            scenes = [defaultScene]
            currentScene = defaultScene
        }
        isInitializing = false
    }
    
    /// 加载保存的快捷键配置
    func loadShortcuts() {
        // 加载场景数据
        if let data = UserDefaults.standard.data(forKey: "webScenes"),
           let loadedScenes = try? JSONDecoder().decode([WebScene].self, from: data) {
            self.scenes = loadedScenes
            
            // 加载当前场景
            if let currentSceneIdString = UserDefaults.standard.string(forKey: "currentWebSceneId"),
               let currentSceneId = UUID(uuidString: currentSceneIdString) {
                self.currentScene = scenes.first { $0.id == currentSceneId }
            } else {
                self.currentScene = scenes.first
            }
            
            // 更新当前快捷键
            if let currentScene = currentScene {
                self.shortcuts = currentScene.shortcuts
            }
        } else {
            // 加载旧版本的快捷键数据
            if let data = UserDefaults.standard.data(forKey: "WebShortcuts"),
               let shortcuts = try? JSONDecoder().decode([WebShortcut].self, from: data) {
                self.shortcuts = shortcuts
            }
        }
    }
    
    /// 保存快捷键配置
    func saveShortcuts() {
        // 保存场景数据
        if let data = try? JSONEncoder().encode(scenes) {
            UserDefaults.standard.set(data, forKey: "webScenes")
        }
        if let currentSceneId = currentScene?.id {
            UserDefaults.standard.set(currentSceneId.uuidString, forKey: "currentWebSceneId")
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
    
    func addScene(name: String) {
        let newScene = WebScene(name: name, shortcuts: [])
        scenes.append(newScene)
        saveShortcuts()
    }
    
    func removeScene(_ scene: WebScene) {
        scenes.removeAll { $0.id == scene.id }
        if currentScene?.id == scene.id {
            currentScene = scenes.first
            shortcuts = currentScene?.shortcuts ?? []
        }
        saveShortcuts()
    }
    
    func switchScene(to scene: WebScene) {
        isUpdatingScene = true
        defer { isUpdatingScene = false }
        
        // 深拷贝场景的快捷键
        if let data = try? JSONEncoder().encode(scene.shortcuts),
           let copiedShortcuts = try? JSONDecoder().decode([WebShortcut].self, from: data) {
            
            // 创建新的场景对象
            let newScene = WebScene(id: scene.id, name: scene.name, shortcuts: copiedShortcuts)
            
            // 更新当前场景引用
            currentScene = newScene
            
            // 更新快捷键列表
            shortcuts = copiedShortcuts
            
            print("Switched to web scene: \(scene.name) with \(copiedShortcuts.count) shortcuts")
        }
    }
    
    func updateCurrentSceneShortcuts() {
        guard !isUpdatingScene, let currentScene = currentScene else { return }
        
        // 深拷贝当前快捷键列表
        if let data = try? JSONEncoder().encode(shortcuts),
           let copiedShortcuts = try? JSONDecoder().decode([WebShortcut].self, from: data) {
            
            // 创建新的场景对象
            let updatedScene = WebScene(id: currentScene.id, name: currentScene.name, shortcuts: copiedShortcuts)
            
            // 更新scenes数组中的场景
            if let index = scenes.firstIndex(where: { $0.id == currentScene.id }) {
                scenes[index] = updatedScene
                self.currentScene = updatedScene
                saveShortcuts()
                print("Web scene shortcuts updated and saved: \(copiedShortcuts.count) shortcuts")
            }
        }
    }
} 