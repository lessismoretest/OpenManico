import SwiftUI
import AppKit

/**
 * Dock 栏程序图标视图
 */
struct DockIconsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var hotKeyManager = HotKeyManager.shared
    @StateObject private var websiteManager = WebsiteManager.shared
    @State private var webIcons: [UUID: NSImage] = [:]
    @State private var installedApps: [AppInfo] = []
    @State private var selectedAppGroup: UUID? = nil
    @State private var selectedWebGroup: UUID? = nil
    @State private var isScanning = false
    
    var body: some View {
        VStack(spacing: 0) {
            if settings.showAppsInFloatingWindow {
                TopToolbarView(
                    appDisplayMode: $settings.appDisplayMode,
                    selectedAppGroup: $selectedAppGroup,
                    installedApps: installedApps,
                    runningApps: runningApps,
                    shortcuts: settings.shortcuts
                )
            }
            
            // 应用图标列表
            if settings.showAppsInFloatingWindow {
                DockAppListView(
                    appDisplayMode: settings.appDisplayMode,
                    installedApps: installedApps,
                    runningApps: runningApps,
                    shortcuts: settings.shortcuts,
                    selectedAppGroup: selectedAppGroup
                )
            }
            
            // 网站快捷键图标
            if settings.showWebShortcutsInFloatingWindow {
                if settings.showDivider {
                    Divider()
                        .background(Color.white.opacity(settings.dividerOpacity))
                }
                
                WebShortcutToolbarView(
                    websiteDisplayMode: $settings.websiteDisplayMode,
                    selectedWebGroup: $selectedWebGroup
                )
                
                WebShortcutListView(
                    websiteDisplayMode: settings.websiteDisplayMode,
                    selectedWebGroup: selectedWebGroup,
                    webIcons: webIcons,
                    onWebIconsUpdate: { newIcons in
                        webIcons = newIcons
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .background {
            if settings.useBlurEffect {
                RoundedRectangle(cornerRadius: settings.floatingWindowCornerRadius)
                    .fill(.ultraThinMaterial)
                    .blur(radius: settings.blurRadius)
            } else {
                RoundedRectangle(cornerRadius: settings.floatingWindowCornerRadius)
                    .fill(Color.black.opacity(settings.floatingWindowOpacity))
            }
        }
        .onAppear {
            let startTime = Date()
            print("[DockIconsView] ⏱️ 开始加载视图: \(startTime)")
            
            // 预加载所有网站图标
            if settings.showWebShortcutsInFloatingWindow {
                print("[DockIconsView] 🌐 开始加载网站图标")
                print("[DockIconsView] 📊 当前网站总数: \(websiteManager.websites.count)")
                print("[DockIconsView] 🗂 已缓存图标数: \(WebIconManager.shared.getCachedIconCount())")
                
                Task {
                    let iconLoadStart = Date()
                    await WebIconManager.shared.preloadIcons(for: websiteManager.websites)
                    let iconLoadEnd = Date()
                    let iconLoadTime = iconLoadEnd.timeIntervalSince(iconLoadStart)
                    print("[DockIconsView] ⏱️ 网站图标加载耗时: \(String(format: "%.2f", iconLoadTime))秒")
                }
            }
            
            if settings.appDisplayMode == .all {
                print("[DockIconsView] 📱 开始扫描已安装应用")
                scanInstalledApps()
            }
            
            let endTime = Date()
            let totalTime = endTime.timeIntervalSince(startTime)
            print("[DockIconsView] ⏱️ 视图加载完成，总耗时: \(String(format: "%.2f", totalTime))秒")
        }
        .onChange(of: settings.appDisplayMode) { newMode in
            print("显示模式改变: \(newMode)")
            if newMode == .all {
                scanInstalledApps()
            }
        }
    }
    
    private var runningApps: [AppInfo] {
        let workspace = NSWorkspace.shared
        return workspace.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let bundleId = app.bundleIdentifier,
                      let name = app.localizedName,
                      let icon = app.icon else {
                    return nil
                }
                return AppInfo(bundleId: bundleId, name: name, icon: icon, url: app.bundleURL)
            }
            .sorted { $0.name < $1.name }
    }
    
    private func scanInstalledApps() {
        print("开始扫描已安装应用...")
        DispatchQueue.global(qos: .userInitiated).async {
            // 扫描应用程序文件夹
            let systemApps = getAppsInDirectory(at: URL(fileURLWithPath: "/Applications"))
            let userApps = getAppsInDirectory(at: URL(fileURLWithPath: NSString(string: "~/Applications").expandingTildeInPath))
            
            print("找到系统应用: \(systemApps.count)个")
            print("找到用户应用: \(userApps.count)个")
            
            let appURLs = systemApps + userApps
            
            // 转换为 AppInfo 对象
            let apps = appURLs.compactMap { url -> AppInfo? in
                guard let bundle = Bundle(url: url),
                      let bundleId = bundle.bundleIdentifier,
                      let name = bundle.infoDictionary?["CFBundleName"] as? String ?? url.deletingPathExtension().lastPathComponent as String? else {
                    print("无法读取应用信息: \(url.path)")
                    return nil
                }
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                return AppInfo(bundleId: bundleId, name: name, icon: icon, url: url)
            }
            
            DispatchQueue.main.async {
                installedApps = apps.sorted { $0.name < $1.name }
                print("应用扫描完成，共找到 \(installedApps.count) 个有效应用")
            }
        }
    }
    
    private func getAppsInDirectory(at url: URL) -> [URL] {
        print("扫描目录: \(url.path)")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isApplicationKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("无法读取目录: \(url.path)")
            return []
        }
        
        let apps = contents.filter { url in
            guard url.pathExtension == "app" else { return false }
            guard let isApp = try? url.resourceValues(forKeys: [.isApplicationKey]).isApplication else { return false }
            return isApp
        }
        
        print("在 \(url.path) 中找到 \(apps.count) 个应用")
        return apps
    }
}

// MARK: - 顶部工具栏视图
private struct TopToolbarView: View {
    @Binding var appDisplayMode: AppDisplayMode
    @Binding var selectedAppGroup: UUID?
    let installedApps: [AppInfo]
    let runningApps: [AppInfo]
    let shortcuts: [AppShortcut]
    
    private func getGroupAppCount(group: AppGroup) -> Int {
        let groupApps = group.apps
        switch appDisplayMode {
        case .all:
            return installedApps.filter { app in
                groupApps.contains(where: { $0.bundleId == app.bundleId })
            }.count
        case .runningOnly:
            return runningApps.filter { app in
                groupApps.contains(where: { $0.bundleId == app.bundleId })
            }.count
        case .shortcutOnly:
            return shortcuts.filter { shortcut in
                groupApps.contains(where: { $0.bundleId == shortcut.bundleIdentifier })
            }.count
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
                            .fill(Color.blue)
                    )
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .menuIndicator(.hidden)
                .fixedSize()
                
                Divider()
                    .frame(height: 24)
                    .background(Color.white.opacity(0.3))
                
                // 全部应用按钮
                Button(action: {}) {
                    Text("全部")
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedAppGroup == nil ? Color.blue : Color.gray.opacity(0.3))
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        selectedAppGroup = nil
                    }
                }
                
                // 分组按钮
                ForEach(AppGroupManager.shared.groups) { group in
                    Button(action: {}) {
                        Text("\(group.name) (\(getGroupAppCount(group: group)))")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedAppGroup == group.id ? Color.blue : Color.gray.opacity(0.3))
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            selectedAppGroup = group.id
                        }
                    }
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
        guard let groupId = selectedAppGroup else {
            switch appDisplayMode {
            case .all:
                return installedApps
            case .runningOnly:
                return runningApps
            case .shortcutOnly:
                return shortcuts.compactMap { shortcut in
                    AppInfo(
                        bundleId: shortcut.bundleIdentifier,
                        name: shortcut.appName,
                        icon: NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: shortcut.bundleIdentifier)?.path ?? ""),
                        url: NSWorkspace.shared.urlForApplication(withBundleIdentifier: shortcut.bundleIdentifier)
                    )
                }
            }
        }
        
        let groupApps = AppGroupManager.shared.groups.first(where: { $0.id == groupId })?.apps ?? []
        switch appDisplayMode {
        case .all:
            return installedApps.filter { app in
                groupApps.contains(where: { $0.bundleId == app.bundleId })
            }
        case .runningOnly:
            return runningApps.filter { app in
                groupApps.contains(where: { $0.bundleId == app.bundleId })
            }
        case .shortcutOnly:
            return shortcuts
                .filter { shortcut in
                    groupApps.contains(where: { $0.bundleId == shortcut.bundleIdentifier })
                }
                .compactMap { shortcut in
                    AppInfo(
                        bundleId: shortcut.bundleIdentifier,
                        name: shortcut.appName,
                        icon: NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: shortcut.bundleIdentifier)?.path ?? ""),
                        url: NSWorkspace.shared.urlForApplication(withBundleIdentifier: shortcut.bundleIdentifier)
                    )
                }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: settings.appIconSize + 20), spacing: 16)
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
                GridItem(.adaptive(minimum: settings.webIconSize + 20), spacing: 16)
            ], spacing: 16) {
                let websites = websiteManager.getWebsites(mode: websiteDisplayMode, groupId: selectedWebGroup)
                ForEach(websites) { website in
                    WebsiteIconView(website: website)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .padding(.top, 8)
    }
}

