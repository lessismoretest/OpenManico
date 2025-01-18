import Foundation
import ServiceManagement

struct AppShortcut: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    var key: String
    var bundleIdentifier: String
    var appName: String
    
    var displayKey: String {
        "Option + \(key)"
    }
    
    static func == (lhs: AppShortcut, rhs: AppShortcut) -> Bool {
        lhs.id == rhs.id &&
        lhs.key == rhs.key &&
        lhs.bundleIdentifier == rhs.bundleIdentifier &&
        lhs.appName == rhs.appName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(key)
        hasher.combine(bundleIdentifier)
        hasher.combine(appName)
    }
}

enum Theme: String, Codable {
    case light
    case dark
    case system
}

/// 场景模型
struct Scene: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var shortcuts: [AppShortcut]
    
    static func == (lhs: Scene, rhs: Scene) -> Bool {
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

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private var isInitializing = true
    private var isUpdatingScene = false
    
    @Published var shortcuts: [AppShortcut] = [] {
        didSet {
            // 避免初始化时的循环调用
            guard !isInitializing else { return }
            
            // 更新热键绑定
            HotKeyManager.shared.updateShortcuts(shortcuts)
            
            // 如果不是在切换场景过程中，则更新当前场景
            if !isUpdatingScene {
                updateCurrentSceneShortcuts()
            }
        }
    }
    @Published var theme: Theme = .system
    @Published var launchAtLogin: Bool = false
    @Published var totalUsageCount: Int = 0
    @Published var showFloatingWindow: Bool = true
    @Published var showWebShortcutsInFloatingWindow: Bool = false
    @Published var openOnMouseHover: Bool = false
    @Published var selectedShortcutIndex: Int = -1
    @Published var selectedWebShortcutIndex: Int = -1
    @Published var showWindowOnHover: Bool = false
    @Published var scenes: [Scene] = []
    @Published var currentScene: Scene?
    
    private let shortcutsKey = "AppShortcuts"
    private let themeKey = "AppTheme"
    private let launchAtLoginKey = "LaunchAtLogin"
    private let usageCountKey = "UsageCount"
    private let showFloatingWindowKey = "ShowFloatingWindow"
    private let showWebShortcutsInFloatingWindowKey = "ShowWebShortcutsInFloatingWindow"
    private let openOnMouseHoverKey = "OpenOnMouseHover"
    private let showWindowOnHoverKey = "ShowWindowOnHover"
    
    private init() {
        isInitializing = true
        loadSettings()
        launchAtLogin = SMAppService.mainApp.status == .enabled
        
        // 初始化场景
        if scenes.isEmpty {
            // 创建默认场景
            let defaultScene = Scene(name: "默认场景", shortcuts: shortcuts)
            scenes = [defaultScene]
            currentScene = defaultScene
        }
        isInitializing = false
    }
    
    func loadSettings() {
        // 加载场景数据
        if let data = UserDefaults.standard.data(forKey: "scenes"),
           let loadedScenes = try? JSONDecoder().decode([Scene].self, from: data) {
            self.scenes = loadedScenes
            
            // 加载当前场景
            if let currentSceneIdString = UserDefaults.standard.string(forKey: "currentSceneId"),
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
            if let data = UserDefaults.standard.data(forKey: shortcutsKey),
               let shortcuts = try? JSONDecoder().decode([AppShortcut].self, from: data) {
                self.shortcuts = shortcuts
            }
        }
        
        if let themeString = UserDefaults.standard.string(forKey: themeKey),
           let theme = Theme(rawValue: themeString) {
            self.theme = theme
        }
        
        totalUsageCount = UserDefaults.standard.integer(forKey: usageCountKey)
        showFloatingWindow = UserDefaults.standard.bool(forKey: showFloatingWindowKey)
        showWebShortcutsInFloatingWindow = UserDefaults.standard.bool(forKey: showWebShortcutsInFloatingWindowKey)
        openOnMouseHover = UserDefaults.standard.bool(forKey: openOnMouseHoverKey)
        showWindowOnHover = UserDefaults.standard.bool(forKey: showWindowOnHoverKey)
    }
    
    func saveSettings() {
        // 保存场景数据
        if let data = try? JSONEncoder().encode(scenes) {
            UserDefaults.standard.set(data, forKey: "scenes")
        }
        if let currentSceneId = currentScene?.id {
            UserDefaults.standard.set(currentSceneId.uuidString, forKey: "currentSceneId")
        }
        
        // 保存其他设置
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        UserDefaults.standard.set(totalUsageCount, forKey: usageCountKey)
        UserDefaults.standard.set(showFloatingWindow, forKey: showFloatingWindowKey)
        UserDefaults.standard.set(showWebShortcutsInFloatingWindow, forKey: showWebShortcutsInFloatingWindowKey)
        UserDefaults.standard.set(openOnMouseHover, forKey: openOnMouseHoverKey)
        UserDefaults.standard.set(showWindowOnHover, forKey: showWindowOnHoverKey)
    }
    
    func incrementUsageCount() {
        totalUsageCount += 1
        UserDefaults.standard.set(totalUsageCount, forKey: usageCountKey)
    }
    
    func toggleLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
            // 恢复状态
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    
    func exportSettings() -> URL? {
        // 导出应用快捷键
        let appShortcuts = self.shortcuts.map { shortcut -> [String: String] in
            return [
                "key": shortcut.key,
                "bundleIdentifier": shortcut.bundleIdentifier,
                "appName": shortcut.appName
            ]
        }
        
        // 导出网站快捷键
        let webShortcuts = HotKeyManager.shared.webShortcutManager.shortcuts.map { shortcut -> [String: String] in
            return [
                "key": shortcut.key,
                "url": shortcut.url,
                "name": shortcut.name
            ]
        }
        
        // 只导出快捷键配置
        let exportData: [String: Any] = [
            "appShortcuts": appShortcuts,
            "webShortcuts": webShortcuts
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) else {
            return nil
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let exportURL = tempDir.appendingPathComponent("OpenManico_Shortcuts.json")
        
        try? jsonData.write(to: exportURL)
        return exportURL
    }
    
    func resetSelection() {
        selectedShortcutIndex = -1
        selectedWebShortcutIndex = -1
    }
    
    func selectNextShortcut() {
        let sortedShortcuts = shortcuts.sorted(by: { $0.key < $1.key })
        if sortedShortcuts.isEmpty { return }
        
        if selectedShortcutIndex == -1 {
            selectedShortcutIndex = 0
        } else {
            selectedShortcutIndex = (selectedShortcutIndex + 1) % sortedShortcuts.count
        }
    }
    
    func selectNextWebShortcut() {
        let sortedWebShortcuts = HotKeyManager.shared.webShortcutManager.shortcuts.sorted(by: { $0.key < $1.key })
        if sortedWebShortcuts.isEmpty { return }
        
        if selectedWebShortcutIndex == -1 {
            selectedWebShortcutIndex = 0
        } else {
            selectedWebShortcutIndex = (selectedWebShortcutIndex + 1) % sortedWebShortcuts.count
        }
    }
    
    var selectedShortcut: AppShortcut? {
        let sortedShortcuts = shortcuts.sorted(by: { $0.key < $1.key })
        guard selectedShortcutIndex >= 0 && selectedShortcutIndex < sortedShortcuts.count else {
            return nil
        }
        return sortedShortcuts[selectedShortcutIndex]
    }
    
    var selectedWebShortcut: WebShortcut? {
        let sortedWebShortcuts = HotKeyManager.shared.webShortcutManager.shortcuts.sorted(by: { $0.key < $1.key })
        guard selectedWebShortcutIndex >= 0 && selectedWebShortcutIndex < sortedWebShortcuts.count else {
            return nil
        }
        return sortedWebShortcuts[selectedWebShortcutIndex]
    }
    
    // 场景管理相关方法
    func addScene(name: String) {
        let newScene = Scene(name: name, shortcuts: [])
        scenes.append(newScene)
        saveSettings()
    }
    
    func removeScene(_ scene: Scene) {
        scenes.removeAll { $0.id == scene.id }
        if scenes.isEmpty {
            // 如果删除了所有场景，创建一个默认场景
            addScene(name: "默认")
        }
        // 切换到第一个场景
        if let firstScene = scenes.first {
            switchScene(to: firstScene)
        }
        saveSettings()
    }
    
    func renameScene(_ scene: Scene, to newName: String) {
        if let index = scenes.firstIndex(where: { $0.id == scene.id }) {
            var updatedScene = scene
            updatedScene.name = newName
            scenes[index] = updatedScene
            
            // 如果重命名的是当前场景，更新当前场景
            if currentScene?.id == scene.id {
                currentScene = updatedScene
            }
            
            saveSettings()
        }
    }
    
    func duplicateScene(_ scene: Scene) {
        // 深拷贝场景的快捷键
        if let data = try? JSONEncoder().encode(scene.shortcuts),
           let copiedShortcuts = try? JSONDecoder().decode([AppShortcut].self, from: data) {
            
            // 创建新的场景对象，使用原场景名称加上"副本"
            let newScene = Scene(name: scene.name + " 副本", shortcuts: copiedShortcuts)
            scenes.append(newScene)
            
            // 切换到新场景
            switchScene(to: newScene)
            saveSettings()
        }
    }
    
    func switchScene(to scene: Scene) {
        isUpdatingScene = true
        
        // 深拷贝场景的快捷键
        if let data = try? JSONEncoder().encode(scene.shortcuts),
           let copiedShortcuts = try? JSONDecoder().decode([AppShortcut].self, from: data) {
            
            // 创建新的场景对象
            let newScene = Scene(id: scene.id, name: scene.name, shortcuts: copiedShortcuts)
            
            // 更新当前场景引用
            currentScene = newScene
            
            // 更新scenes数组中的对应场景
            if let index = scenes.firstIndex(where: { $0.id == scene.id }) {
                scenes[index] = newScene
            }
            
            // 更新快捷键列表
            shortcuts = copiedShortcuts
            
            // 保存设置
            saveSettings()
            print("Switched to scene: \(scene.name) with \(copiedShortcuts.count) shortcuts")
        }
        
        isUpdatingScene = false
    }
    
    func updateShortcuts(_ newShortcuts: [AppShortcut], updateScene: Bool = true) {
        isUpdatingScene = !updateScene
        shortcuts = newShortcuts
        if updateScene {
            // 强制更新当前场景，不受 didSet 观察器的 isUpdatingScene 检查影响
            updateCurrentSceneShortcuts()
        }
        isUpdatingScene = false
    }
    
    func updateCurrentSceneShortcuts() {
        guard let currentScene = currentScene else { return }
        
        // 深拷贝当前快捷键列表
        if let data = try? JSONEncoder().encode(shortcuts),
           let copiedShortcuts = try? JSONDecoder().decode([AppShortcut].self, from: data) {
            
            // 创建新的场景对象
            let updatedScene = Scene(id: currentScene.id, name: currentScene.name, shortcuts: copiedShortcuts)
            
            // 更新scenes数组中的场景
            if let index = scenes.firstIndex(where: { $0.id == currentScene.id }) {
                scenes[index] = updatedScene
                self.currentScene = updatedScene
                
                // 保存设置
                saveSettings()
                print("Scene shortcuts updated and saved: \(copiedShortcuts.count) shortcuts")
            }
        }
    }
} 
