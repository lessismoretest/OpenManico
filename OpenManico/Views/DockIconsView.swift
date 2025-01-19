import SwiftUI
import AppKit

/**
 * Dock 栏程序图标视图
 */
struct DockIconsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var hotKeyManager = HotKeyManager.shared
    @StateObject private var webShortcutManager = HotKeyManager.shared.webShortcutManager
    @State private var webIcons: [UUID: NSImage] = [:]
    @State private var installedApps: [AppInfo] = []
    @State private var selectedAppGroup: UUID? = nil
    @State private var selectedWebGroup: UUID? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部选择器
            if settings.showSceneSwitcherInFloatingWindow {
                if settings.appDisplayMode == .installed {
                    // 分组横向显示
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
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
                                    Text("\(group.name) (\(group.apps.count))")
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
                } else {
                    // 原有的场景选择器
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.white)
                        
                        let currentScene = settings.currentScene ?? settings.scenes.first ?? Scene(name: "默认场景", shortcuts: [])
                        Picker("", selection: Binding(
                            get: { currentScene },
                            set: { settings.switchScene(to: $0) }
                        )) {
                            let scenes = settings.scenes.isEmpty ? [Scene(name: "默认场景", shortcuts: [])] : settings.scenes
                            ForEach(scenes) { scene in
                                Text(scene.name).tag(scene)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    .padding(.top, 8)
                }
            }
            
            // 应用图标列表
            if settings.appDisplayMode == .installed {
                // 显示所有已安装应用或已过滤的应用
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: settings.appIconSize + 20), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredApps, id: \.bundleId) { app in
                            VStack {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: settings.appIconSize, height: settings.appIconSize)
                                    .onTapGesture {
                                        if let url = app.url {
                                            print("打开应用: \(app.name) at \(url)")
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                
                                Text(app.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .frame(width: 100)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    print("显示已安装应用列表，当前数量: \(installedApps.count)")
                }
            } else {
                // 应用程序图标
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        let shortcuts = settings.currentScene?.shortcuts ?? []
                        let displayShortcuts = settings.appDisplayMode == .running
                            ? shortcuts.filter { shortcut in
                                NSWorkspace.shared.runningApplications.contains { app in
                                    app.bundleIdentifier == shortcut.bundleIdentifier
                                }
                            }
                            : shortcuts
                        
                        ForEach(Array(displayShortcuts.sorted(by: { $0.key < $1.key }).enumerated()), id: \.element.id) { index, shortcut in
                            if settings.appDisplayMode == .all || NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first != nil,
                               let icon = settings.appDisplayMode == .all ? NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: shortcut.bundleIdentifier)?.path ?? "") : NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first?.icon {
                                VStack(spacing: 4) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: settings.appIconSize, height: settings.appIconSize)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white, lineWidth: settings.selectedShortcutIndex == index ? 2 : 0)
                                        )
                                        .onHover { hovering in
                                            if hovering {
                                                settings.selectedShortcutIndex = index
                                                if settings.showWindowOnHover {
                                                    if let app = NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first {
                                                        app.activate(options: [.activateIgnoringOtherApps])
                                                    }
                                                    else if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: shortcut.bundleIdentifier) {
                                                        try? NSWorkspace.shared.launchApplication(at: appUrl,
                                                                                               options: [.default],
                                                                                               configuration: [:])
                                                    }
                                                    if !hotKeyManager.isOptionKeyPressed {
                                                        DockIconsWindowController.shared.hideWindow()
                                                    }
                                                }
                                            } else if settings.selectedShortcutIndex == index {
                                                settings.selectedShortcutIndex = -1
                                            }
                                        }
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onEnded { _ in
                                                    if settings.openOnMouseHover && settings.selectedShortcutIndex == index {
                                                        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first {
                                                            app.activate(options: .activateIgnoringOtherApps)
                                                        }
                                                        else if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: shortcut.bundleIdentifier) {
                                                            try? NSWorkspace.shared.launchApplication(at: appUrl,
                                                                                                   options: [.default],
                                                                                                   configuration: [:])
                                                        }
                                                        if !hotKeyManager.isOptionKeyPressed {
                                                            DockIconsWindowController.shared.hideWindow()
                                                        }
                                                    }
                                                }
                                        )
                                    
                                    Text(shortcut.key)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
            }
            
            // 网站快捷键图标
            if settings.showWebShortcutsInFloatingWindow {
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // 网站场景选择器
                if settings.showSceneSwitcherInFloatingWindow {
                    if settings.websiteDisplayMode == .shortcutOnly {
                        // 显示场景选择器
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.white)
                            Picker("", selection: Binding(
                                get: { webShortcutManager.currentScene ?? webShortcutManager.scenes.first ?? WebScene(name: "默认场景", shortcuts: []) },
                                set: { webShortcutManager.switchScene(to: $0) }
                            )) {
                                ForEach(webShortcutManager.scenes.isEmpty ? [WebScene(name: "默认场景", shortcuts: [])] : webShortcutManager.scenes) { scene in
                                    Text(scene.name).tag(scene)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                        }
                        .padding(.vertical, 8)
                    } else {
                        // 显示分组选择器
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
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
                                ForEach(WebsiteGroupManager.shared.groups) { group in
                                    Button(action: {}) {
                                        Text("\(group.name) (\(group.websiteIds.count))")
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
                
                // 网站快捷键图标
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: settings.webIconSize + 20), spacing: 16)
                    ], spacing: 16) {
                        let shortcuts = webShortcutManager.shortcuts.sorted(by: { $0.key < $1.key })
                        let displayShortcuts = settings.websiteDisplayMode == .shortcutOnly ? shortcuts : {
                            let websites = if let groupId = selectedWebGroup {
                                WebsiteManager.shared.websites.filter { website in
                                    WebsiteGroupManager.shared.groups.first(where: { $0.id == groupId })?.websiteIds.contains(website.id) ?? false
                                }
                            } else {
                                WebsiteManager.shared.websites
                            }
                            return websites.map { website in
                                if let shortcut = shortcuts.first(where: { $0.websiteId == website.id }) {
                                    return shortcut
                                } else {
                                    return WebShortcut(key: "", websiteId: website.id)
                                }
                            }
                        }()
                        
                        ForEach(Array(displayShortcuts.enumerated()), id: \.element.id) { index, shortcut in
                            if !shortcut.key.isEmpty || settings.websiteDisplayMode == .all {
                                VStack(spacing: 4) {
                                    Group {
                                        if let icon = webIcons[shortcut.websiteId] {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .frame(width: settings.webIconSize, height: settings.webIconSize)
                                        } else {
                                            Image(systemName: "globe")
                                                .resizable()
                                                .frame(width: settings.webIconSize, height: settings.webIconSize)
                                                .foregroundColor(.white)
                                                .onAppear {
                                                    if let website = WebsiteManager.shared.findWebsite(id: shortcut.websiteId) {
                                                        Task {
                                                            await website.fetchIcon { fetchedIcon in
                                                                if let icon = fetchedIcon {
                                                                    webIcons[shortcut.websiteId] = icon
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white, lineWidth: settings.selectedWebShortcutIndex == index ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        if let website = WebsiteManager.shared.findWebsite(id: shortcut.websiteId),
                                           let url = URL(string: website.url) {
                                            NSWorkspace.shared.open(url)
                                            if !hotKeyManager.isOptionKeyPressed {
                                                DockIconsWindowController.shared.hideWindow()
                                            }
                                        }
                                    }
                                    .onHover { hovering in
                                        if hovering {
                                            settings.selectedWebShortcutIndex = index
                                            if settings.openWebOnHover {
                                                if let website = WebsiteManager.shared.findWebsite(id: shortcut.websiteId),
                                                   let url = URL(string: website.url) {
                                                    NSWorkspace.shared.open(url)
                                                }
                                            }
                                        } else if settings.selectedWebShortcutIndex == index {
                                            settings.selectedWebShortcutIndex = -1
                                        }
                                    }
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onEnded { _ in
                                                if settings.openOnMouseHover && settings.selectedWebShortcutIndex == index {
                                                    if let website = WebsiteManager.shared.findWebsite(id: shortcut.websiteId),
                                                       let url = URL(string: website.url) {
                                                        NSWorkspace.shared.open(url)
                                                        if !hotKeyManager.isOptionKeyPressed {
                                                            DockIconsWindowController.shared.hideWindow()
                                                        }
                                                    }
                                                }
                                            }
                                    )
                                
                                    if !shortcut.key.isEmpty {
                                        Text("⌘\(shortcut.key)")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                    } else if settings.websiteDisplayMode == .all {
                                        if let website = WebsiteManager.shared.findWebsite(id: shortcut.websiteId) {
                                            Text(website.name)
                                                .font(.system(size: 10))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .frame(width: 60)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .background {
            if settings.useBlurEffect {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .blur(radius: settings.blurRadius)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(settings.floatingWindowOpacity))
            }
        }
        .onAppear {
            print("DockIconsView appeared, 当前显示模式: \(settings.appDisplayMode)")
            if settings.appDisplayMode == .installed {
                scanInstalledApps()
            }
        }
        .onChange(of: settings.appDisplayMode) { newMode in
            print("显示模式改变: \(newMode)")
            if newMode == .installed {
                scanInstalledApps()
            }
        }
    }
    
    private func loadWebIcon(for shortcut: WebShortcut) {
        shortcut.fetchIcon { fetchedIcon in
            if let icon = fetchedIcon {
                webIcons[shortcut.websiteId] = icon
            }
        }
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
    
    // 根据选中的分组过滤应用列表
    private var filteredApps: [AppInfo] {
        // 如果没有选中分组，返回所有应用
        guard let selectedGroupId = selectedAppGroup else {
            return installedApps
        }
        
        // 查找选中的分组
        guard let selectedGroup = AppGroupManager.shared.groups.first(where: { $0.id == selectedGroupId }) else {
            return installedApps
        }
        
        // 过滤应用列表
        return installedApps.filter { app in
            selectedGroup.apps.contains(where: { $0.bundleId == app.bundleId })
        }
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
