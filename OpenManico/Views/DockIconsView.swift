import SwiftUI
import AppKit

/**
 * Dock 栏程序图标视图
 */
struct DockIconsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var websiteManager = WebsiteManager.shared
    @StateObject private var iconManager = WebIconManager.shared
    @State private var installedApps: [AppInfo] = []
    @State private var runningApps: [AppInfo] = []
    @State private var appDisplayMode: AppDisplayMode = .all
    @State private var websiteDisplayMode: WebsiteDisplayMode = .shortcutOnly
    @State private var selectedAppGroup: UUID?
    @State private var selectedWebGroup: UUID?
    @State private var webIcons: [UUID: NSImage] = [:]
    @State private var optionKeyMonitor: Any?
    
    var body: some View {
        VStack(spacing: 0) {
            if settings.showAppsInFloatingWindow {
                TopToolbarView(
                    appDisplayMode: $appDisplayMode,
                    selectedAppGroup: $selectedAppGroup,
                    installedApps: installedApps,
                    runningApps: runningApps,
                    shortcuts: settings.shortcuts
                )
                
                DockAppListView(
                    appDisplayMode: appDisplayMode,
                    installedApps: installedApps,
                    runningApps: runningApps,
                    shortcuts: settings.shortcuts,
                    selectedAppGroup: selectedAppGroup
                )
            }
            
            if settings.showWebShortcutsInFloatingWindow {
                if settings.showDivider && settings.showAppsInFloatingWindow {
                    Divider()
                        .opacity(settings.dividerOpacity)
                }
                
                WebShortcutToolbarView(
                    websiteDisplayMode: $websiteDisplayMode,
                    selectedWebGroup: $selectedWebGroup
                )
                
                WebShortcutListView(
                    websiteDisplayMode: websiteDisplayMode,
                    selectedWebGroup: selectedWebGroup,
                    webIcons: webIcons,
                    onWebIconsUpdate: { newIcons in
                        webIcons = newIcons
                    }
                )
            }
        }
        .onAppear {
            appDisplayMode = settings.appDisplayMode
            websiteDisplayMode = settings.websiteDisplayMode
            scanApps()
            startRunningAppsMonitor()
            setupHotKeys()
            
            // 设置 Option 键监听
            optionKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { event in
                // 只有单独按 Option 键时才触发悬浮窗
                let isOptionOnlyPressed = event.modifierFlags.intersection([.option, .command]) == .option
                if isOptionOnlyPressed {
                    DockIconsWindowController.shared.showWindow()
                } else if !event.modifierFlags.contains(.option) || event.modifierFlags.contains(.command) {
                    DockIconsWindowController.shared.hideWindow()
                }
            }
        }
        .onDisappear {
            // 移除 Option 键监听
            if let monitor = optionKeyMonitor {
                NSEvent.removeMonitor(monitor)
                optionKeyMonitor = nil
            }
        }
        .onChange(of: appDisplayMode) { newMode in
            settings.appDisplayMode = newMode
        }
        .onChange(of: websiteDisplayMode) { newMode in
            settings.websiteDisplayMode = newMode
        }
        .onChange(of: settings.shortcuts) { _ in
            scanApps()
            setupHotKeys()
        }
        .onChange(of: websiteManager.websites) { _ in
            setupHotKeys()
        }
    }
    
    private func setupHotKeys() {
        // 更新所有快捷键
        HotKeyManager.shared.updateShortcuts()
    }
    
    private func startRunningAppsMonitor() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { _ in
            updateRunningApps()
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { _ in
            updateRunningApps()
        }
        
        updateRunningApps()
    }
    
    private func updateRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let bundleId = app.bundleIdentifier,
                      let url = app.bundleURL,
                      let name = app.localizedName else { return nil }
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                return AppInfo(bundleId: bundleId, name: name, icon: icon, url: url)
            }
    }
    
    private func scanApps() {
        Task {
            // 扫描所有可能的应用目录
            let appURLs = getAppsInDirectory(at: URL(fileURLWithPath: "/Applications")) +
                         getAppsInDirectory(at: URL(fileURLWithPath: "/System/Applications")) +
                         getAppsInDirectory(at: FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first ?? URL(fileURLWithPath: "")) +
                         getAppsInDirectory(at: URL(fileURLWithPath: NSString(string: "~/Applications").expandingTildeInPath))
            
            var uniqueApps: [String: AppInfo] = [:]  // 使用字典来去重
            
            for url in appURLs {
                guard let bundle = Bundle(url: url),
                      let bundleId = bundle.bundleIdentifier else {
                    continue
                }
                
                // 如果已经存在相同 bundleId 的应用，跳过
                if uniqueApps[bundleId] != nil {
                    continue
                }
                
                let name = bundle.infoDictionary?["CFBundleName"] as? String ??
                          bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                          url.deletingPathExtension().lastPathComponent
                
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                uniqueApps[bundleId] = AppInfo(bundleId: bundleId, name: name, icon: icon, url: url)
            }
            
            DispatchQueue.main.async {
                installedApps = Array(uniqueApps.values).sorted { $0.name < $1.name }
            }
        }
    }
    
    private func getAppsInDirectory(at url: URL) -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isApplicationKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        return contents.filter { url in
            guard url.pathExtension == "app" else { return false }
            guard let isApp = try? url.resourceValues(forKeys: [.isApplicationKey]).isApplication else { return false }
            return isApp
        }
    }
}

