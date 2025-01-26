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
    case runningOnly = "running"   // 只显示正在运行的应用
    
    var description: String {
        switch self {
        case .all:
            return "显示所有应用"
        case .runningOnly:
            return "只显示运行中应用"
        }
    }
}

enum WebsiteDisplayMode: String, Codable {
    case all = "all"
    
    var description: String {
        switch self {
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

// 添加扇区高亮颜色枚举
enum SectorHighlightColorType: String, Codable {
    case auto = "auto"
    case white = "white"
    case black = "black"
    case red = "red"
    case blue = "blue"
    case green = "green"
    case yellow = "yellow"
    case purple = "purple"
    case orange = "orange"
    
    var description: String {
        switch self {
        case .auto: return "自动(跟随主题)"
        case .white: return "白色"
        case .black: return "黑色"
        case .red: return "红色"
        case .blue: return "蓝色"
        case .green: return "绿色"
        case .yellow: return "黄色"
        case .purple: return "紫色"
        case .orange: return "橙色"
        }
    }
    
    var color: Color {
        switch self {
        case .auto: return Color.clear // 特殊标记，表示自动
        case .white: return Color.white
        case .black: return Color.black
        case .red: return Color.red
        case .blue: return Color.blue
        case .green: return Color.green
        case .yellow: return Color.yellow
        case .purple: return Color.purple
        case .orange: return Color.orange
        }
    }
}

// 添加震动强度枚举
enum HapticFeedbackStrength: String, Codable {
    case light = "light"
    case medium = "medium"
    case strong = "strong"
    
    var description: String {
        switch self {
        case .light: return "轻微"
        case .medium: return "中等"
        case .strong: return "强烈"
        }
    }
}

// 添加圆环启动音效类型枚举
enum CircleRingStartupSoundType: String, Codable {
    case none = "none"
    case hero = "hero"
    case magic = "magic"
    case sparkle = "sparkle"
    case chime = "chime"
    case bell = "bell"
    case crystal = "crystal"
    case cosmic = "cosmic"
    case fairy = "fairy"
    case mystic = "mystic"
    
    var description: String {
        switch self {
        case .none: return "无音效"
        case .hero: return "英雄登场"
        case .magic: return "魔法闪现"
        case .sparkle: return "星光闪耀"
        case .chime: return "风铃轻响"
        case .bell: return "钟声回荡"
        case .crystal: return "水晶共鸣"
        case .cosmic: return "宇宙之音"
        case .fairy: return "精灵低语"
        case .mystic: return "神秘召唤"
        }
    }
}

// 悬浮窗中分组显示位置
enum GroupDisplayPosition: String, CaseIterable, Identifiable, Codable {
    case horizontal = "horizontal" // 水平显示在顶部
    case vertical = "vertical"     // 垂直显示在应用模式切换按钮下方
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .horizontal: return "水平排列在顶部"
        case .vertical: return "垂直排列在左侧"
        }
    }
}

enum AppWebsiteOrder: String, Codable {
    case appFirst = "appFirst"
    case websiteFirst = "websiteFirst"
    
    var description: String {
        switch self {
        case .appFirst: return "应用区域在前"
        case .websiteFirst: return "网站区域在前"
        }
    }
}

enum LayoutDirection: String, Codable {
    case vertical = "vertical"   // 上下布局
    case horizontal = "horizontal" // 左右布局
    
