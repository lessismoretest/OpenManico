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
    /// 关联的网站ID
    var websiteId: UUID
    /// 是否启用
    var isEnabled: Bool = true
    
    /// 获取网站图标
    func fetchIcon(completion: @escaping (NSImage?) -> Void) {
        Task {
            if let website = WebsiteManager.shared.findWebsite(id: websiteId) {
                await website.fetchIcon(completion: completion)
            } else {
                completion(nil)
            }
        }
    }
    
    /// 获取网站名称
    var name: String {
        WebsiteManager.shared.findWebsite(id: websiteId)?.name ?? ""
    }
    
    /// 获取网站URL
    var url: String {
        print("[WebShortcut] 正在获取网站 URL，websiteId: \(websiteId)")
        if let website = WebsiteManager.shared.findWebsite(id: websiteId) {
            print("[WebShortcut] 找到网站: \(website.name), URL: \(website.url)")
            return website.url
        } else {
            print("[WebShortcut] ❌ 未找到对应的网站")
            return ""
        }
    }
}

/// 网站快捷键场景模型
struct WebScene: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var shortcuts: [WebShortcut]
    
    static func == (lhs: WebScene, rhs: WebScene) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.shortcuts == rhs.shortcuts
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(shortcuts)
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
        print("[WebShortcutManager] 开始加载快捷键...")
        // 加载场景数据
        if let data = UserDefaults.standard.data(forKey: "webScenes"),
           let loadedScenes = try? JSONDecoder().decode([WebScene].self, from: data) {
            self.scenes = loadedScenes
            print("[WebShortcutManager] 成功加载 \(loadedScenes.count) 个场景")
            
            // 加载当前场景
            if let currentSceneIdString = UserDefaults.standard.string(forKey: "currentWebSceneId"),
               let currentSceneId = UUID(uuidString: currentSceneIdString),
               let currentScene = loadedScenes.first(where: { $0.id == currentSceneId }) {
                print("[WebShortcutManager] 已恢复当前场景: \(currentScene.name)")
                self.currentScene = currentScene
                self.shortcuts = currentScene.shortcuts
                print("[WebShortcutManager] 已加载当前场景的 \(currentScene.shortcuts.count) 个快捷键:")
                for shortcut in currentScene.shortcuts {
                    print("- 键: \(shortcut.key), 网站ID: \(shortcut.websiteId), 启用: \(shortcut.isEnabled)")
                }
            } else {
                print("[WebShortcutManager] ⚠️ 未找到当前场景，使用第一个场景")
                if let firstScene = loadedScenes.first {
                    self.currentScene = firstScene
                    self.shortcuts = firstScene.shortcuts
                    print("[WebShortcutManager] 使用场景: \(firstScene.name)")
                    print("[WebShortcutManager] 加载了 \(firstScene.shortcuts.count) 个快捷键")
                }
            }
        } else {
            print("[WebShortcutManager] ⚠️ 未找到场景数据，创建默认场景")
            let defaultScene = WebScene(name: "默认场景", shortcuts: [])
            self.scenes = [defaultScene]
            self.currentScene = defaultScene
            self.shortcuts = []
        }
    }
    
    /// 保存快捷键配置
    func saveShortcuts() {
        // 保存场景数据
        if let data = try? JSONEncoder().encode(scenes) {
            UserDefaults.standard.set(data, forKey: "webScenes")
            print("[WebShortcutManager] 已保存 \(scenes.count) 个场景")
        }
        
        // 同时保存当前快捷键列表（兼容旧版本）
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: "WebShortcuts")
            print("[WebShortcutManager] 已保存 \(shortcuts.count) 个快捷键")
        }
        
        if let currentSceneId = currentScene?.id {
            UserDefaults.standard.set(currentSceneId.uuidString, forKey: "currentWebSceneId")
            print("[WebShortcutManager] 已保存当前场景ID: \(currentSceneId)")
        }
        
        // 立即同步
        UserDefaults.standard.synchronize()
    }
    
    /// 添加新的网站快捷键
    func addShortcut(key: String, website: Website) {
        let shortcut = WebShortcut(key: key, websiteId: website.id)
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
        if scenes.isEmpty {
            // 如果删除了所有场景，创建一个默认场景
            addScene(name: "默认")
        }
        // 切换到第一个场景
        if let firstScene = scenes.first {
            switchScene(to: firstScene)
        }
        saveShortcuts()
    }
    
    func renameScene(_ scene: WebScene, to newName: String) {
        if let index = scenes.firstIndex(where: { $0.id == scene.id }) {
            var updatedScene = scene
            updatedScene.name = newName
            scenes[index] = updatedScene
            
            // 如果重命名的是当前场景，更新当前场景
            if currentScene?.id == scene.id {
                currentScene = updatedScene
            }
            
            saveShortcuts()
        }
    }
    
    func duplicateScene(_ scene: WebScene) {
        // 深拷贝场景的快捷键
        if let data = try? JSONEncoder().encode(scene.shortcuts),
           let copiedShortcuts = try? JSONDecoder().decode([WebShortcut].self, from: data) {
            
            // 创建新的场景对象，使用原场景名称加上"副本"
            let newScene = WebScene(name: scene.name + " 副本", shortcuts: copiedShortcuts)
            scenes.append(newScene)
            
            // 切换到新场景
            switchScene(to: newScene)
            saveShortcuts()
        }
    }
    
    func switchScene(to scene: WebScene) {
        isUpdatingScene = true
        
        // 深拷贝场景的快捷键
        if let data = try? JSONEncoder().encode(scene.shortcuts),
           let copiedShortcuts = try? JSONDecoder().decode([WebShortcut].self, from: data) {
            
            DispatchQueue.main.async {
                // 创建新的场景对象
                let newScene = WebScene(id: scene.id, name: scene.name, shortcuts: copiedShortcuts)
                
                // 更新当前场景引用
                self.currentScene = newScene
                
                // 更新scenes数组中的对应场景
                if let index = self.scenes.firstIndex(where: { $0.id == scene.id }) {
                    self.scenes[index] = newScene
                }
                
                // 更新快捷键列表
                self.shortcuts = copiedShortcuts
                
                // 保存设置
                self.saveShortcuts()
                
                print("Switched to web scene: \(scene.name) with \(copiedShortcuts.count) shortcuts")
                
                self.isUpdatingScene = false
            }
        } else {
            isUpdatingScene = false
        }
    }
    
    /// 更新当前场景的快捷键
    private func updateCurrentSceneShortcuts() {
        print("[WebShortcutManager] 更新当前场景的快捷键...")
        if var updatedScene = currentScene {
            updatedScene.shortcuts = shortcuts
            if let index = scenes.firstIndex(where: { $0.id == updatedScene.id }) {
                scenes[index] = updatedScene
                currentScene = updatedScene
                
                // 保存场景数据
                if let data = try? JSONEncoder().encode(scenes) {
                    UserDefaults.standard.set(data, forKey: "webScenes")
                    UserDefaults.standard.set(updatedScene.id.uuidString, forKey: "currentWebSceneId")
                    print("[WebShortcutManager] ✅ 成功保存场景数据")
                    print("[WebShortcutManager] - 当前场景: \(updatedScene.name)")
                    print("[WebShortcutManager] - 快捷键数量: \(updatedScene.shortcuts.count)")
                }
            }
        } else {
            print("[WebShortcutManager] ⚠️ 没有当前场景，无法更新")
        }
    }
} 