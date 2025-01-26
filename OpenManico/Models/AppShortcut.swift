import Foundation
import ServiceManagement
import SwiftUI

struct AppShortcut: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    var key: String
    var bundleIdentifier: String
    var appName: String
    
    var displayKey: String {
        key
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

// 快捷键标签位置枚举
enum ShortcutLabelPosition: String, Codable {
    case top = "top"
    case bottom = "bottom"
    case left = "left"
    case right = "right"
    
    var description: String {
        switch self {
        case .top: return "顶部"
        case .bottom: return "底部"
        case .left: return "左侧"
        case .right: return "右侧"
        }
    }
}

// 在Theme枚举定义后添加
enum FloatingWindowTheme: String {
    case system = "system"
    case light = "light"
    case dark = "dark"
}

// 添加圆环主题枚举
enum CircleRingTheme: String, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var description: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
}

enum SectorHoverSoundType: String, Codable {
    case ping = "ping"
    case tink = "tink"
    case submarine = "submarine"
    case bottle = "bottle"
    case frog = "frog"
    case pop = "pop"
    case basso = "basso"
    case funk = "funk"
    case glass = "glass"
    case morse = "morse"
    case purr = "purr"
    case sosumi = "sosumi"
    // 轻快类音效
    case click = "click"
    
    var description: String {
        switch self {
        case .ping: return "Ping"
        case .tink: return "Tink"
        case .submarine: return "潜水艇"
        case .bottle: return "瓶子"
        case .frog: return "青蛙"
        case .pop: return "流行"
        case .basso: return "低音"
        case .funk: return "放克"
        case .glass: return "玻璃"
        case .morse: return "摩尔斯"
        case .purr: return "猫咪"
        case .sosumi: return "Sosumi"
        case .click: return "点击"
        }
    }
}

// 添加图标显示动效类型枚举
enum IconAppearAnimationType: String, Codable {
    case none = "none"
    case clockwise = "clockwise"
    case counterClockwise = "counterClockwise"
    