    var description: String {
        switch self {
        case .vertical: return "上下布局"
        case .horizontal: return "左右布局"
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // 圆环展开动效设置
    @Published var useCircleRingAnimation: Bool = true {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    // 圆环长按触发时间
    @Published var circleRingLongPressThreshold: CGFloat = 0.1 {
        didSet {
            saveSettings()
        }
    }
    
    // 新增：鼠标滑过刘海区域显示悬浮窗
    @Published var showOnMenuBarHover: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    // 圆环展开动效速度
    @Published var circleRingAnimationSpeed: CGFloat = 0.2 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
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
    
    @Published var useBlurEffect: Bool = true {
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
    @Published var openAppOnMouseHover: Bool = false {
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
    @Published var websiteDisplayMode: WebsiteDisplayMode = .all {
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
    
    @Published var iconGridSpacing: Double = 16 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var iconShadowRadius: Double = 2 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var useIconShadow: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var useHoverBackground: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    @Published var iconHoverBackgroundColor: Color = Color.blue.opacity(0.2) {
        didSet {
            saveSettings()
        }
    }
    
    @Published var iconHoverBackgroundPadding: Double = 4 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var iconHoverBackgroundCornerRadius: Double = 8 {
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
    
    // 悬浮窗分组设置
    @Published var showGroupsInFloatingWindow: Bool = true {
        didSet {
            saveSettings()
            DockIconsWindowController.shared.updateWindow()
        }
    }
    
    @Published var showGroupCountInFloatingWindow: Bool = false {
        didSet {
            saveSettings()
            DockIconsWindowController.shared.updateWindow()
        }
    }
    
    // ==== 圆环模式设置 ====
    @Published var enableCircleRingMode: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    @Published var showAppNameInCircleRing: Bool = true {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var circleRingDiameter: CGFloat = 280 {
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
    
    @Published var circleRingInnerDiameter: CGFloat = 100 {
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
    
    @Published var sectorHighlightOpacity: CGFloat = 1.0 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var sectorHighlightColor: SectorHighlightColorType = .blue {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var useSectorHoverSound: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var useCircleRingStartupSound: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    @Published var circleRingStartupSoundType: CircleRingStartupSoundType = .none {
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
    
    @Published var sectorHoverSoundType: SectorHoverSoundType = .frog {
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
    
    @Published var showInnerCircle: Bool = false {
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
    
    @Published var innerCircleFillOpacity: CGFloat = 0.15 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    @Published var showCenterIndicator: Bool = false {
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
    
    @Published var iconAppearSpeed: CGFloat = 0.04 {
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
    
    // 悬浮窗工具栏显示设置
    @Published var showToolbar: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    // 新增内圆自定义图片设置
    @Published var showCustomImageInCircle: Bool = false {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    // 存储自定义图片路径
    @Published var customCircleImagePath: String = "" {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    // 自定义图片大小比例(占内圆的百分比)
    @Published var customCircleImageScale: CGFloat = 0.7 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    // 自定义图片透明度
    @Published var customCircleImageOpacity: CGFloat = 0.8 {
        didSet {
            saveSettings()
            CircleRingController.shared.reloadCircleRing()
        }
    }
    
    // 扇区悬停震动相关设置
    @Published var useSectorHoverHaptic: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var sectorHoverHapticStrength: HapticFeedbackStrength = .medium {
        didSet {
            saveSettings()
        }
    }
    
    // 添加在AppSettings类中的属性列表中
    @Published var showRunningIndicator: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var runningIndicatorColor: Color = .blue {
        didSet {
            saveSettings()
        }
    }
    
    @Published var runningIndicatorSize: Double = 6 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var runningIndicatorPosition: ShortcutLabelPosition = .bottom {
        didSet {
            saveSettings()
        }
    }
    
    // 悬浮窗中分组显示位置
    @Published var groupDisplayPosition: GroupDisplayPosition = .horizontal {
        didSet {
            saveSettings()
        }
    }
    
    // 悬浮窗中网站分组显示位置
    @Published var webGroupDisplayPosition: GroupDisplayPosition = .horizontal {
        didSet {
            saveSettings()
        }
    }
    
    // 应用和网站区域显示位置
    @Published var appWebsiteOrder: AppWebsiteOrder = .appFirst {
        didSet {
            saveSettings()
            DockIconsWindowController.shared.updateWindow()
        }
    }
    
    // 应用区域占比 (0.1-0.9)
    @Published var appAreaRatio: Double = 0.5 {
        didSet {
            saveSettings()
            DockIconsWindowController.shared.updateWindow()
        }
    }
    
    // 布局方向：上下还是左右
    @Published var layoutDirection: LayoutDirection = .vertical {
        didSet {
            saveSettings()
            DockIconsWindowController.shared.updateWindow()
        }
    }
    
    // 区域间隔大小
    @Published var areaSeparatorSize: Double = 8.0 {
        didSet {
            saveSettings()
            DockIconsWindowController.shared.updateWindow()
        }
    }
    
    // 在AppSettings类中添加一个新的属性，放在其他相似的Toggle属性附近
    @Published var clickAppToToggle: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    // 添加新的布尔属性，放在其他类似的Toggle属性附近
    @Published var clickCircleAppToToggle: Bool = true {
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
    private let iconSpacingKey = "iconSpacing"
    private let iconGridSpacingKey = "iconGridSpacing"
    private let iconShadowRadiusKey = "iconShadowRadius"
    private let useIconShadowKey = "UseIconShadow"
    private let useHoverBackgroundKey = "UseHoverBackground"
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
    private let showToolbarKey = "ShowToolbar"
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
    private let useBlurEffectForCircleRingKey = "UseBlurEffectForCircleRing"
    private let sectorHoverSoundTypeKey = "SectorHoverSoundType"
    private let centerIndicatorSizeKey = "CenterIndicatorSize"
    private let showInnerCircleKey = "ShowInnerCircle"
    private let innerCircleOpacityKey = "InnerCircleOpacity"
    private let showInnerCircleFillKey = "ShowInnerCircleFill"
    private let innerCircleFillOpacityKey = "InnerCircleFillOpacity"
    private let showCenterIndicatorKey = "ShowCenterIndicator"
    private let useCircleRingAnimationKey = "UseCircleRingAnimation"
    private let circleRingLongPressThresholdKey = "CircleRingLongPressThreshold"
    private let circleRingAnimationSpeedKey = "CircleRingAnimationSpeed"
    private let iconAppearAnimationTypeKey = "IconAppearAnimationType"
    private let iconAppearSpeedKey = "IconAppearSpeed"
    private let circleRingOpacityKey = "CircleRingOpacity"
    private let sectorHighlightColorKey = "SectorHighlightColor"
    private let showAppNameInCircleRingKey = "ShowAppNameInCircleRing"
    private let showCustomImageInCircleKey = "ShowCustomImageInCircle"
    private let customCircleImagePathKey = "CustomCircleImagePath"
    private let customCircleImageScaleKey = "CustomCircleImageScale"
    private let customCircleImageOpacityKey = "CustomCircleImageOpacity"
    private let showOnMenuBarHoverKey = "ShowOnMenuBarHover"
    private let useSectorHoverHapticKey = "UseSectorHoverHaptic"
    private let sectorHoverHapticStrengthKey = "SectorHoverHapticStrength"
    private let groupDisplayPositionKey = "GroupDisplayPosition"
    private let webGroupDisplayPositionKey = "WebGroupDisplayPosition"
    private let appWebsiteOrderKey = "AppWebsiteOrder"
    private let appAreaRatioKey = "AppAreaRatio"
    private let layoutDirectionKey = "LayoutDirection"
    private let areaSeparatorSizeKey = "AreaSeparatorSize"
    
    // 图标悬停背景设置键名
    private let iconHoverBackgroundColorKey = "IconHoverBackgroundColor"
    private let iconHoverBackgroundPaddingKey = "IconHoverBackgroundPadding"
    private let iconHoverBackgroundCornerRadiusKey = "IconHoverBackgroundCornerRadius"
    
    // 运行中应用标识设置键名
    private let showRunningIndicatorKey = "showRunningIndicator"
    private let runningIndicatorColorKey = "runningIndicatorColor"
    private let runningIndicatorSizeKey = "runningIndicatorSize"
    private let runningIndicatorPositionKey = "runningIndicatorPosition"
    
    // 在私有键名常量区域添加新的键名
    private let clickAppToToggleKey = "ClickAppToToggle"
    private let clickCircleAppToToggleKey = "ClickCircleAppToToggle"
    
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
        
        // 注意：此处之前存在键名不一致问题，导致某些设置无法持久化
        // 已修复所有圆环模式设置的键名，统一为首字母大写格式
        // 并优化了loadSettings方法，确保所有设置项都能正确加载
        
        // 初始化完成，确保将标志设置为false
        print("[AppSettings] 初始化完成")
        isInitializing = false
    }
    
    func loadSettings() {
        print("[AppSettings] 开始加载设置...")
        isInitializing = true
        
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
            iconSize = 80
            UserDefaults.standard.set(80, forKey: iconSizeKey)
        }
        
        appIconSize = UserDefaults.standard.double(forKey: appIconSizeKey)
        if !UserDefaults.standard.contains(key: appIconSizeKey) {
            appIconSize = 80
            UserDefaults.standard.set(80, forKey: appIconSizeKey)
        }
        
        webIconSize = UserDefaults.standard.double(forKey: webIconSizeKey)
        if !UserDefaults.standard.contains(key: webIconSizeKey) {
            webIconSize = 80
            UserDefaults.standard.set(80, forKey: webIconSizeKey)
        }
        
        floatingWindowWidth = UserDefaults.standard.double(forKey: floatingWindowWidthKey)
        if !UserDefaults.standard.contains(key: floatingWindowWidthKey) {
            floatingWindowWidth = 1000
            UserDefaults.standard.set(1000, forKey: floatingWindowWidthKey)
        }
        
        floatingWindowHeight = UserDefaults.standard.double(forKey: floatingWindowHeightKey)
        if !UserDefaults.standard.contains(key: floatingWindowHeightKey) {
            floatingWindowHeight = 500
            UserDefaults.standard.set(500, forKey: floatingWindowHeightKey)
        }
        
        floatingWindowOpacity = UserDefaults.standard.double(forKey: floatingWindowOpacityKey)
        if !UserDefaults.standard.contains(key: floatingWindowOpacityKey) {
            floatingWindowOpacity = 0.8
            UserDefaults.standard.set(0.8, forKey: floatingWindowOpacityKey)
        }
        
        useBlurEffect = UserDefaults.standard.bool(forKey: useBlurEffectKey)
        if !UserDefaults.standard.contains(key: useBlurEffectKey) {
            useBlurEffect = true
            UserDefaults.standard.set(true, forKey: useBlurEffectKey)
        }
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
            iconCornerRadius = 16
            UserDefaults.standard.set(16, forKey: iconCornerRadiusKey)
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
        
        iconGridSpacing = UserDefaults.standard.double(forKey: iconGridSpacingKey)
        if !UserDefaults.standard.contains(key: iconGridSpacingKey) {
            iconGridSpacing = 16
            UserDefaults.standard.set(16, forKey: iconGridSpacingKey)
        }
        
        iconShadowRadius = UserDefaults.standard.double(forKey: iconShadowRadiusKey)
        if !UserDefaults.standard.contains(key: iconShadowRadiusKey) {
            iconShadowRadius = 4
            UserDefaults.standard.set(4, forKey: iconShadowRadiusKey)
        }
        
        useIconShadow = UserDefaults.standard.bool(forKey: useIconShadowKey)
        if !UserDefaults.standard.contains(key: useIconShadowKey) {
            useIconShadow = true
            UserDefaults.standard.set(true, forKey: useIconShadowKey)
        }
        
        // 加载图标悬停背景设置
        if let colorData = UserDefaults.standard.data(forKey: iconHoverBackgroundColorKey),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            iconHoverBackgroundColor = Color(color)
        }
        
        iconHoverBackgroundPadding = UserDefaults.standard.double(forKey: iconHoverBackgroundPaddingKey)
        if !UserDefaults.standard.contains(key: iconHoverBackgroundPaddingKey) {
            iconHoverBackgroundPadding = 4
            UserDefaults.standard.set(4, forKey: iconHoverBackgroundPaddingKey)
        }
        
        iconHoverBackgroundCornerRadius = UserDefaults.standard.double(forKey: iconHoverBackgroundCornerRadiusKey)
        if !UserDefaults.standard.contains(key: iconHoverBackgroundCornerRadiusKey) {
            iconHoverBackgroundCornerRadius = 8
            UserDefaults.standard.set(8, forKey: iconHoverBackgroundCornerRadiusKey)
        }
        
        // 加载图标悬停动画设置
        useHoverAnimation = UserDefaults.standard.bool(forKey: useHoverAnimationKey)
        if !UserDefaults.standard.contains(key: useHoverAnimationKey) {
            useHoverAnimation = true
            UserDefaults.standard.set(true, forKey: useHoverAnimationKey)
        }
        
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
        if !UserDefaults.standard.contains(key: showAppNameKey) {
            showAppName = true
            UserDefaults.standard.set(true, forKey: showAppNameKey)
        }
        
        showWebsiteName = UserDefaults.standard.bool(forKey: showWebsiteNameKey)
        if !UserDefaults.standard.contains(key: showWebsiteNameKey) {
            showWebsiteName = true
            UserDefaults.standard.set(true, forKey: showWebsiteNameKey)
        }
        
        appNameFontSize = UserDefaults.standard.double(forKey: appNameFontSizeKey)
        if !UserDefaults.standard.contains(key: appNameFontSizeKey) {
            appNameFontSize = 12
            UserDefaults.standard.set(12, forKey: appNameFontSizeKey)
        }
        
        websiteNameFontSize = UserDefaults.standard.double(forKey: websiteNameFontSizeKey)
        if !UserDefaults.standard.contains(key: websiteNameFontSizeKey) {
            websiteNameFontSize = 10
            UserDefaults.standard.set(10, forKey: websiteNameFontSizeKey)
        }
        
        // 加载鼠标滑过刘海区域显示悬浮窗设置
        showOnMenuBarHover = UserDefaults.standard.bool(forKey: showOnMenuBarHoverKey)
        
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
        
        // 加载悬浮窗主题设置
        if let themeString = UserDefaults.standard.string(forKey: floatingWindowThemeKey),
           let theme = FloatingWindowTheme(rawValue: themeString) {
            floatingWindowTheme = theme
        }
        
        // 加载悬浮窗工具栏显示设置
        showToolbar = UserDefaults.standard.bool(forKey: showToolbarKey)
        if !UserDefaults.standard.contains(key: showToolbarKey) {
            showToolbar = true
            UserDefaults.standard.set(true, forKey: showToolbarKey)
        }
        
        showDivider = UserDefaults.standard.bool(forKey: showDividerKey)
        
        dividerOpacity = UserDefaults.standard.double(forKey: dividerOpacityKey)
        if !UserDefaults.standard.contains(key: dividerOpacityKey) {
            dividerOpacity = 0.3
            UserDefaults.standard.set(0.3, forKey: dividerOpacityKey)
        }
        
        showWebShortcutsInFloatingWindow = UserDefaults.standard.bool(forKey: showWebShortcutsInFloatingWindowKey)
        
        // 修改showAppsInFloatingWindow的加载逻辑，确保默认值为true
        showAppsInFloatingWindow = UserDefaults.standard.bool(forKey: showAppsInFloatingWindowKey)
        if !UserDefaults.standard.contains(key: showAppsInFloatingWindowKey) {
            showAppsInFloatingWindow = true
            UserDefaults.standard.set(true, forKey: showAppsInFloatingWindowKey)
        }
        
        // 加载圆环模式设置
        enableCircleRingMode = UserDefaults.standard.bool(forKey: enableCircleRingModeKey)
        
        // 加载圆环主题设置
        if let themeString = UserDefaults.standard.string(forKey: circleRingThemeKey),
           let theme = CircleRingTheme(rawValue: themeString) {
            circleRingTheme = theme
        }
        
        // 加载长按时间阈值
        circleRingLongPressThreshold = UserDefaults.standard.double(forKey: circleRingLongPressThresholdKey)
        if !UserDefaults.standard.contains(key: circleRingLongPressThresholdKey) {
            circleRingLongPressThreshold = 0.1
            UserDefaults.standard.set(0.1, forKey: circleRingLongPressThresholdKey)
        }
        
        // 加载高亮颜色设置
        if let colorString = UserDefaults.standard.string(forKey: sectorHighlightColorKey), 
           let color = SectorHighlightColorType(rawValue: colorString) {
            sectorHighlightColor = color
        } else {
            sectorHighlightColor = .blue
            UserDefaults.standard.set(SectorHighlightColorType.blue.rawValue, forKey: sectorHighlightColorKey)
        }
        
        // 加载圆环展开动效设置
        useCircleRingAnimation = UserDefaults.standard.bool(forKey: useCircleRingAnimationKey)
        if !UserDefaults.standard.contains(key: useCircleRingAnimationKey) {
            useCircleRingAnimation = true
            UserDefaults.standard.set(true, forKey: useCircleRingAnimationKey)
        }
        
        // 加载圆环展开动效速度
        circleRingAnimationSpeed = UserDefaults.standard.double(forKey: circleRingAnimationSpeedKey)
        if !UserDefaults.standard.contains(key: circleRingAnimationSpeedKey) {
            circleRingAnimationSpeed = 0.2
            UserDefaults.standard.set(0.2, forKey: circleRingAnimationSpeedKey)
        }
        
        // 加载内圈可见性设置
        showInnerCircle = UserDefaults.standard.bool(forKey: showInnerCircleKey)
        if !UserDefaults.standard.contains(key: showInnerCircleKey) {
            showInnerCircle = false
            UserDefaults.standard.set(false, forKey: showInnerCircleKey)
        }
        
        // 加载内圈透明度设置
        innerCircleOpacity = CGFloat(UserDefaults.standard.double(forKey: innerCircleOpacityKey))
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
        innerCircleFillOpacity = CGFloat(UserDefaults.standard.double(forKey: innerCircleFillOpacityKey))
        if !UserDefaults.standard.contains(key: innerCircleFillOpacityKey) {
            innerCircleFillOpacity = 0.15
            UserDefaults.standard.set(0.15, forKey: innerCircleFillOpacityKey)
        }
        
        // 加载中央指示器设置
        showCenterIndicator = UserDefaults.standard.bool(forKey: showCenterIndicatorKey)
        if !UserDefaults.standard.contains(key: showCenterIndicatorKey) {
            showCenterIndicator = false
            UserDefaults.standard.set(false, forKey: showCenterIndicatorKey)
        }
        
        // 加载中央指示器大小
        centerIndicatorSize = UserDefaults.standard.double(forKey: centerIndicatorSizeKey)
        if !UserDefaults.standard.contains(key: centerIndicatorSizeKey) {
            centerIndicatorSize = 8
            UserDefaults.standard.set(8, forKey: centerIndicatorSizeKey)
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
            // 保存新的枚举值以便将来使用
            UserDefaults.standard.set(iconAppearAnimationType.rawValue, forKey: iconAppearAnimationTypeKey)
        }
        
        // 加载图标显示速度
        iconAppearSpeed = UserDefaults.standard.double(forKey: iconAppearSpeedKey)
        if !UserDefaults.standard.contains(key: iconAppearSpeedKey) {
            iconAppearSpeed = 0.04
            UserDefaults.standard.set(0.04, forKey: iconAppearSpeedKey)
        }
        
        // 加载圆环毛玻璃效果设置
        useBlurEffectForCircleRing = UserDefaults.standard.bool(forKey: useBlurEffectForCircleRingKey)
        
        // 加载圆环透明度设置
        circleRingOpacity = UserDefaults.standard.double(forKey: circleRingOpacityKey)
        if !UserDefaults.standard.contains(key: circleRingOpacityKey) {
            circleRingOpacity = 0.8
            UserDefaults.standard.set(0.8, forKey: circleRingOpacityKey)
        }
        
        // 加载应用名称显示设置
        showAppNameInCircleRing = UserDefaults.standard.bool(forKey: showAppNameInCircleRingKey)
        if !UserDefaults.standard.contains(key: showAppNameInCircleRingKey) {
            showAppNameInCircleRing = true
            UserDefaults.standard.set(true, forKey: showAppNameInCircleRingKey)
        }
        
        // 加载扇区高亮设置
        useSectorHighlight = UserDefaults.standard.bool(forKey: useSectorHighlightKey)
        if !UserDefaults.standard.contains(key: useSectorHighlightKey) {
            useSectorHighlight = true
            UserDefaults.standard.set(true, forKey: useSectorHighlightKey)
        }
        
        // 加载扇区高亮不透明度
        sectorHighlightOpacity = UserDefaults.standard.double(forKey: sectorHighlightOpacityKey)
        if !UserDefaults.standard.contains(key: sectorHighlightOpacityKey) {
            sectorHighlightOpacity = 1.0
            UserDefaults.standard.set(1.0, forKey: sectorHighlightOpacityKey)
        }
        
        // 加载扇区高亮颜色
        if let colorTypeString = UserDefaults.standard.string(forKey: sectorHighlightColorKey),
           let colorType = SectorHighlightColorType(rawValue: colorTypeString) {
            sectorHighlightColor = colorType
        } else {
            sectorHighlightColor = .blue
            UserDefaults.standard.set(SectorHighlightColorType.blue.rawValue, forKey: sectorHighlightColorKey)
        }
        
        // 加载扇区悬停音效设置
        useSectorHoverSound = UserDefaults.standard.bool(forKey: useSectorHoverSoundKey)
        if !UserDefaults.standard.contains(key: useSectorHoverSoundKey) {
            useSectorHoverSound = true
            UserDefaults.standard.set(true, forKey: useSectorHoverSoundKey)
        }
        
        // 加载扇区悬停音效类型
        if let soundTypeString = UserDefaults.standard.string(forKey: sectorHoverSoundTypeKey),
           let soundType = SectorHoverSoundType(rawValue: soundTypeString) {
            sectorHoverSoundType = soundType
        } else {
            sectorHoverSoundType = .frog
            UserDefaults.standard.set(SectorHoverSoundType.frog.rawValue, forKey: sectorHoverSoundTypeKey)
        }
        
        // 加载圆环应用列表
        if let appsData = UserDefaults.standard.array(forKey: circleRingAppsKey) as? [String] {
            circleRingApps = appsData
            print("[AppSettings] 加载了 \(circleRingApps.count) 个圆环应用")
        } else {
            print("[AppSettings] 未找到已保存的圆环应用")
            circleRingApps = []
        }
        
        // 加载圆环直径
        circleRingDiameter = UserDefaults.standard.double(forKey: circleRingDiameterKey)
        if !UserDefaults.standard.contains(key: circleRingDiameterKey) {
            circleRingDiameter = 280
            UserDefaults.standard.set(280, forKey: circleRingDiameterKey)
        }
        
        // 加载圆环内径
        circleRingInnerDiameter = UserDefaults.standard.double(forKey: circleRingInnerDiameterKey)
        if !UserDefaults.standard.contains(key: circleRingInnerDiameterKey) {
            circleRingInnerDiameter = 100
            UserDefaults.standard.set(100, forKey: circleRingInnerDiameterKey)
        }
        
        // 加载图标大小
        circleRingIconSize = UserDefaults.standard.double(forKey: circleRingIconSizeKey)
        if !UserDefaults.standard.contains(key: circleRingIconSizeKey) {
            circleRingIconSize = 40
            UserDefaults.standard.set(40, forKey: circleRingIconSizeKey)
        }
        
        // 加载图标圆角
        circleRingIconCornerRadius = UserDefaults.standard.double(forKey: circleRingIconCornerRadiusKey)
        if !UserDefaults.standard.contains(key: circleRingIconCornerRadiusKey) {
            circleRingIconCornerRadius = 8
            UserDefaults.standard.set(8, forKey: circleRingIconCornerRadiusKey)
        }
        
        // 加载扇区数量
        circleRingSectorCount = UserDefaults.standard.integer(forKey: circleRingSectorCountKey)
        if !UserDefaults.standard.contains(key: circleRingSectorCountKey) {
            circleRingSectorCount = 6
            UserDefaults.standard.set(6, forKey: circleRingSectorCountKey)
        }
        
        // 加载圆环内圆自定义图片设置
        showCustomImageInCircle = UserDefaults.standard.bool(forKey: showCustomImageInCircleKey)
        customCircleImagePath = UserDefaults.standard.string(forKey: customCircleImagePathKey) ?? ""
        
        customCircleImageScale = CGFloat(UserDefaults.standard.double(forKey: customCircleImageScaleKey))
        if !UserDefaults.standard.contains(key: customCircleImageScaleKey) {
            customCircleImageScale = 0.7
            UserDefaults.standard.set(0.7, forKey: customCircleImageScaleKey)
        }
        
        customCircleImageOpacity = CGFloat(UserDefaults.standard.double(forKey: customCircleImageOpacityKey))
        if !UserDefaults.standard.contains(key: customCircleImageOpacityKey) {
            customCircleImageOpacity = 0.8
            UserDefaults.standard.set(0.8, forKey: customCircleImageOpacityKey)
        }
        
        // 加载扇区震动设置
        useSectorHoverHaptic = UserDefaults.standard.bool(forKey: useSectorHoverHapticKey)
        if !UserDefaults.standard.contains(key: useSectorHoverHapticKey) {
            useSectorHoverHaptic = true
            UserDefaults.standard.set(true, forKey: useSectorHoverHapticKey)
        }
        
        // 加载震动强度设置
        if let strengthString = UserDefaults.standard.string(forKey: sectorHoverHapticStrengthKey),
           let strength = HapticFeedbackStrength(rawValue: strengthString) {
            sectorHoverHapticStrength = strength
        } else {
            sectorHoverHapticStrength = .medium
            UserDefaults.standard.set(HapticFeedbackStrength.medium.rawValue, forKey: sectorHoverHapticStrengthKey)
        }
        
        // 添加在AppSettings类中的属性列表中
        showRunningIndicator = UserDefaults.standard.bool(forKey: showRunningIndicatorKey)

        // 加载运行中应用标识颜色
        if let colorHexString = UserDefaults.standard.string(forKey: runningIndicatorColorKey) {
            runningIndicatorColor = Color(hex: colorHexString)
        } else {
            runningIndicatorColor = .blue
            UserDefaults.standard.set("#0000FF", forKey: runningIndicatorColorKey)
        }

        runningIndicatorSize = UserDefaults.standard.double(forKey: runningIndicatorSizeKey)
        if !UserDefaults.standard.contains(key: runningIndicatorSizeKey) {
            runningIndicatorSize = 6.0
            UserDefaults.standard.set(6.0, forKey: runningIndicatorSizeKey)
        }

        runningIndicatorPosition = ShortcutLabelPosition(rawValue: UserDefaults.standard.string(forKey: runningIndicatorPositionKey) ?? "bottom") ?? .bottom
        
        // 加载图标悬停背景启用设置
        useHoverBackground = UserDefaults.standard.bool(forKey: useHoverBackgroundKey)
        if !UserDefaults.standard.contains(key: useHoverBackgroundKey) {
            useHoverBackground = false
            UserDefaults.standard.set(false, forKey: useHoverBackgroundKey)
        }
        
        // 加载分组显示位置
        if let positionString = UserDefaults.standard.string(forKey: groupDisplayPositionKey),
           let position = GroupDisplayPosition(rawValue: positionString) {
            groupDisplayPosition = position
            print("[AppSettings] 成功设置分组显示位置为: \(position)")
        } else {
            groupDisplayPosition = .vertical  // 默认垂直显示
        }
        
        // 加载网站分组显示位置
        if let positionString = UserDefaults.standard.string(forKey: webGroupDisplayPositionKey),
           let position = GroupDisplayPosition(rawValue: positionString) {
            webGroupDisplayPosition = position
            print("[AppSettings] 成功设置网站分组显示位置为: \(position)")
        } else {
            webGroupDisplayPosition = .vertical  // 默认垂直显示
        }
        
        // 加载应用和网站区域显示顺序
        if let orderString = UserDefaults.standard.string(forKey: appWebsiteOrderKey),
           let order = AppWebsiteOrder(rawValue: orderString) {
            appWebsiteOrder = order
        } else {
            appWebsiteOrder = .appFirst  // 默认应用区域在前
        }
        
        // 加载应用区域占比
        appAreaRatio = UserDefaults.standard.double(forKey: appAreaRatioKey)
        if !UserDefaults.standard.contains(key: appAreaRatioKey) || appAreaRatio < 0.1 || appAreaRatio > 0.9 {
            appAreaRatio = 0.5  // 默认均分
            UserDefaults.standard.set(0.5, forKey: appAreaRatioKey)
        }
        
        // 加载布局方向
        if let directionString = UserDefaults.standard.string(forKey: layoutDirectionKey),
           let direction = LayoutDirection(rawValue: directionString) {
            layoutDirection = direction
        } else {
            layoutDirection = .vertical  // 默认上下布局
        }
        
        // 加载区域间隔大小
        areaSeparatorSize = UserDefaults.standard.double(forKey: areaSeparatorSizeKey)
        if !UserDefaults.standard.contains(key: areaSeparatorSizeKey) || areaSeparatorSize < 0 {
            areaSeparatorSize = 8.0  // 默认间隔为8
            UserDefaults.standard.set(8.0, forKey: areaSeparatorSizeKey)
        }
        
        // 在其他布尔类型设置的加载代码后添加
        clickAppToToggle = UserDefaults.standard.bool(forKey: clickAppToToggleKey)
        if !UserDefaults.standard.contains(key: clickAppToToggleKey) {
            clickAppToToggle = true
            UserDefaults.standard.set(true, forKey: clickAppToToggleKey)
        }
        
        clickCircleAppToToggle = UserDefaults.standard.bool(forKey: clickCircleAppToToggleKey)
        if !UserDefaults.standard.contains(key: clickCircleAppToToggleKey) {
            clickCircleAppToToggle = true
            UserDefaults.standard.set(true, forKey: clickCircleAppToToggleKey)
        }
        
        // 悬浮窗分组设置
        showGroupsInFloatingWindow = UserDefaults.standard.bool(forKey: "showGroupsInFloatingWindow")
        if !UserDefaults.standard.contains(key: "showGroupsInFloatingWindow") {
            showGroupsInFloatingWindow = true
            UserDefaults.standard.set(true, forKey: "showGroupsInFloatingWindow")
        }
        
        showGroupCountInFloatingWindow = UserDefaults.standard.bool(forKey: "showGroupCountInFloatingWindow")
        
        // 初始化完成
        print("[AppSettings] 设置加载完成")
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
        UserDefaults.standard.set(iconGridSpacing, forKey: iconGridSpacingKey)
        UserDefaults.standard.set(iconShadowRadius, forKey: iconShadowRadiusKey)
        UserDefaults.standard.set(useIconShadow, forKey: useIconShadowKey)
        
        // 保存图标悬停背景设置
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: NSColor(iconHoverBackgroundColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: iconHoverBackgroundColorKey)
        }
        UserDefaults.standard.set(iconHoverBackgroundPadding, forKey: iconHoverBackgroundPaddingKey)
        UserDefaults.standard.set(iconHoverBackgroundCornerRadius, forKey: iconHoverBackgroundCornerRadiusKey)
        
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
        
        // 保存悬浮窗工具栏显示设置
        UserDefaults.standard.set(showToolbar, forKey: showToolbarKey)
        
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
        UserDefaults.standard.set(circleRingAnimationSpeed, forKey: circleRingAnimationSpeedKey)
        UserDefaults.standard.set(iconAppearAnimationType.rawValue, forKey: iconAppearAnimationTypeKey)
        UserDefaults.standard.set(iconAppearSpeed, forKey: iconAppearSpeedKey)
        UserDefaults.standard.set(circleRingOpacity, forKey: circleRingOpacityKey)
        UserDefaults.standard.set(sectorHighlightColor.rawValue, forKey: sectorHighlightColorKey)
        UserDefaults.standard.set(showAppNameInCircleRing, forKey: showAppNameInCircleRingKey)
        UserDefaults.standard.set(showCustomImageInCircle, forKey: showCustomImageInCircleKey)
        UserDefaults.standard.set(customCircleImagePath, forKey: customCircleImagePathKey)
        UserDefaults.standard.set(customCircleImageScale, forKey: customCircleImageScaleKey)
        UserDefaults.standard.set(customCircleImageOpacity, forKey: customCircleImageOpacityKey)
        UserDefaults.standard.set(showOnMenuBarHover, forKey: showOnMenuBarHoverKey)
        UserDefaults.standard.set(useSectorHoverHaptic, forKey: useSectorHoverHapticKey)
        UserDefaults.standard.set(sectorHoverHapticStrength.rawValue, forKey: sectorHoverHapticStrengthKey)
        UserDefaults.standard.set(showRunningIndicator, forKey: showRunningIndicatorKey)
        UserDefaults.standard.set(runningIndicatorColor.toHexString(), forKey: runningIndicatorColorKey)
        UserDefaults.standard.set(runningIndicatorSize, forKey: runningIndicatorSizeKey)
        UserDefaults.standard.set(runningIndicatorPosition.rawValue, forKey: runningIndicatorPositionKey)
        UserDefaults.standard.set(useHoverBackground, forKey: useHoverBackgroundKey)
        UserDefaults.standard.set(groupDisplayPosition.rawValue, forKey: groupDisplayPositionKey)
        UserDefaults.standard.set(webGroupDisplayPosition.rawValue, forKey: webGroupDisplayPositionKey)
        UserDefaults.standard.set(appWebsiteOrder.rawValue, forKey: appWebsiteOrderKey)
        UserDefaults.standard.set(appAreaRatio, forKey: appAreaRatioKey)
        UserDefaults.standard.set(layoutDirection.rawValue, forKey: layoutDirectionKey)
        UserDefaults.standard.set(areaSeparatorSize, forKey: areaSeparatorSizeKey)
        
        // 在其他布尔类型设置的保存代码后添加
        UserDefaults.standard.set(clickAppToToggle, forKey: clickAppToToggleKey)
        UserDefaults.standard.set(clickCircleAppToToggle, forKey: clickCircleAppToToggleKey)
        
        // 悬浮窗分组设置
        UserDefaults.standard.set(showGroupsInFloatingWindow, forKey: "showGroupsInFloatingWindow")
        UserDefaults.standard.set(showGroupCountInFloatingWindow, forKey: "showGroupCountInFloatingWindow")
        
        // 发布设置更改通知
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        
        print("[AppSettings] 设置保存完成")
    }
    
    func incrementUsageCount(type: UsageType = .unknown) {
        totalUsageCount += 1
        UserDefaults.standard.set(totalUsageCount, forKey: usageCountKey)
        
        // 同时记录每日使用量
        UsageStatsManager.shared.recordUsage(type: type)
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
        let websites = WebsiteManager.shared.getWebsites(mode: .all).filter { $0.shortcutKey != nil }
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
        let websites = WebsiteManager.shared.getWebsites(mode: .all).filter { $0.shortcutKey != nil }
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
    
    // 添加一个重置丢失设置到默认值的方法
    func ensureDefaultSettings() {
        // 如果检测到关键设置丢失，则重置为默认值
        print("[AppSettings] 检查并确保默认设置存在")
        
        // 检查场景是否丢失
        if scenes.isEmpty {
            print("[AppSettings] 警告：场景数据丢失，重新创建默认场景")
            let defaultScene = Scene(name: "默认场景", shortcuts: shortcuts)
            scenes = [defaultScene]
            currentScene = defaultScene
            saveSettings()
        }
        
        // 检查悬浮窗尺寸设置
        if floatingWindowWidth <= 0 {
            print("[AppSettings] 警告：悬浮窗宽度数据无效，重置为默认值")
            floatingWindowWidth = 600
            UserDefaults.standard.set(600, forKey: floatingWindowWidthKey)
        }
        
        if floatingWindowHeight <= 0 {
            print("[AppSettings] 警告：悬浮窗高度数据无效，重置为默认值")
            floatingWindowHeight = 400
            UserDefaults.standard.set(400, forKey: floatingWindowHeightKey)
        }
        
        // 检查图标尺寸设置
        if iconSize <= 0 {
            print("[AppSettings] 警告：图标尺寸数据无效，重置为默认值")
            iconSize = 48
            UserDefaults.standard.set(48, forKey: iconSizeKey)
        }
        
        if appIconSize <= 0 {
            print("[AppSettings] 警告：应用图标尺寸数据无效，重置为默认值")
            appIconSize = 48
            UserDefaults.standard.set(48, forKey: appIconSizeKey)
        }
        
        if webIconSize <= 0 {
            print("[AppSettings] 警告：网站图标尺寸数据无效，重置为默认值")
            webIconSize = 48
            UserDefaults.standard.set(48, forKey: webIconSizeKey)
        }
        
        // 检查圆环设置
        if circleRingDiameter <= 0 {
            print("[AppSettings] 重置无效的圆环直径设置")
            circleRingDiameter = 280
            UserDefaults.standard.set(280, forKey: circleRingDiameterKey)
        }
        
        if circleRingIconSize <= 0 {
            print("[AppSettings] 警告：圆环图标尺寸数据无效，重置为默认值")
            circleRingIconSize = 40
            UserDefaults.standard.set(40, forKey: circleRingIconSizeKey)
        }
        
        // 确保悬浮窗运行中应用标识设置存在
        if UserDefaults.standard.object(forKey: showRunningIndicatorKey) == nil {
            UserDefaults.standard.set(true, forKey: showRunningIndicatorKey)
            showRunningIndicator = true
        }
        
        if UserDefaults.standard.object(forKey: runningIndicatorSizeKey) == nil {
            UserDefaults.standard.set(6.0, forKey: runningIndicatorSizeKey)
            runningIndicatorSize = 6.0
        }
        
        if UserDefaults.standard.object(forKey: runningIndicatorPositionKey) == nil {
            UserDefaults.standard.set("bottom", forKey: runningIndicatorPositionKey)
            runningIndicatorPosition = .bottom
        }
        
        if UserDefaults.standard.object(forKey: runningIndicatorColorKey) == nil {
            UserDefaults.standard.set("#0000FF", forKey: runningIndicatorColorKey)
            runningIndicatorColor = .blue
        }
        
        // 将更改保存到磁盘
        saveSettings()
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

// 添加Color扩展，提供十六进制字符串转换功能
extension Color {
    func toHexString() -> String {
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            return "#000000"
        }
        
        let red = Int(round(rgbColor.redComponent * 255.0))
        let green = Int(round(rgbColor.greenComponent * 255.0))
        let blue = Int(round(rgbColor.blueComponent * 255.0))
        let alpha = Int(round(rgbColor.alphaComponent * 255.0))
        
        if alpha == 255 {
            return String(format: "#%02X%02X%02X", red, green, blue)
        } else {
            return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
        }
    }
    
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
} 