// MARK: - 网站图标视图
private struct WebsiteIconView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var iconManager = WebIconManager.shared
    let website: Website
    
    var body: some View {
        IconView(
            icon: iconManager.icon(for: website.id) ?? NSImage(systemSymbolName: "globe", accessibilityDescription: nil)!,
            size: settings.webIconSize,
            label: {
                VStack(spacing: 2) {
                    if settings.showWebsiteName {
                        Text(website.name)
                            .font(.system(size: settings.websiteNameFontSize))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(width: 60)
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
                            .fill(Color.blue)
                    )
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .menuIndicator(.hidden)
                .fixedSize()
                
                Divider()
                    .frame(height: 24)
                    .background(Color.white.opacity(0.3))
                
                // 全部网站按钮
                Button(action: {}) {
                    Text("全部")
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedWebGroup == nil ? Color.blue : Color.gray.opacity(0.3))
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        selectedWebGroup = nil
                    }
                }
                
                // 分组按钮
                ForEach(websiteManager.groups) { group in
                    Button(action: {}) {
                        Text("\(group.name) (\(websiteManager.getWebsites(mode: .all, groupId: group.id).count))")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedWebGroup == group.id ? Color.blue : Color.gray.opacity(0.3))
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            selectedWebGroup = group.id
                        }
                    }
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
                        Text("⌘\(key)")
                            .font(.system(size: settings.webShortcutLabelFontSize, weight: .medium))
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
                        Text("⌘\(key)")
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
    let app: AppInfo
    
    var body: some View {
        IconView(
            icon: app.icon,
            size: AppSettings.shared.appIconSize,
            label: {
                if settings.showAppName {
                    Text(app.name)
                        .font(.system(size: settings.appNameFontSize))
                        .foregroundColor(.white)
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
    private var previewWindow: NSWindow?
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
                self?.updateWindowSize()
                self?.updatePreviewWindow()
            }
        }
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // 显示预览窗口
    func showPreviewWindow() {
        if previewWindow == nil {
            let view = DockIconsView()
            let hostingView = NSHostingView(rootView: view)
            
            let settings = AppSettings.shared
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: settings.floatingWindowWidth, height: settings.floatingWindowHeight),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            window.contentView = hostingView
            window.backgroundColor = .clear
            window.isOpaque = false
            window.level = .normal
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            
            self.previewWindow = window
        }
        
        if let window = previewWindow {
            updatePreviewWindow()
            window.orderFront(nil)
        }
    }
    
    // 隐藏预览窗口
    func hidePreviewWindow() {
        previewWindow?.orderOut(nil)
    }
    
    // 更新预览窗口
    func updatePreviewWindow() {
        if let window = previewWindow {
            let settings = AppSettings.shared
            window.setContentSize(NSSize(width: settings.floatingWindowWidth, height: settings.floatingWindowHeight))
            updateWindowPosition(window)
        }
    }
    
    private func updateWindowSize() {
        if let window = window {
            let settings = AppSettings.shared
            window.setContentSize(NSSize(width: settings.floatingWindowWidth, height: settings.floatingWindowHeight))
            updateWindowPosition(window)
        }
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
    
    func showWindow() {
        print("显示悬浮窗")
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
            
            window.contentView = hostingView
            window.backgroundColor = .clear
            window.isOpaque = false
            window.level = .floating
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            
            self.window = window
        }
        
        if let window = window {
            // 更新窗口大小
            updateWindowSize()
            
            window.orderFront(nil)
            isVisible = true
            print("悬浮窗已显示，当前显示模式: \(AppSettings.shared.appDisplayMode)")
        }
    }
    
    func hideWindow() {
        print("隐藏悬浮窗")
        window?.orderOut(nil)
        isVisible = false
        print("悬浮窗已隐藏")
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