    var description: String {
        switch self {
        case .none: return "无动效"
        case .clockwise: return "顺时针"
        case .counterClockwise: return "逆时针"
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // 圆环展开动效设置
    @Published var useCircleRingAnimation: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    // 圆环长按触发时间
    @Published var circleRingLongPressThreshold: CGFloat = 0.3 {
        didSet {
            saveSettings()
        }
    }
    
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
    @Published var showAppsInFloatingWindow: Bool = true {
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
    
    // 应用快捷键标签设置
    @Published var showAppShortcutLabel: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var appShortcutLabelPosition: ShortcutLabelPosition = .bottom {
        didSet {
            saveSettings()
        }
    }
    
    @Published var appShortcutLabelBackgroundColor: Color = .black.opacity(0.6) {
        didSet {
            saveSettings()
        }
    }
    
    @Published var appShortcutLabelTextColor: Color = .white {
        didSet {
            saveSettings()
        }
    }
    
    @Published var appShortcutLabelOffsetX: Double = 0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var appShortcutLabelOffsetY: Double = 0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var appShortcutLabelFontSize: Double = 10 {
        didSet {
            saveSettings()
        }
    }
    
    // 网站快捷键标签设置
    @Published var showWebShortcutLabel: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var webShortcutLabelPosition: ShortcutLabelPosition = .bottom {
        didSet {
            saveSettings()
        }
    }
    
    @Published var webShortcutLabelBackgroundColor: Color = .black.opacity(0.6) {
        didSet {
            saveSettings()
        }
    }
    
    @Published var webShortcutLabelTextColor: Color = .white {
        didSet {
            saveSettings()
        }
    }
    
    @Published var webShortcutLabelOffsetX: Double = 0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var webShortcutLabelOffsetY: Double = 0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var webShortcutLabelFontSize: Double = 10 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var floatingWindowCornerRadius: Double = 16 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var showDivider: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var dividerOpacity: Double = 0.3 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var floatingWindowTheme: FloatingWindowTheme = .system {
        didSet {
            saveSettings()
        }
    }
    
    @Published var switchToLastAppWithOptionClick: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    // ==== 圆环模式设置 ====
    @Published var enableCircleRingMode: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    @Published var circleRingDiameter: CGFloat = 300 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var circleRingIconSize: CGFloat = 40 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var circleRingIconCornerRadius: CGFloat = 8 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var circleRingSectorCount: Int = 6 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var circleRingApps: [String] = [] {
        didSet {
            print("[AppSettings] 圆环应用更新: \(oldValue.count) -> \(circleRingApps.count)")
            saveSettings()
        }
    }
    
    @Published var circleRingTheme: CircleRingTheme = .system {
        didSet {
            saveSettings()
        }
    }
    
    @Published var circleRingInnerDiameter: CGFloat = 260 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var useSectorHighlight: Bool = true {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var sectorHighlightOpacity: CGFloat = 0.15 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var useSectorHoverSound: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    @Published var useBlurEffectForCircleRing: Bool = true {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var circleRingOpacity: CGFloat = 0.8 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var sectorHoverSoundType: SectorHoverSoundType = .ping {
        didSet {
            saveSettings()
        }
    }
    
    @Published var centerIndicatorSize: CGFloat = 8 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var showInnerCircle: Bool = true {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var innerCircleOpacity: CGFloat = 0.4 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var showInnerCircleFill: Bool = false {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var innerCircleFillOpacity: CGFloat = 0.1 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var showCenterIndicator: Bool = true {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var useIconAppearAnimation: Bool = false {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var iconAppearAnimationType: IconAppearAnimationType = .none {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var iconAppearSpeed: CGFloat = 0.06 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    // 悬浮窗置顶设置
    @Published var isPinned: Bool = false {
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
    private let showAppsInFloatingWindowKey = "ShowAppsInFloatingWindow"
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
    private let showAppShortcutLabelKey = "ShowAppShortcutLabel"
    private let appShortcutLabelPositionKey = "AppShortcutLabelPosition"
    private let appShortcutLabelBackgroundColorKey = "AppShortcutLabelBackgroundColor"
    private let appShortcutLabelTextColorKey = "AppShortcutLabelTextColor"
    private let appShortcutLabelOffsetXKey = "AppShortcutLabelOffsetX"
    private let appShortcutLabelOffsetYKey = "AppShortcutLabelOffsetY"
    private let appShortcutLabelFontSizeKey = "AppShortcutLabelFontSize"
    private let showWebShortcutLabelKey = "ShowWebShortcutLabel"
    private let webShortcutLabelPositionKey = "WebShortcutLabelPosition"
    private let webShortcutLabelBackgroundColorKey = "WebShortcutLabelBackgroundColor"
    private let webShortcutLabelTextColorKey = "WebShortcutLabelTextColor"
    private let webShortcutLabelOffsetXKey = "WebShortcutLabelOffsetX"
    private let webShortcutLabelOffsetYKey = "WebShortcutLabelOffsetY"
    private let webShortcutLabelFontSizeKey = "WebShortcutLabelFontSize"
    private let floatingWindowCornerRadiusKey = "FloatingWindowCornerRadius"
    private let showDividerKey = "ShowDivider"
    private let dividerOpacityKey = "DividerOpacity"
    private let floatingWindowThemeKey = "FloatingWindowTheme"
    private let switchToLastAppWithOptionClickKey = "SwitchToLastAppWithOptionClick"
    private let enableCircleRingModeKey = "EnableCircleRingMode"
    private let circleRingDiameterKey = "CircleRingDiameter"
    private let circleRingIconSizeKey = "CircleRingIconSize"
    private let circleRingIconCornerRadiusKey = "CircleRingIconCornerRadius"
    private let circleRingSectorCountKey = "CircleRingSectorCount"
    private let circleRingAppsKey = "CircleRingApps"
    private let circleRingThemeKey = "CircleRingTheme"
    private let circleRingInnerDiameterKey = "CircleRingInnerDiameter"
    private let useSectorHighlightKey = "UseSectorHighlight"
    private let sectorHighlightOpacityKey = "SectorHighlightOpacity"
    private let useSectorHoverSoundKey = "UseSectorHoverSound"
    private let useBlurEffectForCircleRingKey = "useBlurEffectForCircleRing"
    private let sectorHoverSoundTypeKey = "SectorHoverSoundType"
    private let centerIndicatorSizeKey = "CenterIndicatorSize"
    private let showInnerCircleKey = "ShowInnerCircle"
    private let innerCircleOpacityKey = "InnerCircleOpacity"
    private let showInnerCircleFillKey = "ShowInnerCircleFill"
    private let innerCircleFillOpacityKey = "InnerCircleFillOpacity"
    private let showCenterIndicatorKey = "ShowCenterIndicator"
    private let useCircleRingAnimationKey = "useCircleRingAnimation"
    private let circleRingLongPressThresholdKey = "circleRingLongPressThreshold"
    private let iconAppearAnimationTypeKey = "iconAppearAnimationType"
    private let iconAppearSpeedKey = "iconAppearSpeed"
    private let circleRingOpacityKey = "circleRingOpacity"
    
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
        
        appShortcutLabelFontSize = UserDefaults.standard.double(forKey: appShortcutLabelFontSizeKey)
        if !UserDefaults.standard.contains(key: appShortcutLabelFontSizeKey) {
            appShortcutLabelFontSize = 10
            UserDefaults.standard.set(10, forKey: appShortcutLabelFontSizeKey)
        }
        
        webShortcutLabelFontSize = UserDefaults.standard.double(forKey: webShortcutLabelFontSizeKey)
        if !UserDefaults.standard.contains(key: webShortcutLabelFontSizeKey) {
            webShortcutLabelFontSize = 10
            UserDefaults.standard.set(10, forKey: webShortcutLabelFontSizeKey)
        }
        
        showDivider = UserDefaults.standard.bool(forKey: showDividerKey)
        
        dividerOpacity = UserDefaults.standard.double(forKey: dividerOpacityKey)
        if !UserDefaults.standard.contains(key: dividerOpacityKey) {
            dividerOpacity = 0.3
            UserDefaults.standard.set(0.3, forKey: dividerOpacityKey)
        }
        
        showWebShortcutsInFloatingWindow = UserDefaults.standard.bool(forKey: showWebShortcutsInFloatingWindowKey)
        showAppsInFloatingWindow = UserDefaults.standard.bool(forKey: showAppsInFloatingWindowKey)
        
        // 加载悬浮窗主题设置
        if let themeString = UserDefaults.standard.string(forKey: floatingWindowThemeKey),
           let theme = FloatingWindowTheme(rawValue: themeString) {
            floatingWindowTheme = theme
        }
        
        // 加载圆环主题设置
        if let themeString = UserDefaults.standard.string(forKey: circleRingThemeKey),
           let theme = CircleRingTheme(rawValue: themeString) {
            circleRingTheme = theme
        }
        
        // 加载圆环毛玻璃效果设置
        useBlurEffectForCircleRing = UserDefaults.standard.bool(forKey: useBlurEffectForCircleRingKey)
        
        // 加载圆环透明度设置
        circleRingOpacity = UserDefaults.standard.double(forKey: circleRingOpacityKey)
        if !UserDefaults.standard.contains(key: circleRingOpacityKey) {
            circleRingOpacity = 0.8
            UserDefaults.standard.set(0.8, forKey: circleRingOpacityKey)
        }
        
        // 加载圆心大小设置
        centerIndicatorSize = UserDefaults.standard.double(forKey: centerIndicatorSizeKey)
        if !UserDefaults.standard.contains(key: centerIndicatorSizeKey) {
            centerIndicatorSize = 8
            UserDefaults.standard.set(8, forKey: centerIndicatorSizeKey)
        }
        
        // 加载内圈可见性设置
        showInnerCircle = UserDefaults.standard.bool(forKey: showInnerCircleKey)
        if !UserDefaults.standard.contains(key: showInnerCircleKey) {
            showInnerCircle = true
            UserDefaults.standard.set(true, forKey: showInnerCircleKey)
        }
        
        // 加载内圈透明度设置
        innerCircleOpacity = UserDefaults.standard.double(forKey: innerCircleOpacityKey)
        if !UserDefaults.standard.contains(key: innerCircleOpacityKey) {
            innerCircleOpacity = 0.4
            UserDefaults.standard.set(0.4, forKey: innerCircleOpacityKey)
        }
        
        // 加载内圆填充显示设置
        showInnerCircleFill = UserDefaults.standard.bool(forKey: showInnerCircleFillKey)
        if !UserDefaults.standard.contains(key: showInnerCircleFillKey) {
            showInnerCircleFill = false
            UserDefaults.standard.set(false, forKey: showInnerCircleFillKey)
        }
        
        // 加载内圆填充透明度设置
        innerCircleFillOpacity = UserDefaults.standard.double(forKey: innerCircleFillOpacityKey)
        if !UserDefaults.standard.contains(key: innerCircleFillOpacityKey) {
            innerCircleFillOpacity = 0.1
            UserDefaults.standard.set(0.1, forKey: innerCircleFillOpacityKey)
        }
        
        // 加载内圈设置
        showCenterIndicator = UserDefaults.standard.bool(forKey: showCenterIndicatorKey)
        
        if !UserDefaults.standard.contains(key: showCenterIndicatorKey) {
            showCenterIndicator = true
            UserDefaults.standard.set(true, forKey: showCenterIndicatorKey)
        }
        
        // 加载圆环动画设置
        useCircleRingAnimation = UserDefaults.standard.bool(forKey: useCircleRingAnimationKey)
        if !UserDefaults.standard.contains(key: useCircleRingAnimationKey) {
            useCircleRingAnimation = true
            UserDefaults.standard.set(true, forKey: useCircleRingAnimationKey)
        }
        
        // 加载圆环长按阈值设置
        circleRingLongPressThreshold = UserDefaults.standard.double(forKey: circleRingLongPressThresholdKey)
        if !UserDefaults.standard.contains(key: circleRingLongPressThresholdKey) {
            circleRingLongPressThreshold = 0.3
            UserDefaults.standard.set(0.3, forKey: circleRingLongPressThresholdKey)
        }
        
        // 加载图标显示动效类型
        if let animTypeString = UserDefaults.standard.string(forKey: iconAppearAnimationTypeKey),
           let animType = IconAppearAnimationType(rawValue: animTypeString) {
            iconAppearAnimationType = animType
        } else {
            // 兼容旧版本：如果之前使用了布尔设置，转换为新的枚举类型
            if UserDefaults.standard.bool(forKey: "useIconAppearAnimation") {
                iconAppearAnimationType = .clockwise
            } else {
                iconAppearAnimationType = .none
            }
        }
        
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
        showAllAppsInFloatingWindow = UserDefaults.standard.bool(forKey: showAllAppsInFloatingWindowKey)
        switchToLastAppWithOptionClick = UserDefaults.standard.bool(forKey: switchToLastAppWithOptionClickKey)
        
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
        
        // 加载快捷键标签设置
        showAppShortcutLabel = UserDefaults.standard.bool(forKey: showAppShortcutLabelKey)
        appShortcutLabelPosition = ShortcutLabelPosition(rawValue: UserDefaults.standard.string(forKey: appShortcutLabelPositionKey) ?? "bottom") ?? .bottom
        
        if let colorData = UserDefaults.standard.data(forKey: appShortcutLabelBackgroundColorKey),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            appShortcutLabelBackgroundColor = Color(nsColor: color)
        } else {
            appShortcutLabelBackgroundColor = Color.black.opacity(0.6)
        }
        
        if let colorData = UserDefaults.standard.data(forKey: appShortcutLabelTextColorKey),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            appShortcutLabelTextColor = Color(nsColor: color)
        } else {
            appShortcutLabelTextColor = .white
        }
        
        appShortcutLabelOffsetX = UserDefaults.standard.double(forKey: appShortcutLabelOffsetXKey)
        appShortcutLabelOffsetY = UserDefaults.standard.double(forKey: appShortcutLabelOffsetYKey)
        appShortcutLabelFontSize = UserDefaults.standard.double(forKey: appShortcutLabelFontSizeKey)
        
        showWebShortcutLabel = UserDefaults.standard.bool(forKey: showWebShortcutLabelKey)
        webShortcutLabelPosition = ShortcutLabelPosition(rawValue: UserDefaults.standard.string(forKey: webShortcutLabelPositionKey) ?? "bottom") ?? .bottom
        
        if let colorData = UserDefaults.standard.data(forKey: webShortcutLabelBackgroundColorKey),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            webShortcutLabelBackgroundColor = Color(nsColor: color)
        } else {
            webShortcutLabelBackgroundColor = Color.black.opacity(0.6)
        }
        
        if let colorData = UserDefaults.standard.data(forKey: webShortcutLabelTextColorKey),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            webShortcutLabelTextColor = Color(nsColor: color)
        } else {
            webShortcutLabelTextColor = .white
        }
        
        webShortcutLabelOffsetX = UserDefaults.standard.double(forKey: webShortcutLabelOffsetXKey)
        webShortcutLabelOffsetY = UserDefaults.standard.double(forKey: webShortcutLabelOffsetYKey)
        webShortcutLabelFontSize = UserDefaults.standard.double(forKey: webShortcutLabelFontSizeKey)
        
        floatingWindowCornerRadius = UserDefaults.standard.double(forKey: floatingWindowCornerRadiusKey)
        if !UserDefaults.standard.contains(key: floatingWindowCornerRadiusKey) {
            floatingWindowCornerRadius = 16
            UserDefaults.standard.set(16, forKey: floatingWindowCornerRadiusKey)
        }
        
        // 加载圆环模式设置
        enableCircleRingMode = UserDefaults.standard.bool(forKey: enableCircleRingModeKey)
        
        circleRingDiameter = UserDefaults.standard.double(forKey: circleRingDiameterKey)
        if !UserDefaults.standard.contains(key: circleRingDiameterKey) {
            circleRingDiameter = 300
            UserDefaults.standard.set(300, forKey: circleRingDiameterKey)
        }
        
        circleRingIconSize = UserDefaults.standard.double(forKey: circleRingIconSizeKey)
        if !UserDefaults.standard.contains(key: circleRingIconSizeKey) {
            circleRingIconSize = 40
            UserDefaults.standard.set(40, forKey: circleRingIconSizeKey)
        }
        
        circleRingIconCornerRadius = UserDefaults.standard.double(forKey: circleRingIconCornerRadiusKey)
        if !UserDefaults.standard.contains(key: circleRingIconCornerRadiusKey) {
            circleRingIconCornerRadius = 8
            UserDefaults.standard.set(8, forKey: circleRingIconCornerRadiusKey)
        }
        
        circleRingSectorCount = UserDefaults.standard.integer(forKey: circleRingSectorCountKey)
        if !UserDefaults.standard.contains(key: circleRingSectorCountKey) {
            circleRingSectorCount = 6
            UserDefaults.standard.set(6, forKey: circleRingSectorCountKey)
        }
        
        circleRingInnerDiameter = UserDefaults.standard.double(forKey: circleRingInnerDiameterKey)
        if !UserDefaults.standard.contains(key: circleRingInnerDiameterKey) {
            circleRingInnerDiameter = 260
            UserDefaults.standard.set(260, forKey: circleRingInnerDiameterKey)
        }
        
        useSectorHighlight = UserDefaults.standard.bool(forKey: useSectorHighlightKey)
        if !UserDefaults.standard.contains(key: useSectorHighlightKey) {
            useSectorHighlight = true
            UserDefaults.standard.set(true, forKey: useSectorHighlightKey)
        }
        
        sectorHighlightOpacity = UserDefaults.standard.double(forKey: sectorHighlightOpacityKey)
        if !UserDefaults.standard.contains(key: sectorHighlightOpacityKey) {
            sectorHighlightOpacity = 0.15
            UserDefaults.standard.set(0.15, forKey: sectorHighlightOpacityKey)
        }
        
        useSectorHoverSound = UserDefaults.standard.bool(forKey: useSectorHoverSoundKey)
        
        if let soundTypeString = UserDefaults.standard.string(forKey: sectorHoverSoundTypeKey),
           let soundType = SectorHoverSoundType(rawValue: soundTypeString) {
            sectorHoverSoundType = soundType
        } else {
            sectorHoverSoundType = .ping
        }
        
        if let appsData = UserDefaults.standard.array(forKey: circleRingAppsKey) as? [String] {
            circleRingApps = appsData
            print("[AppSettings] 加载了 \(circleRingApps.count) 个圆环应用")
        } else {
            print("[AppSettings] 未找到已保存的圆环应用")
            circleRingApps = []
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
        UserDefaults.standard.set(showAppsInFloatingWindow, forKey: showAppsInFloatingWindowKey)
        UserDefaults.standard.set(openOnMouseHover, forKey: openOnMouseHoverKey)
        UserDefaults.standard.set(showWindowOnHover, forKey: showWindowOnHoverKey)
        UserDefaults.standard.set(openWebOnHover, forKey: openWebOnHoverKey)
        UserDefaults.standard.set(showAllAppsInFloatingWindow, forKey: showAllAppsInFloatingWindowKey)
        UserDefaults.standard.set(switchToLastAppWithOptionClick, forKey: switchToLastAppWithOptionClickKey)
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
        
        // 保存快捷键标签设置
        UserDefaults.standard.set(showAppShortcutLabel, forKey: showAppShortcutLabelKey)
        UserDefaults.standard.set(appShortcutLabelPosition.rawValue, forKey: appShortcutLabelPositionKey)
        
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: NSColor(appShortcutLabelBackgroundColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: appShortcutLabelBackgroundColorKey)
        }
        
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: NSColor(appShortcutLabelTextColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: appShortcutLabelTextColorKey)
        }
        
        UserDefaults.standard.set(appShortcutLabelOffsetX, forKey: appShortcutLabelOffsetXKey)
        UserDefaults.standard.set(appShortcutLabelOffsetY, forKey: appShortcutLabelOffsetYKey)
        UserDefaults.standard.set(appShortcutLabelFontSize, forKey: appShortcutLabelFontSizeKey)
        
        UserDefaults.standard.set(showWebShortcutLabel, forKey: showWebShortcutLabelKey)
        UserDefaults.standard.set(webShortcutLabelPosition.rawValue, forKey: webShortcutLabelPositionKey)
        
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: NSColor(webShortcutLabelBackgroundColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: webShortcutLabelBackgroundColorKey)
        }
        
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: NSColor(webShortcutLabelTextColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: webShortcutLabelTextColorKey)
        }
        
        UserDefaults.standard.set(webShortcutLabelOffsetX, forKey: webShortcutLabelOffsetXKey)
        UserDefaults.standard.set(webShortcutLabelOffsetY, forKey: webShortcutLabelOffsetYKey)
        UserDefaults.standard.set(webShortcutLabelFontSize, forKey: webShortcutLabelFontSizeKey)
        
        UserDefaults.standard.set(floatingWindowCornerRadius, forKey: floatingWindowCornerRadiusKey)
        UserDefaults.standard.set(showDivider, forKey: showDividerKey)
        UserDefaults.standard.set(dividerOpacity, forKey: dividerOpacityKey)
        
        // 保存悬浮窗主题设置
        UserDefaults.standard.set(floatingWindowTheme.rawValue, forKey: floatingWindowThemeKey)
        
        // 保存圆环模式设置
        UserDefaults.standard.set(enableCircleRingMode, forKey: enableCircleRingModeKey)
        UserDefaults.standard.set(circleRingDiameter, forKey: circleRingDiameterKey)
        UserDefaults.standard.set(circleRingIconSize, forKey: circleRingIconSizeKey)
        UserDefaults.standard.set(circleRingIconCornerRadius, forKey: circleRingIconCornerRadiusKey)
        UserDefaults.standard.set(circleRingSectorCount, forKey: circleRingSectorCountKey)
        UserDefaults.standard.set(circleRingApps, forKey: circleRingAppsKey)
        print("[AppSettings] 保存 \(circleRingApps.count) 个圆环应用: \(circleRingApps)")
        UserDefaults.standard.set(circleRingTheme.rawValue, forKey: circleRingThemeKey)
        UserDefaults.standard.set(circleRingInnerDiameter, forKey: circleRingInnerDiameterKey)
        UserDefaults.standard.set(useSectorHighlight, forKey: useSectorHighlightKey)
        UserDefaults.standard.set(sectorHighlightOpacity, forKey: sectorHighlightOpacityKey)
        UserDefaults.standard.set(useSectorHoverSound, forKey: useSectorHoverSoundKey)
        UserDefaults.standard.set(useBlurEffectForCircleRing, forKey: useBlurEffectForCircleRingKey)
        UserDefaults.standard.set(sectorHoverSoundType.rawValue, forKey: sectorHoverSoundTypeKey)
        UserDefaults.standard.set(centerIndicatorSize, forKey: centerIndicatorSizeKey)
        UserDefaults.standard.set(showInnerCircle, forKey: showInnerCircleKey)
        UserDefaults.standard.set(innerCircleOpacity, forKey: innerCircleOpacityKey)
        UserDefaults.standard.set(showInnerCircleFill, forKey: showInnerCircleFillKey)
        UserDefaults.standard.set(innerCircleFillOpacity, forKey: innerCircleFillOpacityKey)
        UserDefaults.standard.set(showCenterIndicator, forKey: showCenterIndicatorKey)
        UserDefaults.standard.set(useCircleRingAnimation, forKey: useCircleRingAnimationKey)
        UserDefaults.standard.set(circleRingLongPressThreshold, forKey: circleRingLongPressThresholdKey)
        UserDefaults.standard.set(iconAppearAnimationType.rawValue, forKey: iconAppearAnimationTypeKey)
        UserDefaults.standard.set(iconAppearSpeed, forKey: iconAppearSpeedKey)
        UserDefaults.standard.set(useBlurEffectForCircleRing, forKey: useBlurEffectForCircleRingKey)
        UserDefaults.standard.set(circleRingOpacity, forKey: circleRingOpacityKey)
        
        // 立即同步所有设置
        UserDefaults.standard.synchronize()
        
        // 发布设置更改通知
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        
        print("[AppSettings] 设置保存完成")
    }
    
    func incrementUsageCount() {
        totalUsageCount += 1
        UserDefaults.standard.set(totalUsageCount, forKey: usageCountKey)
        
        // 同时记录每日使用量
        UsageStatsManager.shared.recordUsage()
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
        let webShortcuts = WebsiteManager.shared.websites.compactMap { website -> [String: String]? in
            guard let key = website.shortcutKey else { return nil }
            return [
                "key": key,
                "url": website.url,
                "name": website.name
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
        let websites = WebsiteManager.shared.websites.filter { $0.shortcutKey != nil }
        let sortedWebsites = websites.sorted { $0.shortcutKey ?? "" < $1.shortcutKey ?? "" }
        if sortedWebsites.isEmpty { return }
        
        if selectedWebShortcutIndex == -1 {
            selectedWebShortcutIndex = 0
        } else {
            selectedWebShortcutIndex = (selectedWebShortcutIndex + 1) % sortedWebsites.count
        }
    }
    
    var selectedShortcut: AppShortcut? {
        let sortedShortcuts = shortcuts.sorted(by: { $0.key < $1.key })
        guard selectedShortcutIndex >= 0 && selectedShortcutIndex < sortedShortcuts.count else {
            return nil
        }
        return sortedShortcuts[selectedShortcutIndex]
    }
    
    var selectedWebShortcut: Website? {
        let websites = WebsiteManager.shared.getWebsites(mode: .shortcutOnly)
        let sortedWebsites = websites.sorted { $0.shortcutKey ?? "" < $1.shortcutKey ?? "" }
        guard selectedWebShortcutIndex >= 0 && selectedWebShortcutIndex < sortedWebsites.count else {
            return nil
        }
        return sortedWebsites[selectedWebShortcutIndex]
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

class AppShortcutManager: ObservableObject {
    static let shared = AppShortcutManager()
    
    @Published var shortcuts: [AppShortcut] = []
    
    private init() {
        loadShortcuts()
    }
    
    private func loadShortcuts() {
        if let data = UserDefaults.standard.data(forKey: "AppShortcuts") {
            do {
                shortcuts = try JSONDecoder().decode([AppShortcut].self, from: data)
            } catch {
                print("[AppShortcutManager] ❌ 加载快捷键失败: \(error)")
            }
        }
    }
    
    private func saveShortcuts() {
        do {
            let data = try JSONEncoder().encode(shortcuts)
            UserDefaults.standard.set(data, forKey: "AppShortcuts")
        } catch {
            print("[AppShortcutManager] ❌ 保存快捷键失败: \(error)")
        }
    }
    
    func addShortcut(_ shortcut: AppShortcut) {
        shortcuts.append(shortcut)
        saveShortcuts()
    }
    
    func updateShortcut(_ shortcut: AppShortcut) {
        if let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            shortcuts[index] = shortcut
            saveShortcuts()
        }
    }
    
    func deleteShortcut(_ shortcut: AppShortcut) {
        shortcuts.removeAll { $0.id == shortcut.id }
        saveShortcuts()
    }
} 
