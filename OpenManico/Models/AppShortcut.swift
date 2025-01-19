import Foundation
import ServiceManagement
import SwiftUI

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

enum AppDisplayMode: String, Codable {
    case all = "all"              // 显示所有应用
    case shortcutOnly = "shortcut" // 只显示设置了快捷键的应用
    case runningOnly = "running"   // 只显示正在运行的应用
    
    var description: String {
        switch self {
        case .all:
            return "显示所有应用"
        case .shortcutOnly:
            return "只显示快捷键应用"
        case .runningOnly:
            return "只显示运行中应用"
        }
    }
}

enum WebsiteDisplayMode: String, Codable {
    case shortcutOnly = "shortcutOnly"
    case all = "all"
    
    var description: String {
        switch self {
        case .shortcutOnly:
            return "只显示快捷键网站"
        case .all:
            return "显示所有网站"
        }
    }
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

enum WindowPosition: String, Codable {
    case topLeft = "topLeft"
    case topCenter = "topCenter"
    case topRight = "topRight"
    case centerLeft = "centerLeft"
    case center = "center"
    case centerRight = "centerRight"
    case bottomLeft = "bottomLeft"
    case bottomCenter = "bottomCenter"
    case bottomRight = "bottomRight"
    case custom = "custom"
    
    var description: String {
        switch self {
        case .topLeft: return "左上角"
        case .topCenter: return "顶部居中"
        case .topRight: return "右上角"
        case .centerLeft: return "左侧居中"
        case .center: return "屏幕居中"
        case .centerRight: return "右侧居中"
        case .bottomLeft: return "左下角"
        case .bottomCenter: return "底部居中"
        case .bottomRight: return "右下角"
        case .custom: return "自定义位置"
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private var isInitializing = true
    private var isUpdatingScene = false
    
    @Published var floatingWindowWidth: Double = 600 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var floatingWindowHeight: Double = 400 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var floatingWindowOpacity: Double = 0.8 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var useBlurEffect: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    @Published var blurRadius: Double = 20 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var floatingWindowX: Double = -1 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var floatingWindowY: Double = -1 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var windowPosition: WindowPosition = .center {
        didSet {
            saveSettings()
        }
    }
    
    @Published var iconSize: Double = 48 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var appIconSize: Double = 48 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var webIconSize: Double = 48 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var appIconsPerRow: Double = 5 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var webIconsPerRow: Double = 8 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var shortcuts: [AppShortcut] = [] {
        didSet {
            // 避免初始化时的循环调用
            guard !isInitializing else { return }
            
            // 更新热键绑定
            HotKeyManager.shared.updateShortcuts()
            
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
    @Published var showWebShortcutsInFloatingWindow: Bool = false {
        didSet {
            saveSettings()
        }
    }
    @Published var openOnMouseHover: Bool = false {
        didSet {
            saveSettings()
        }
    }
    @Published var selectedShortcutIndex: Int = -1
    @Published var selectedWebShortcutIndex: Int = -1
    @Published var showWindowOnHover: Bool = false {
        didSet {
            saveSettings()
        }
    }
    @Published var openWebOnHover: Bool = false {
        didSet {
            saveSettings()
        }
    }
    @Published var showAllAppsInFloatingWindow: Bool = true {
        didSet {
            saveSettings()
        }
    }
    @Published var scenes: [Scene] = []
    @Published var currentScene: Scene?
    @Published var appDisplayMode: AppDisplayMode = .all {
        didSet {
            print("应用显示模式改变: \(oldValue) -> \(appDisplayMode)")
            saveSettings()
        }
    }
    @Published var websiteDisplayMode: WebsiteDisplayMode = .shortcutOnly {
        didSet {
            print("网站显示模式改变: \(oldValue) -> \(websiteDisplayMode)")
            saveSettings()
        }
    }
    
    // 图标样式设置
    @Published var iconCornerRadius: Double = 8 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var iconBorderWidth: Double = 2 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var iconBorderColor: Color = .white {
        didSet {
            saveSettings()
        }
    }
    
    @Published var iconSpacing: Double = 4 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var iconShadowRadius: Double = 0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var useIconShadow: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    // 图标悬停动画设置
    @Published var useHoverAnimation: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var hoverScale: Double = 1.1 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var hoverAnimationDuration: Double = 0.2 {
        didSet {
            saveSettings()
        }
    }
    
    // 图标标签设置
    @Published var showAppName: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var showWebsiteName: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var appNameFontSize: Double = 10 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var websiteNameFontSize: Double = 10 {
        didSet {
            saveSettings()
        }
    }
    
    private let shortcutsKey = "AppShortcuts"
    private let themeKey = "AppTheme"
    private let launchAtLoginKey = "LaunchAtLogin"
    private let usageCountKey = "UsageCount"
    private let showFloatingWindowKey = "ShowFloatingWindow"
    private let showWebShortcutsInFloatingWindowKey = "ShowWebShortcutsInFloatingWindow"
    private let openOnMouseHoverKey = "OpenOnMouseHover"
    private let showWindowOnHoverKey = "ShowWindowOnHover"
    private let openWebOnHoverKey = "OpenWebOnHover"
    private let showAllAppsInFloatingWindowKey = "ShowAllAppsInFloatingWindow"
    private let appDisplayModeKey = "AppDisplayMode"
    private let websiteDisplayModeKey = "WebsiteDisplayMode"
    private let iconSizeKey = "IconSize"
    private let appIconSizeKey = "AppIconSize"
    private let webIconSizeKey = "WebIconSize"
    private let appIconsPerRowKey = "AppIconsPerRow"
    private let webIconsPerRowKey = "WebIconsPerRow"
    private let floatingWindowWidthKey = "FloatingWindowWidth"
    private let floatingWindowHeightKey = "FloatingWindowHeight"
    private let floatingWindowOpacityKey = "FloatingWindowOpacity"
    private let useBlurEffectKey = "UseBlurEffect"
    private let blurRadiusKey = "BlurRadius"
    private let floatingWindowXKey = "FloatingWindowX"
    private let floatingWindowYKey = "FloatingWindowY"
    private let windowPositionKey = "WindowPosition"
    private let iconCornerRadiusKey = "IconCornerRadius"
    private let iconBorderWidthKey = "IconBorderWidth"
    private let iconBorderColorKey = "IconBorderColor"
    private let iconSpacingKey = "IconSpacing"
    private let iconShadowRadiusKey = "IconShadowRadius"
    private let useIconShadowKey = "UseIconShadow"
    private let useHoverAnimationKey = "UseHoverAnimation"
    private let hoverScaleKey = "HoverScale"
    private let hoverAnimationDurationKey = "HoverAnimationDuration"
    private let showAppNameKey = "ShowAppName"
    private let showWebsiteNameKey = "ShowWebsiteName"
    private let appNameFontSizeKey = "AppNameFontSize"
    private let websiteNameFontSizeKey = "WebsiteNameFontSize"
    
    private init() {
        isInitializing = true
        
        // 加载所有设置
        loadSettings()
        
        // 初始化场景
        if scenes.isEmpty {
            // 创建默认场景
            let defaultScene = Scene(name: "默认场景", shortcuts: shortcuts)
            scenes = [defaultScene]
            currentScene = defaultScene
            saveSettings() // 保存初始场景
        }
        
        // 设置启动登录状态
        launchAtLogin = SMAppService.mainApp.status == .enabled
        
        isInitializing = false
    }
    
    func loadSettings() {
        // 加载场景数据
        if let data = UserDefaults.standard.data(forKey: "scenes"),
           let loadedScenes = try? JSONDecoder().decode([Scene].self, from: data) {
            print("[AppSettings] 成功加载 \(loadedScenes.count) 个场景")
            self.scenes = loadedScenes
            
            // 加载当前场景
            if let currentSceneIdString = UserDefaults.standard.string(forKey: "currentSceneId"),
               let currentSceneId = UUID(uuidString: currentSceneIdString) {
                self.currentScene = scenes.first { $0.id == currentSceneId }
                print("[AppSettings] 已恢复当前场景: \(self.currentScene?.name ?? "未知")")
            } else {
                self.currentScene = scenes.first
            }
            
            // 更新当前快捷键
            if let currentScene = currentScene {
                self.shortcuts = currentScene.shortcuts
                print("[AppSettings] 已加载当前场景的 \(currentScene.shortcuts.count) 个快捷键")
            }
        } else {
            // 加载旧版本的快捷键数据
            if let data = UserDefaults.standard.data(forKey: shortcutsKey),
               let shortcuts = try? JSONDecoder().decode([AppShortcut].self, from: data) {
                print("[AppSettings] 从旧版本加载了 \(shortcuts.count) 个快捷键")
                self.shortcuts = shortcuts
            }
        }
        
        // 加载主题
        if let themeString = UserDefaults.standard.string(forKey: themeKey),
           let theme = Theme(rawValue: themeString) {
            self.theme = theme
        }
        
        // 加载网站显示模式
        if let modeString = UserDefaults.standard.string(forKey: websiteDisplayModeKey) {
            print("[AppSettings] 从 UserDefaults 读取到网站显示模式: \(modeString)")
            if let mode = WebsiteDisplayMode(rawValue: modeString) {
                websiteDisplayMode = mode
                print("[AppSettings] 成功设置网站显示模式为: \(mode)")
            }
        }
        
        // 加载应用显示模式
        if let modeString = UserDefaults.standard.string(forKey: appDisplayModeKey),
           let mode = AppDisplayMode(rawValue: modeString) {
            appDisplayMode = mode
            print("[AppSettings] 成功设置应用显示模式为: \(mode)")
        }
        
        // 加载其他布尔值设置
        totalUsageCount = UserDefaults.standard.integer(forKey: usageCountKey)
        showFloatingWindow = UserDefaults.standard.bool(forKey: showFloatingWindowKey)
        showWebShortcutsInFloatingWindow = UserDefaults.standard.bool(forKey: showWebShortcutsInFloatingWindowKey)
        openOnMouseHover = UserDefaults.standard.bool(forKey: openOnMouseHoverKey)
        showWindowOnHover = UserDefaults.standard.bool(forKey: showWindowOnHoverKey)
        openWebOnHover = UserDefaults.standard.bool(forKey: openWebOnHoverKey)
        showAllAppsInFloatingWindow = UserDefaults.standard.bool(forKey: showAllAppsInFloatingWindowKey)
        
        // 加载数值设置，如果没有则使用默认值
        iconSize = UserDefaults.standard.double(forKey: iconSizeKey)
        if !UserDefaults.standard.contains(key: iconSizeKey) {
            iconSize = 48
            UserDefaults.standard.set(48, forKey: iconSizeKey)
        }
        
        appIconSize = UserDefaults.standard.double(forKey: appIconSizeKey)
        if !UserDefaults.standard.contains(key: appIconSizeKey) {
            appIconSize = 48
            UserDefaults.standard.set(48, forKey: appIconSizeKey)
        }
        
        webIconSize = UserDefaults.standard.double(forKey: webIconSizeKey)
        if !UserDefaults.standard.contains(key: webIconSizeKey) {
            webIconSize = 48
            UserDefaults.standard.set(48, forKey: webIconSizeKey)
        }
        
        floatingWindowWidth = UserDefaults.standard.double(forKey: floatingWindowWidthKey)
        if !UserDefaults.standard.contains(key: floatingWindowWidthKey) {
            floatingWindowWidth = 600
            UserDefaults.standard.set(600, forKey: floatingWindowWidthKey)
        }
        
        floatingWindowHeight = UserDefaults.standard.double(forKey: floatingWindowHeightKey)
        if !UserDefaults.standard.contains(key: floatingWindowHeightKey) {
            floatingWindowHeight = 400
            UserDefaults.standard.set(400, forKey: floatingWindowHeightKey)
        }
        
        floatingWindowOpacity = UserDefaults.standard.double(forKey: floatingWindowOpacityKey)
        if !UserDefaults.standard.contains(key: floatingWindowOpacityKey) {
            floatingWindowOpacity = 0.8
            UserDefaults.standard.set(0.8, forKey: floatingWindowOpacityKey)
        }
        
        useBlurEffect = UserDefaults.standard.bool(forKey: useBlurEffectKey)
        blurRadius = UserDefaults.standard.double(forKey: blurRadiusKey)
        if !UserDefaults.standard.contains(key: blurRadiusKey) {
            blurRadius = 20
            UserDefaults.standard.set(20, forKey: blurRadiusKey)
        }
        
        floatingWindowX = UserDefaults.standard.double(forKey: floatingWindowXKey)
        floatingWindowY = UserDefaults.standard.double(forKey: floatingWindowYKey)
        
        if let positionString = UserDefaults.standard.string(forKey: windowPositionKey),
           let position = WindowPosition(rawValue: positionString) {
            windowPosition = position
        }
        
        // 加载图标样式设置
        iconCornerRadius = UserDefaults.standard.double(forKey: iconCornerRadiusKey)
        if !UserDefaults.standard.contains(key: iconCornerRadiusKey) {
            iconCornerRadius = 8
            UserDefaults.standard.set(8, forKey: iconCornerRadiusKey)
        }
        
        iconBorderWidth = UserDefaults.standard.double(forKey: iconBorderWidthKey)
        if !UserDefaults.standard.contains(key: iconBorderWidthKey) {
            iconBorderWidth = 2
            UserDefaults.standard.set(2, forKey: iconBorderWidthKey)
        }
        
        if let colorData = UserDefaults.standard.data(forKey: iconBorderColorKey),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            iconBorderColor = Color(nsColor: color)
        }
        
        iconSpacing = UserDefaults.standard.double(forKey: iconSpacingKey)
        if !UserDefaults.standard.contains(key: iconSpacingKey) {
            iconSpacing = 4
            UserDefaults.standard.set(4, forKey: iconSpacingKey)
        }
        
        iconShadowRadius = UserDefaults.standard.double(forKey: iconShadowRadiusKey)
        if !UserDefaults.standard.contains(key: iconShadowRadiusKey) {
            iconShadowRadius = 0
            UserDefaults.standard.set(0, forKey: iconShadowRadiusKey)
        }
        
        useIconShadow = UserDefaults.standard.bool(forKey: useIconShadowKey)
        
        // 加载图标悬停动画设置
        useHoverAnimation = UserDefaults.standard.bool(forKey: useHoverAnimationKey)
        
        hoverScale = UserDefaults.standard.double(forKey: hoverScaleKey)
        if !UserDefaults.standard.contains(key: hoverScaleKey) {
            hoverScale = 1.1
            UserDefaults.standard.set(1.1, forKey: hoverScaleKey)
        }
        
        hoverAnimationDuration = UserDefaults.standard.double(forKey: hoverAnimationDurationKey)
        if !UserDefaults.standard.contains(key: hoverAnimationDurationKey) {
            hoverAnimationDuration = 0.2
            UserDefaults.standard.set(0.2, forKey: hoverAnimationDurationKey)
        }
        
        // 加载图标标签设置
        showAppName = UserDefaults.standard.bool(forKey: showAppNameKey)
        showWebsiteName = UserDefaults.standard.bool(forKey: showWebsiteNameKey)
        
        appNameFontSize = UserDefaults.standard.double(forKey: appNameFontSizeKey)
        if !UserDefaults.standard.contains(key: appNameFontSizeKey) {
            appNameFontSize = 10
            UserDefaults.standard.set(10, forKey: appNameFontSizeKey)
        }
        
        websiteNameFontSize = UserDefaults.standard.double(forKey: websiteNameFontSizeKey)
        if !UserDefaults.standard.contains(key: websiteNameFontSizeKey) {
            websiteNameFontSize = 10
            UserDefaults.standard.set(10, forKey: websiteNameFontSizeKey)
        }
        
        // 确保所有默认值都被保存
        UserDefaults.standard.synchronize()
    }
    
    func saveSettings() {
        // 避免初始化时的保存
        guard !isInitializing else { return }
        
        print("[AppSettings] 开始保存设置...")
        
        // 保存场景数据
        if let data = try? JSONEncoder().encode(scenes) {
            UserDefaults.standard.set(data, forKey: "scenes")
            print("[AppSettings] 已保存 \(scenes.count) 个场景")
        }
        
        // 保存当前场景ID
        if let currentSceneId = currentScene?.id {
            UserDefaults.standard.set(currentSceneId.uuidString, forKey: "currentSceneId")
            print("[AppSettings] 已保存当前场景ID: \(currentSceneId)")
        }
        
        // 保存其他设置
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        UserDefaults.standard.set(totalUsageCount, forKey: usageCountKey)
        UserDefaults.standard.set(showFloatingWindow, forKey: showFloatingWindowKey)
        UserDefaults.standard.set(showWebShortcutsInFloatingWindow, forKey: showWebShortcutsInFloatingWindowKey)
        UserDefaults.standard.set(openOnMouseHover, forKey: openOnMouseHoverKey)
        UserDefaults.standard.set(showWindowOnHover, forKey: showWindowOnHoverKey)
        UserDefaults.standard.set(openWebOnHover, forKey: openWebOnHoverKey)
        UserDefaults.standard.set(showAllAppsInFloatingWindow, forKey: showAllAppsInFloatingWindowKey)
        UserDefaults.standard.set(appDisplayMode.rawValue, forKey: appDisplayModeKey)
        UserDefaults.standard.set(websiteDisplayMode.rawValue, forKey: websiteDisplayModeKey)
        UserDefaults.standard.set(iconSize, forKey: iconSizeKey)
        UserDefaults.standard.set(appIconSize, forKey: appIconSizeKey)
        UserDefaults.standard.set(webIconSize, forKey: webIconSizeKey)
        UserDefaults.standard.set(floatingWindowWidth, forKey: floatingWindowWidthKey)
        UserDefaults.standard.set(floatingWindowHeight, forKey: floatingWindowHeightKey)
        UserDefaults.standard.set(floatingWindowOpacity, forKey: floatingWindowOpacityKey)
        UserDefaults.standard.set(useBlurEffect, forKey: useBlurEffectKey)
        UserDefaults.standard.set(blurRadius, forKey: blurRadiusKey)
        UserDefaults.standard.set(floatingWindowX, forKey: floatingWindowXKey)
        UserDefaults.standard.set(floatingWindowY, forKey: floatingWindowYKey)
        UserDefaults.standard.set(windowPosition.rawValue, forKey: windowPositionKey)
        UserDefaults.standard.set(iconCornerRadius, forKey: iconCornerRadiusKey)
        UserDefaults.standard.set(iconBorderWidth, forKey: iconBorderWidthKey)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: NSColor(iconBorderColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: iconBorderColorKey)
        }
        UserDefaults.standard.set(iconSpacing, forKey: iconSpacingKey)
        UserDefaults.standard.set(iconShadowRadius, forKey: iconShadowRadiusKey)
        UserDefaults.standard.set(useIconShadow, forKey: useIconShadowKey)
        
        // 保存图标悬停动画设置
        UserDefaults.standard.set(useHoverAnimation, forKey: useHoverAnimationKey)
        UserDefaults.standard.set(hoverScale, forKey: hoverScaleKey)
        UserDefaults.standard.set(hoverAnimationDuration, forKey: hoverAnimationDurationKey)
        
        // 保存图标标签设置
        UserDefaults.standard.set(showAppName, forKey: showAppNameKey)
        UserDefaults.standard.set(showWebsiteName, forKey: showWebsiteNameKey)
        UserDefaults.standard.set(appNameFontSize, forKey: appNameFontSizeKey)
        UserDefaults.standard.set(websiteNameFontSize, forKey: websiteNameFontSizeKey)
        
        // 立即同步所有设置
        UserDefaults.standard.synchronize()
        print("[AppSettings] 设置保存完成")
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

extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
} 