// MARK: - 顶部工具栏视图
private struct TopToolbarView: View {
    @Binding var appDisplayMode: AppDisplayMode
    @Binding var selectedAppGroup: UUID?
    @Environment(\.colorScheme) private var systemColorScheme
    let installedApps: [AppInfo]
    let runningApps: [AppInfo]
    let shortcuts: [AppShortcut]
    
    private var effectiveColorScheme: ColorScheme {
        switch AppSettings.shared.floatingWindowTheme {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    private var textColor: Color {
        effectiveColorScheme == .dark ? .white : .black.opacity(0.85)
    }
    
    private var buttonBackgroundColor: Color {
        Color.blue
    }
    
    private var inactiveButtonBackgroundColor: Color {
        effectiveColorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15)
    }
    
    private func getTextColor(isSelected: Bool) -> Color {
        isSelected ? .white : textColor
    }
    
    private func getGroupAppCount(group: AppGroup) -> Int {
        let groupBundleIds = Set(group.apps.map { $0.bundleId })
        switch appDisplayMode {
        case .all:
            return installedApps.filter { groupBundleIds.contains($0.bundleId) }.count
        case .runningOnly:
            return runningApps.filter { groupBundleIds.contains($0.bundleId) }.count
        case .shortcutOnly:
            let shortcutApps = shortcuts
                .filter { groupBundleIds.contains($0.bundleIdentifier) }
                .filter { shortcut in
                    installedApps.contains { $0.bundleId == shortcut.bundleIdentifier }
                }
            return shortcutApps.count
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 应用显示模式下拉菜单
                Menu {
                    ForEach([AppDisplayMode.all, AppDisplayMode.shortcutOnly, AppDisplayMode.runningOnly], id: \.self) { mode in
                        Button(action: {
                            appDisplayMode = mode
                        }) {
                            HStack {
                                Text(mode.description)
                                if appDisplayMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(appDisplayMode.description)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(buttonBackgroundColor)
                    )
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .menuIndicator(.hidden)
                .fixedSize()
                
                Divider()
                    .frame(height: 24)
                    .background(Color.primary.opacity(0.3))
                
                // 全部应用按钮
                Button(action: {
                    selectedAppGroup = nil
                }) {
                    let totalCount = switch appDisplayMode {
                        case .all: installedApps.count
                        case .runningOnly: runningApps.count
                        case .shortcutOnly: shortcuts.count
                    }
                    Text("全部 (\(totalCount))")
                        .foregroundColor(getTextColor(isSelected: selectedAppGroup == nil))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedAppGroup == nil ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                        )
                }
                .buttonStyle(.plain)
                
                // 分组按钮
                ForEach(AppGroupManager.shared.groups) { group in
                    Button(action: {
                        selectedAppGroup = group.id
                    }) {
                        Text("\(group.name) (\(getGroupAppCount(group: group)))")
                            .foregroundColor(getTextColor(isSelected: selectedAppGroup == group.id))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedAppGroup == group.id ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }
}

// MARK: - 应用列表视图
private struct DockAppListView: View {
    @StateObject private var settings = AppSettings.shared
    let appDisplayMode: AppDisplayMode
    let installedApps: [AppInfo]
    let runningApps: [AppInfo]
    let shortcuts: [AppShortcut]
    let selectedAppGroup: UUID?
    
    var filteredApps: [AppInfo] {
        // 如果没有选择分组，显示所有应用
        if selectedAppGroup == nil {
            switch appDisplayMode {
            case .all:
                return installedApps
            case .runningOnly:
                return runningApps
            case .shortcutOnly:
                return shortcuts.compactMap { shortcut in
                    installedApps.first { $0.bundleId == shortcut.bundleIdentifier }
                }
            }
        }
        
        // 如果选择了分组，只显示分组内的应用
        let groupApps = AppGroupManager.shared.groups.first(where: { $0.id == selectedAppGroup })?.apps ?? []
        let groupBundleIds = Set(groupApps.map { $0.bundleId })
        
        switch appDisplayMode {
        case .all:
            return installedApps.filter { groupBundleIds.contains($0.bundleId) }
        case .runningOnly:
            return runningApps.filter { groupBundleIds.contains($0.bundleId) }
        case .shortcutOnly:
            return shortcuts
                .filter { groupBundleIds.contains($0.bundleIdentifier) }
                .compactMap { shortcut in
                    installedApps.first { $0.bundleId == shortcut.bundleIdentifier }
                }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: max(settings.appIconSize, 80)))
            ], spacing: 16) {
                ForEach(filteredApps, id: \.bundleId) { app in
                    AppIconView(app: app)
                }
            }
            .padding()
        }
    }
}

// MARK: - 网站快捷键列表视图
private struct WebShortcutListView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var websiteManager = WebsiteManager.shared
    @StateObject private var iconManager = WebIconManager.shared
    let websiteDisplayMode: WebsiteDisplayMode
    let selectedWebGroup: UUID?
    let webIcons: [UUID: NSImage]
    let onWebIconsUpdate: ([UUID: NSImage]) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: max(settings.webIconSize, 80)))
            ], spacing: 16) {
                let websites = websiteManager.getWebsites(mode: websiteDisplayMode, groupId: selectedWebGroup)
                ForEach(websites) { website in
                    WebsiteIconView(website: website)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - 网站图标视图
private struct WebsiteIconView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var iconManager = WebIconManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    let website: Website
    
    private var effectiveColorScheme: ColorScheme {
        switch settings.floatingWindowTheme {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    private var textColor: Color {
        effectiveColorScheme == .dark ? .white : .black.opacity(0.85)
    }
    
    var body: some View {
        IconView(
            icon: iconManager.icon(for: website.id) ?? NSImage(systemSymbolName: "globe", accessibilityDescription: nil)!,
            size: settings.webIconSize,
            label: {
                VStack(spacing: 2) {
                    if settings.showWebsiteName {
                        Text(website.name)
                            .font(.system(size: settings.websiteNameFontSize))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            },
            onTap: {
                if let url = URL(string: website.url) {
                    NSWorkspace.shared.open(url)
                }
            },
            shortcutKey: website.shortcutKey,
            isWebsite: true
        )
        .onAppear {
            Task {
                await website.fetchIcon { icon in
                    if let icon = icon {
                        Task {
                            await iconManager.setIcon(icon, for: website.id)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 网站工具栏视图
private struct WebShortcutToolbarView: View {
    @Binding var websiteDisplayMode: WebsiteDisplayMode
    @Binding var selectedWebGroup: UUID?
    @StateObject private var websiteManager = WebsiteManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    
    private var effectiveColorScheme: ColorScheme {
        switch AppSettings.shared.floatingWindowTheme {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    private var textColor: Color {
        effectiveColorScheme == .dark ? .white : .black.opacity(0.85)
    }
    
    private var buttonBackgroundColor: Color {
        Color.blue
    }
    
    private var inactiveButtonBackgroundColor: Color {
        effectiveColorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15)
    }
    
    private func getTextColor(isSelected: Bool) -> Color {
        isSelected ? .white : textColor
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 网站显示模式下拉菜单
                Menu {
                    ForEach([WebsiteDisplayMode.shortcutOnly, WebsiteDisplayMode.all], id: \.self) { mode in
                        Button(action: {
                            websiteDisplayMode = mode
                        }) {
                            HStack {
                                Text(mode.description)
                                if websiteDisplayMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(websiteDisplayMode.description)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(buttonBackgroundColor)
                    )
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .menuIndicator(.hidden)
                .fixedSize()
                
                Divider()
                    .frame(height: 24)
                    .background(Color.primary.opacity(0.3))
                
                // 全部网站按钮
                Button(action: {
                    selectedWebGroup = nil
                }) {
                    Text("全部")
                        .foregroundColor(getTextColor(isSelected: selectedWebGroup == nil))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedWebGroup == nil ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                        )
                }
                .buttonStyle(.plain)
                
                // 分组按钮
                ForEach(websiteManager.groups) { group in
                    Button(action: {
                        selectedWebGroup = group.id
                    }) {
                        Text(group.name)
                            .foregroundColor(getTextColor(isSelected: selectedWebGroup == group.id))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedWebGroup == group.id ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
    }
}

struct IconView<Label: View>: View {
    @StateObject private var settings = AppSettings.shared
    let icon: NSImage
    let size: CGFloat
    let label: Label
    let onHover: ((Bool) -> Void)?
    let onTap: (() -> Void)?
    let shortcutKey: String?
    let isWebsite: Bool
    @State private var isHovering = false
    
    init(
        icon: NSImage,
        size: CGFloat,
        @ViewBuilder label: () -> Label,
        onHover: ((Bool) -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        shortcutKey: String? = nil,
        isWebsite: Bool = false
    ) {
        self.icon = icon
        self.size = size
        self.label = label()
        self.onHover = onHover
        self.onTap = onTap
        self.shortcutKey = shortcutKey
        self.isWebsite = isWebsite
    }
    
    var body: some View {
        VStack(spacing: settings.iconSpacing) {
            ZStack(alignment: .center) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: size, height: size)
                    .cornerRadius(settings.iconCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: settings.iconCornerRadius)
                            .stroke(settings.iconBorderColor, lineWidth: isHovering ? settings.iconBorderWidth : 0)
                    )
                    .shadow(radius: settings.useIconShadow ? settings.iconShadowRadius : 0)
                    .scaleEffect(settings.useHoverAnimation && isHovering ? settings.hoverScale : 1.0)
                    .animation(.easeInOut(duration: settings.hoverAnimationDuration), value: isHovering)
                
                if let key = shortcutKey {
                    if isWebsite && settings.showWebShortcutLabel {
                        let labelOffset = getLabelOffset(position: settings.webShortcutLabelPosition)
                        HStack(spacing: 2) {
                            Image(systemName: "command")
                                .font(.system(size: settings.webShortcutLabelFontSize, weight: .medium))
                            Text(key)
                                .font(.system(size: settings.webShortcutLabelFontSize, weight: .medium))
                        }
                        .foregroundColor(settings.webShortcutLabelTextColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(settings.webShortcutLabelBackgroundColor)
                        )
                        .offset(x: labelOffset.x + settings.webShortcutLabelOffsetX,
                               y: labelOffset.y + settings.webShortcutLabelOffsetY)
                    } else if !isWebsite && settings.showAppShortcutLabel {
                        let labelOffset = getLabelOffset(position: settings.appShortcutLabelPosition)
                        Text(key)
                            .font(.system(size: settings.appShortcutLabelFontSize, weight: .medium))
                            .foregroundColor(settings.appShortcutLabelTextColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(settings.appShortcutLabelBackgroundColor)
                            )
                            .offset(x: labelOffset.x + settings.appShortcutLabelOffsetX,
                                   y: labelOffset.y + settings.appShortcutLabelOffsetY)
                    }
                }
            }
            .onTapGesture {
                onTap?()
            }
            
            label
        }
        .onHover { hovering in
            isHovering = hovering
            onHover?(hovering)
        }
    }
    
    private func getLabelOffset(position: ShortcutLabelPosition) -> (x: CGFloat, y: CGFloat) {
        let padding: CGFloat = 4
        switch position {
        case .top:
            return (x: 0, y: -size/2 - padding)
        case .bottom:
            return (x: 0, y: size/2 + padding)
        case .left:
            return (x: -size/2 - padding, y: 0)
        case .right:
            return (x: size/2 + padding, y: 0)
        }
    }
}

struct AppIconView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var systemColorScheme
    let app: AppInfo
    
    private var effectiveColorScheme: ColorScheme {
        switch settings.floatingWindowTheme {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    private var textColor: Color {
        effectiveColorScheme == .dark ? .white : .black.opacity(0.85)
    }
    
    var body: some View {
        IconView(
            icon: app.icon,
            size: AppSettings.shared.appIconSize,
            label: {
                if settings.showAppName {
                    Text(app.name)
                        .font(.system(size: settings.appNameFontSize))
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .frame(width: 60)
                }
            },
            onTap: {
                if let url = app.url {
                    NSWorkspace.shared.open(url)
                }
            },
            shortcutKey: settings.shortcuts.first(where: { $0.bundleIdentifier == app.bundleId })?.key,
            isWebsite: false
        )
    }
}

/**
 * Dock 栏程序图标窗口控制器
 */
class DockIconsWindowController {
    static let shared = DockIconsWindowController()
    private var window: NSWindow?
    @objc private var isVisible = false
    private var observer: NSObjectProtocol?
    
    private init() {
        // 监听窗口大小设置变化
        observer = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.isVisible == true {
                self?.updateWindow()
            }
        }
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // 获取窗口背景颜色
    private func getWindowBackgroundColor() -> NSColor {
        let settings = AppSettings.shared
        let appearance = NSAppearance.currentDrawing()
        let isDarkMode = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        
        let effectiveIsDarkMode: Bool
        switch settings.floatingWindowTheme {
        case .system:
            effectiveIsDarkMode = isDarkMode
        case .light:
            effectiveIsDarkMode = false
        case .dark:
            effectiveIsDarkMode = true
        }
        
        return effectiveIsDarkMode ? .black : .white
    }
    
    // 更新窗口
    func updateWindow() {
        guard let window = window else { return }
        
        let settings = AppSettings.shared
        
        // 更新 NSVisualEffectView 的圆角
        if let visualEffectView = window.contentView as? NSVisualEffectView {
            visualEffectView.layer?.cornerRadius = settings.floatingWindowCornerRadius
            visualEffectView.layer?.masksToBounds = true
            
            // 根据主题设置更新外观
            switch settings.floatingWindowTheme {
            case .system:
                visualEffectView.appearance = nil
            case .light:
                visualEffectView.appearance = NSAppearance(named: .aqua)
            case .dark:
                visualEffectView.appearance = NSAppearance(named: .darkAqua)
            }
            
            // 根据是否使用毛玻璃效果来设置
            if settings.useBlurEffect {
                visualEffectView.state = .active
                visualEffectView.material = .hudWindow
                window.backgroundColor = .clear
                visualEffectView.alphaValue = 1.0
            } else {
                visualEffectView.state = .inactive
                visualEffectView.material = .windowBackground
                window.backgroundColor = getWindowBackgroundColor()
                visualEffectView.alphaValue = settings.floatingWindowOpacity
            }
        }
        
        // 设置窗口属性
        window.isOpaque = false
        window.hasShadow = false
        
        // 设置窗口圆角
        if let windowBackgroundView = window.contentView?.superview {
            windowBackgroundView.wantsLayer = true
            windowBackgroundView.layer?.cornerRadius = settings.floatingWindowCornerRadius
            windowBackgroundView.layer?.masksToBounds = true
        }
        
        window.setContentSize(NSSize(width: settings.floatingWindowWidth, height: settings.floatingWindowHeight))
        updateWindowPosition(window)
    }
    
    private func updateWindowPosition(_ window: NSWindow) {
        let settings = AppSettings.shared
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            
            var x: CGFloat = 0
            var y: CGFloat = 0
            
            switch settings.windowPosition {
            case .topLeft:
                x = screenFrame.minX
                y = screenFrame.maxY - windowFrame.height
            case .topCenter:
                x = screenFrame.midX - windowFrame.width / 2
                y = screenFrame.maxY - windowFrame.height
            case .topRight:
                x = screenFrame.maxX - windowFrame.width
                y = screenFrame.maxY - windowFrame.height
            case .centerLeft:
                x = screenFrame.minX
                y = screenFrame.midY - windowFrame.height / 2
            case .center:
                x = screenFrame.midX - windowFrame.width / 2
                y = screenFrame.midY - windowFrame.height / 2
            case .centerRight:
                x = screenFrame.maxX - windowFrame.width
                y = screenFrame.midY - windowFrame.height / 2
            case .bottomLeft:
                x = screenFrame.minX
                y = screenFrame.minY
            case .bottomCenter:
                x = screenFrame.midX - windowFrame.width / 2
                y = screenFrame.minY
            case .bottomRight:
                x = screenFrame.maxX - windowFrame.width
                y = screenFrame.minY
            case .custom:
                if settings.floatingWindowX >= 0 && settings.floatingWindowY >= 0 {
                    x = settings.floatingWindowX
                    y = settings.floatingWindowY
                } else {
                    x = screenFrame.midX - windowFrame.width / 2
                    y = screenFrame.midY - windowFrame.height / 2
                }
            }
            
            // 确保窗口不会超出屏幕边界
            x = max(screenFrame.minX, min(x, screenFrame.maxX - windowFrame.width))
            y = max(screenFrame.minY, min(y, screenFrame.maxY - windowFrame.height))
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
            
            // 如果是自定义位置，保存当前位置
            if settings.windowPosition == .custom {
                settings.floatingWindowX = x
                settings.floatingWindowY = y
            }
        }
    }
    
    // 显示窗口
    func showWindow() {
        if window == nil {
            let view = DockIconsView()
            let hostingView = NSHostingView(rootView: view)
            
            let settings = AppSettings.shared
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: settings.floatingWindowWidth, height: settings.floatingWindowHeight),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            // 创建并配置 NSVisualEffectView
            let visualEffectView = NSVisualEffectView()
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.material = settings.useBlurEffect ? .hudWindow : .windowBackground
            visualEffectView.state = settings.useBlurEffect ? .active : .inactive
            visualEffectView.wantsLayer = true
            visualEffectView.layer?.cornerRadius = settings.floatingWindowCornerRadius
            visualEffectView.layer?.masksToBounds = true
            
            // 设置视图层级
            window.contentView = visualEffectView
            visualEffectView.addSubview(hostingView)
            hostingView.frame = visualEffectView.bounds
            hostingView.autoresizingMask = [.width, .height]
            
            // 设置窗口属性
            window.isOpaque = false
            window.backgroundColor = settings.useBlurEffect ? .clear : getWindowBackgroundColor()
            window.level = .floating
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            window.isMovableByWindowBackground = true
            
            // 设置初始透明度
            if !settings.useBlurEffect {
                visualEffectView.alphaValue = settings.floatingWindowOpacity
            }
            
            // 设置窗口圆角
            if let windowBackgroundView = window.contentView?.superview {
                windowBackgroundView.wantsLayer = true
                windowBackgroundView.layer?.cornerRadius = settings.floatingWindowCornerRadius
                windowBackgroundView.layer?.masksToBounds = true
            }
            
            self.window = window
        }
        
        updateWindow()
        window?.orderFront(nil)
        isVisible = true
    }
    
    // 隐藏窗口
    func hideWindow() {
        window?.orderOut(nil)
        isVisible = false
    }
    
    func toggleWindow() {
        if isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    // 设置窗口层级
    func setWindowLevel(_ level: NSWindow.Level) {
        window?.level = level
    }
    
    // 恢复悬浮窗层级
    func restoreWindowLevel() {
        window?.level = .floating
    }
} 
