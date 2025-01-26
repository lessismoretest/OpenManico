import SwiftUI
import AppKit

/**
 * 悬浮窗全局工具栏组件
 */
struct FloatingWindowToolbar: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var systemColorScheme
    
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
    
    private var iconColor: Color {
        effectiveColorScheme == .dark ? .white : .black.opacity(0.85)
    }
    
    private var toolbarBackgroundColor: Color {
        effectiveColorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.3)
    }
    
    var body: some View {
        HStack {
            Button(action: {
                settings.showAppsInFloatingWindow.toggle()
                settings.saveSettings()
                DockIconsWindowController.shared.updateWindow()
            }) {
                Image(systemName: settings.showAppsInFloatingWindow ? "square.grid.2x2.fill" : "square.grid.2x2")
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(settings.showAppsInFloatingWindow ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .help(settings.showAppsInFloatingWindow ? "隐藏应用" : "显示应用")
            
            Button(action: {
                settings.showWebShortcutsInFloatingWindow.toggle()
                settings.saveSettings()
                DockIconsWindowController.shared.updateWindow()
            }) {
                Image(systemName: settings.showWebShortcutsInFloatingWindow ? "safari.fill" : "safari")
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(settings.showWebShortcutsInFloatingWindow ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .help(settings.showWebShortcutsInFloatingWindow ? "隐藏网站" : "显示网站")
            
            Spacer()
            
            Button(action: {
                settings.openAppOnMouseHover.toggle()
                settings.saveSettings()
            }) {
                Image(systemName: settings.openAppOnMouseHover ? "hand.tap.fill" : "hand.tap")
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(settings.openAppOnMouseHover ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .help(settings.openAppOnMouseHover ? "关闭鼠标滑过立即打开应用" : "开启鼠标滑过立即打开应用")
            
            Button(action: {
                settings.isPinned.toggle()
                if settings.isPinned {
                    // 设置窗口置顶，不再响应点击空白处关闭
                    DockIconsWindowController.shared.setPinned(true)
                } else {
                    // 取消窗口置顶，恢复点击空白处关闭
                    DockIconsWindowController.shared.setPinned(false)
                }
            }) {
                Image(systemName: settings.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(settings.isPinned ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .help("置顶窗口")
            
            Button(action: {
                DockIconsWindowController.shared.hideWindow()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("关闭窗口")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(toolbarBackgroundColor)
    }
}

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
    @State private var websiteDisplayMode: WebsiteDisplayMode = .all
    @State private var selectedAppGroup: UUID?
    @State private var selectedWebGroup: UUID?
    @State private var webIcons: [UUID: NSImage] = [:]
    @Environment(\.colorScheme) private var systemColorScheme
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            // 全局工具栏，根据设置显示或隐藏
            if settings.showToolbar {
                FloatingWindowToolbar()
            }
            
            // 创建应用区域视图
            let appAreaView: some View = Group {
                if settings.showAppsInFloatingWindow {
                    if settings.groupDisplayPosition == .vertical {
                        // 垂直布局
                        HStack(spacing: 0) {
                            if settings.showGroupsInFloatingWindow {
                                // 左侧区域 - 侧边分组(包含应用模式切换按钮)
                                SideGroupsView(
                                    selectedAppGroup: $selectedAppGroup,
                                    appDisplayMode: $appDisplayMode,
                                    installedApps: installedApps,
                                    runningApps: runningApps
                                )
                            } else {
                                // 只显示应用模式切换按钮
                                VStack {
                                    Button(action: {
                                        // 切换显示模式
                                        appDisplayMode = appDisplayMode == .all ? .runningOnly : .all
                                    }) {
                                        HStack {
                                            Image(systemName: appDisplayMode == .all ? "square.grid.2x2.fill" : "play.fill")
                                                .foregroundColor(.white)
                                            Text(appDisplayMode == .all ? "所有应用" : "运行中")
                                                .foregroundColor(.white)
                                                .font(.system(size: 12))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .help(appDisplayMode == .all ? "点击切换到只显示运行中应用" : "点击切换到显示所有应用")
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .frame(width: 100)
                                .background(effectiveColorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.05))
                            }
                            
                            // 右侧区域 - 应用列表
                            DockAppListView(
                                appDisplayMode: appDisplayMode,
                                installedApps: installedApps,
                                runningApps: runningApps,
                                shortcuts: settings.shortcuts,
                                selectedAppGroup: selectedAppGroup
                            )
                            .padding(.trailing, 12)
                        }
                    } else {
                        // 水平布局，顶部工具栏包含应用模式切换按钮和分组
                        VStack(spacing: 0) {
                            if settings.showGroupsInFloatingWindow {
                                // 显示完整的顶部工具栏（包含分组）
                                TopToolbarView(
                                    appDisplayMode: $appDisplayMode,
                                    selectedAppGroup: $selectedAppGroup,
                                    installedApps: installedApps,
                                    runningApps: runningApps,
                                    shortcuts: settings.shortcuts
                                )
                            } else {
                                // 只显示应用模式切换按钮
                                HStack {
                                    Button(action: {
                                        // 切换显示模式
                                        appDisplayMode = appDisplayMode == .all ? .runningOnly : .all
                                    }) {
                                        HStack {
                                            Image(systemName: appDisplayMode == .all ? "square.grid.2x2.fill" : "play.fill")
                                                .foregroundColor(.white)
                                            Text(appDisplayMode == .all ? "所有应用" : "运行中应用")
                                                .foregroundColor(.white)
                                                .font(.system(size: 12))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .help(appDisplayMode == .all ? "点击切换到只显示运行中应用" : "点击切换到显示所有应用")
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.top, 8)
                            }
                            
                            DockAppListView(
                                appDisplayMode: appDisplayMode,
                                installedApps: installedApps,
                                runningApps: runningApps,
                                shortcuts: settings.shortcuts,
                                selectedAppGroup: selectedAppGroup
                            )
                        }
                    }
                }
            }
            
            // 创建网站区域视图
            let websiteAreaView: some View = Group {
                if settings.showWebShortcutsInFloatingWindow {
                    if settings.webGroupDisplayPosition == .vertical {
                        // 垂直布局
                        HStack(spacing: 0) {
                            if settings.showGroupsInFloatingWindow {
                                // 左侧区域 - 侧边网站分组
                                SideWebGroupsView(
                                    selectedWebGroup: $selectedWebGroup
                                )
                            } else {
                                // 不显示分组，留一个小边距
                                Spacer()
                                    .frame(width: 8)
                            }
                            
                            // 右侧区域 - 网站列表
                            WebShortcutListView(
                                websiteDisplayMode: websiteDisplayMode,
                                selectedWebGroup: selectedWebGroup,
                                webIcons: webIcons,
                                onWebIconsUpdate: { newIcons in
                                    webIcons = newIcons
                                }
                            )
                            .padding(.trailing, 12)
                        }
                    } else {
                        // 水平布局
                        VStack(spacing: 0) {
                            if settings.showGroupsInFloatingWindow {
                                WebShortcutToolbarView(
                                    websiteDisplayMode: $websiteDisplayMode,
                                    selectedWebGroup: $selectedWebGroup
                                )
                            }
                            
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
                }
            }
            
            // 根据设置的顺序和比例显示应用和网站区域
            if settings.showAppsInFloatingWindow && settings.showWebShortcutsInFloatingWindow {
                // 两个区域都显示，需要按比例分配空间
                GeometryReader { geometry in
                    if settings.layoutDirection == .vertical {
                        // 上下布局
                        if settings.appWebsiteOrder == .appFirst {
                            // 应用区域在上，网站区域在下
                            VStack(spacing: settings.areaSeparatorSize) {
                                appAreaView
                                    .frame(height: geometry.size.height * settings.appAreaRatio)
                                
                                if settings.showDivider {
                                    Divider()
                                        .opacity(settings.dividerOpacity)
                                }
                                
                                websiteAreaView
                                    .frame(height: geometry.size.height * (1 - settings.appAreaRatio))
                            }
                        } else {
                            // 网站区域在上，应用区域在下
                            VStack(spacing: settings.areaSeparatorSize) {
                                websiteAreaView
                                    .frame(height: geometry.size.height * (1 - settings.appAreaRatio))
                                
                                if settings.showDivider {
                                    Divider()
                                        .opacity(settings.dividerOpacity)
                                }
                                
                                appAreaView
                                    .frame(height: geometry.size.height * settings.appAreaRatio)
                            }
                        }
                    } else {
                        // 左右布局
                        if settings.appWebsiteOrder == .appFirst {
                            // 应用区域在左，网站区域在右
                            HStack(spacing: settings.areaSeparatorSize) {
                                appAreaView
                                    .frame(width: geometry.size.width * settings.appAreaRatio)
                                
                                if settings.showDivider {
                                    Divider()
                                        .opacity(settings.dividerOpacity)
                                }
                                
                                websiteAreaView
                                    .frame(width: geometry.size.width * (1 - settings.appAreaRatio))
                            }
                        } else {
                            // 网站区域在左，应用区域在右
                            HStack(spacing: settings.areaSeparatorSize) {
                                websiteAreaView
                                    .frame(width: geometry.size.width * (1 - settings.appAreaRatio))
                                
                                if settings.showDivider {
                                    Divider()
                                        .opacity(settings.dividerOpacity)
                                }
                                
                                appAreaView
                                    .frame(width: geometry.size.width * settings.appAreaRatio)
                            }
                        }
                    }
                }
            } else if settings.showAppsInFloatingWindow {
                // 只显示应用区域
                appAreaView
            } else if settings.showWebShortcutsInFloatingWindow {
                // 只显示网站区域
                websiteAreaView
            }
        }
        .onAppear {
            appDisplayMode = settings.appDisplayMode
            websiteDisplayMode = settings.websiteDisplayMode
            scanApps()
            startRunningAppsMonitor()
            setupHotKeys()
            
            // 注意：Option键的监听由HotKeyManager统一处理，避免多处监听导致的冲突
        }
        .onDisappear {
            // 不再需要移除Option键监听，因为已经在HotKeyManager中统一处理了
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
    @StateObject private var settings = AppSettings.shared
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
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 固定区域 - 应用显示模式按钮
            Button(action: {
                // 切换显示模式
                appDisplayMode = appDisplayMode == .all ? .runningOnly : .all
            }) {
                Image(systemName: appDisplayMode == .all ? "square.grid.2x2.fill" : "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(buttonBackgroundColor)
                    )
            }
            .buttonStyle(.plain)
            .help(appDisplayMode == .all ? "点击切换到只显示运行中应用" : "点击切换到显示所有应用")
            
            Divider()
                .frame(height: 24)
                .background(Color.primary.opacity(0.3))
            
            // 固定区域 - 全部应用按钮
            Button(action: {
                selectedAppGroup = nil
            }) {
                let totalCount = switch appDisplayMode {
                    case .all: installedApps.count
                    case .runningOnly: runningApps.count
                }
                
                if settings.showGroupCountInFloatingWindow {
                    Text("全部 (\(totalCount))")
                        .foregroundColor(getTextColor(isSelected: selectedAppGroup == nil))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedAppGroup == nil ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                        )
                } else {
                    Text("全部")
                        .foregroundColor(getTextColor(isSelected: selectedAppGroup == nil))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedAppGroup == nil ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                        )
                }
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 24)
                .background(Color.primary.opacity(0.3))
            
            // 可滚动区域 - 分组按钮
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppGroupManager.shared.groups) { group in
                        Button(action: {
                            selectedAppGroup = group.id
                        }) {
                            if settings.showGroupCountInFloatingWindow {
                                Text("\(group.name) (\(getGroupAppCount(group: group)))")
                                    .foregroundColor(getTextColor(isSelected: selectedAppGroup == group.id))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedAppGroup == group.id ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                                    )
                            } else {
                                Text(group.name)
                                    .foregroundColor(getTextColor(isSelected: selectedAppGroup == group.id))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedAppGroup == group.id ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 8)
            }
        }
        .padding(.horizontal, 8)
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
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: settings.appIconSize))
            ], spacing: settings.iconGridSpacing) {
                ForEach(filteredApps, id: \.bundleId) { app in
                    AppIconView(app: app, runningApps: runningApps)
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
                GridItem(.adaptive(minimum: settings.webIconSize))
            ], spacing: settings.iconGridSpacing) {
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
                // 增加使用次数
                AppSettings.shared.incrementUsageCount(type: .floatingWindow)
                
                if let url = URL(string: website.url) {
                    NSWorkspace.shared.open(url)
                }
            },
            shortcutKey: website.shortcutKey,
            isWebsite: true,
            isRunning: false
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
    @StateObject private var settings = AppSettings.shared
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
        HStack(spacing: 12) {
            // 固定区域 - 全部网站按钮
            Button(action: {
                selectedWebGroup = nil
            }) {
                Image(systemName: "globe")
                    .foregroundColor(getTextColor(isSelected: selectedWebGroup == nil))
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedWebGroup == nil ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                    )
            }
            .buttonStyle(.plain)
            .help("显示全部网站")
            
            Divider()
                .frame(height: 24)
                .background(Color.primary.opacity(0.3))
            
            // 可滚动区域 - 分组按钮
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(websiteManager.groups) { group in
                        Button(action: {
                            selectedWebGroup = group.id
                        }) {
                            if settings.showGroupCountInFloatingWindow {
                                let count = websiteManager.getWebsites(mode: .all, groupId: group.id).count
                                Text("\(group.name) (\(count))")
                                    .foregroundColor(getTextColor(isSelected: selectedWebGroup == group.id))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedWebGroup == group.id ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                                    )
                            } else {
                                Text(group.name)
                                    .foregroundColor(getTextColor(isSelected: selectedWebGroup == group.id))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedWebGroup == group.id ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

struct IconView<Label: View>: View {
    @StateObject private var settings = AppSettings.shared
    @State private var isHovering = false
    let icon: NSImage
    let size: CGFloat
    let label: Label
    let onTap: (() -> Void)?
    let shortcutKey: String?
    let isWebsite: Bool
    let isRunning: Bool
    
    init(
        icon: NSImage,
        size: CGFloat,
        @ViewBuilder label: () -> Label,
        onTap: (() -> Void)? = nil,
        shortcutKey: String? = nil,
        isWebsite: Bool = false,
        isRunning: Bool = false
    ) {
        self.icon = icon
        self.size = size
        self.label = label()
        self.onTap = onTap
        self.shortcutKey = shortcutKey
        self.isWebsite = isWebsite
        self.isRunning = isRunning
    }
    
    var body: some View {
        VStack(spacing: settings.iconSpacing) {
            ZStack {
                // 图标悬停背景
                if settings.useHoverBackground && isHovering {
                    RoundedRectangle(cornerRadius: settings.iconHoverBackgroundCornerRadius)
                        .fill(settings.iconHoverBackgroundColor)
                        .frame(
                            width: size + settings.iconHoverBackgroundPadding * 2,
                            height: size + settings.iconHoverBackgroundPadding * 2
                        )
                }
                
                // 图标
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: settings.iconCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: settings.iconCornerRadius)
                            .stroke(isHovering ? settings.iconBorderColor : Color.clear, lineWidth: settings.iconBorderWidth)
                    )
                    .shadow(radius: settings.useIconShadow ? settings.iconShadowRadius : 0)
                    .scaleEffect(isHovering && settings.useHoverAnimation ? settings.hoverScale : 1.0)
                    .animation(.easeInOut(duration: settings.useHoverAnimation ? settings.hoverAnimationDuration : 0), value: isHovering)
                
                // 运行指示器
                if isRunning && settings.showRunningIndicator {
                    runningIndicator
                }
                
                // 快捷键标签
                if let key = shortcutKey {
                    if (isWebsite && settings.showWebShortcutLabel) || (!isWebsite && settings.showAppShortcutLabel) {
                        shortcutLabel(key)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
            .onHover { hovering in
                isHovering = hovering
                // 当鼠标悬停在应用图标上并且启用了悬停立即打开应用功能时，触发打开应用
                if hovering && settings.openAppOnMouseHover && !isWebsite {
                    onTap?()
                }
            }
            
            // 标签部分
            label
        }
    }
    
    private var runningIndicator: some View {
        let indicatorOffset = getLabelOffset(position: settings.runningIndicatorPosition)
        return Circle()
            .fill(settings.runningIndicatorColor)
            .frame(width: settings.runningIndicatorSize, height: settings.runningIndicatorSize)
            .offset(x: indicatorOffset.x, y: indicatorOffset.y)
    }
    
    @ViewBuilder
    private func shortcutLabel(_ key: String) -> some View {
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
        } else {
            EmptyView()
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
    let runningApps: [AppInfo]
    
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
    
    private var isAppRunning: Bool {
        runningApps.contains(where: { $0.bundleId == app.bundleId })
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
                // 增加使用次数
                AppSettings.shared.incrementUsageCount(type: .floatingWindow)
                
                // 检查是否为当前运行的应用
                if isAppRunning && AppSettings.shared.clickAppToToggle {
                    // 获取当前应用
                    if let currentApp = NSWorkspace.shared.frontmostApplication,
                       currentApp.bundleIdentifier == app.bundleId {
                        // 如果是当前前台应用，则切换到上一个应用
                        if let lastApp = HotKeyManager.shared.getLastActiveApp(),
                           lastApp.bundleIdentifier != currentApp.bundleIdentifier,
                           !lastApp.isTerminated {
                            // 切换到上一个应用
                            HotKeyManager.shared.switchToApp(bundleIdentifier: lastApp.bundleIdentifier ?? "")
                            return
                        }
                    }
                }
                
                // 如果不是运行中的应用，或者功能未启用，或者没有上一个应用，则正常打开应用
                if let url = app.url {
                    NSWorkspace.shared.open(url)
                }
            },
            shortcutKey: settings.shortcuts.first(where: { $0.bundleIdentifier == app.bundleId })?.key,
            isWebsite: false,
            isRunning: isAppRunning
        )
    }
}

/**
 * 窗口点击事件代理，防止点击空白处激活应用主窗口
 */
class WindowClickDelegate: NSObject, NSWindowDelegate {
    // 阻止窗口变为关键窗口(Key Window)，防止点击事件传递到应用主窗口
    func windowShouldBecomeKey(_ window: NSWindow) -> Bool {
        return false
    }
    
    // 阻止窗口变为主窗口(Main Window)
    func windowShouldBecomeMain(_ window: NSWindow) -> Bool {
        return false
    }
    
    // 阻止窗口激活应用
    func windowDidBecomeMain(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.orderOut(nil)
            window.orderFront(nil)
        }
    }
    
    // 阻止窗口成为第一响应者
    func windowDidBecomeKey(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.makeFirstResponder(nil)
        }
    }
}

/**
 * Dock 栏程序图标窗口控制器
 */
class DockIconsWindowController {
    static let shared = DockIconsWindowController()
    private var window: NSWindow?
    @objc private(set) var isVisible = false
    private var observer: NSObjectProtocol?
    private var backgroundMonitor: Any? // 用于监听点击空白区域
    private var isPinned = false // 窗口是否置顶
    
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
        removeBackgroundMonitor()
    }
    
    // 设置窗口置顶状态
    func setPinned(_ pinned: Bool) {
        self.isPinned = pinned
        // 同步更新全局设置中的置顶状态，确保工具栏按钮显示正确
        AppSettings.shared.isPinned = pinned
        
        if pinned {
            // 如果置顶，移除背景点击监听器
            removeBackgroundMonitor()
            
            // 设置窗口层级为浮动+1，确保在其他浮动窗口之上
            window?.level = .floating + 1
        } else {
            // 如果不置顶，添加背景点击监听器
            setupBackgroundMonitor()
            
            // 恢复正常窗口层级
            window?.level = .floating
        }
    }
    
    // 添加背景点击监听器
    private func setupBackgroundMonitor() {
        // 如果窗口已置顶，则不添加监听器
        if isPinned {
            return
        }
        
        // 先移除之前的监听器
        removeBackgroundMonitor()
        
        // 添加新的监听器，监听全局鼠标点击事件
        backgroundMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let window = self.window else { return }
            
            // 获取点击位置（屏幕坐标系）
            let clickLocation = NSEvent.mouseLocation
            
            // 将点击位置转换为窗口坐标系
            let windowFrame = window.frame
            
            // 检查点击位置是否在窗口范围外
            if !NSPointInRect(clickLocation, windowFrame) {
                // 只有点击窗口外部时才关闭窗口
                self.hideWindow()
            }
        }
    }
    
    // 移除背景点击监听器
    private func removeBackgroundMonitor() {
        if let monitor = backgroundMonitor {
            NSEvent.removeMonitor(monitor)
            backgroundMonitor = nil
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
        
        // ===== 全新的更新逻辑 =====
        // 获取基础容器视图
        if let baseContainerView = window.contentView {
            // 找到背景视图和前景视图
            let subviews = baseContainerView.subviews
            guard subviews.count >= 2,
                  let backgroundView = subviews[0] as? NSVisualEffectView else {
                return
            }
            
            // 更新背景视图设置
            backgroundView.layer?.cornerRadius = settings.floatingWindowCornerRadius
            backgroundView.layer?.masksToBounds = true
            
            // 根据主题设置更新外观
            switch settings.floatingWindowTheme {
            case .system:
                backgroundView.appearance = nil
            case .light:
                backgroundView.appearance = NSAppearance(named: .aqua)
            case .dark:
                backgroundView.appearance = NSAppearance(named: .darkAqua)
            }
            
            // 根据是否使用毛玻璃效果来设置
            if settings.useBlurEffect {
                backgroundView.state = .active
                backgroundView.material = .hudWindow
                // 清除可能存在的背景色
                backgroundView.layer?.backgroundColor = nil
                backgroundView.alphaValue = 1.0
            } else {
                backgroundView.state = .inactive
                backgroundView.material = .titlebar
                
                // 更新背景颜色
                let bgColor = getWindowBackgroundColor()
                backgroundView.layer?.backgroundColor = bgColor.cgColor
                
                // 关键：更新背景透明度
                backgroundView.alphaValue = settings.floatingWindowOpacity
                
                // 调试输出
                print("更新背景不透明度: \(settings.floatingWindowOpacity)")
            }
        }
        
        // 设置窗口属性
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = .clear
        
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
        }
    }
    
    // 显示窗口
    func showWindow() {
        // 如果悬浮窗功能被禁用，直接返回
        if !AppSettings.shared.showFloatingWindow {
            return
        }
        
        if window == nil {
            let view = DockIconsView()
            let hostingView = NSHostingView(rootView: view)
            
            let settings = AppSettings.shared
            
            // 使用NSPanel而不是NSWindow
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: settings.floatingWindowWidth, height: settings.floatingWindowHeight),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            // ===== 全新的层次结构 =====
            // 1. 首先创建一个基础容器视图作为窗口内容视图
            let baseContainerView = NSView()
            baseContainerView.wantsLayer = true
            baseContainerView.layer?.backgroundColor = NSColor.clear.cgColor
            panel.contentView = baseContainerView
            
            // 2. 创建背景视图 - 负责背景效果和透明度
            let backgroundView = NSVisualEffectView()
            backgroundView.blendingMode = .behindWindow
            backgroundView.wantsLayer = true
            backgroundView.layer?.cornerRadius = settings.floatingWindowCornerRadius
            backgroundView.layer?.masksToBounds = true
            
            // 根据是否使用毛玻璃效果设置不同的样式
            if settings.useBlurEffect {
                backgroundView.material = .hudWindow
                backgroundView.state = .active
            } else {
                backgroundView.material = .titlebar
                backgroundView.state = .inactive
                backgroundView.layer?.backgroundColor = getWindowBackgroundColor().cgColor
                backgroundView.alphaValue = settings.floatingWindowOpacity
            }
            
            // 将背景视图添加到基础容器中并设置自动布局
            baseContainerView.addSubview(backgroundView)
            backgroundView.frame = baseContainerView.bounds
            backgroundView.autoresizingMask = [.width, .height]
            
            // 3. 创建前景内容视图 - 始终不透明
            let foregroundView = NSView()
            foregroundView.wantsLayer = true
            foregroundView.layer?.backgroundColor = NSColor.clear.cgColor
            
            // 将前景视图添加到基础容器中并设置自动布局
            baseContainerView.addSubview(foregroundView)
            foregroundView.frame = baseContainerView.bounds
            foregroundView.autoresizingMask = [.width, .height]
            
            // 4. 将实际内容添加到前景视图
            foregroundView.addSubview(hostingView)
            hostingView.frame = foregroundView.bounds
            hostingView.autoresizingMask = [.width, .height]
            
            // 设置窗口属性
            panel.isOpaque = false
            panel.backgroundColor = .clear // 窗口背景色设为透明
            panel.level = .floating
            panel.hasShadow = false
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
            panel.isMovableByWindowBackground = true
            
            // 关键设置：防止激活应用
            panel.becomesKeyOnlyIfNeeded = true
            panel.isExcludedFromWindowsMenu = true
            
            // 添加更多nonactivating属性
            panel.styleMask.insert(.nonactivatingPanel)
            
            // 设置窗口代理，处理点击事件
            let windowDelegate = WindowClickDelegate()
            panel.delegate = windowDelegate
            
            // 设置窗口圆角
            if let windowBackgroundView = panel.contentView?.superview {
                windowBackgroundView.wantsLayer = true
                windowBackgroundView.layer?.cornerRadius = settings.floatingWindowCornerRadius
                windowBackgroundView.layer?.masksToBounds = true
            }
            
            self.window = panel
        }
        
        updateWindow()
        
        // 重要：确保窗口显示时不激活应用
        NSApp.deactivate()
        window?.orderFrontRegardless()
        isVisible = true
        
        // 检查当前是否为置顶状态
        if AppSettings.shared.isPinned {
            setPinned(true)
        } else {
            // 添加背景点击监听
            setupBackgroundMonitor()
        }
    }
    
    // 隐藏窗口
    func hideWindow() {
        print("🔽 窗口控制器：隐藏悬浮窗")
        
        // 执行窗口隐藏操作
        window?.orderOut(nil)
        isVisible = false
        
        // 移除背景点击监听
        removeBackgroundMonitor()
        
        // 如果当前是置顶状态，取消置顶
        if isPinned {
            AppSettings.shared.isPinned = false
            isPinned = false
        }
        
        // 通知HotKeyManager窗口已关闭
        HotKeyManager.shared.notifyWindowClosed()
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

// MARK: - 侧边分组视图
private struct SideGroupsView: View {
    @Binding var selectedAppGroup: UUID?
    @Binding var appDisplayMode: AppDisplayMode
    @StateObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var systemColorScheme
    let installedApps: [AppInfo]
    let runningApps: [AppInfo]
    
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
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 应用显示模式按钮
            Button(action: {
                // 切换显示模式
                appDisplayMode = appDisplayMode == .all ? .runningOnly : .all
            }) {
                HStack {
                    Image(systemName: appDisplayMode == .all ? "square.grid.2x2.fill" : "play.fill")
                        .foregroundColor(.white)
                    Spacer()
                    Text(appDisplayMode == .all ? "所有应用" : "运行中应用")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(buttonBackgroundColor)
                )
            }
            .buttonStyle(.plain)
            .help(appDisplayMode == .all ? "点击切换到只显示运行中应用" : "点击切换到显示所有应用")
            
            // 全部应用按钮
            Button(action: {
                selectedAppGroup = nil
            }) {
                let totalCount = switch appDisplayMode {
                    case .all: installedApps.count
                    case .runningOnly: runningApps.count
                }
                
                HStack {
                    Text("全部")
                        .foregroundColor(getTextColor(isSelected: selectedAppGroup == nil))
                    Spacer()
                    if settings.showGroupCountInFloatingWindow {
                        Text("\(totalCount)")
                            .foregroundColor(getTextColor(isSelected: selectedAppGroup == nil))
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedAppGroup == nil ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                )
            }
            .buttonStyle(.plain)
            
            if settings.showGroupsInFloatingWindow {
                Divider()
                    .padding(.vertical, 4)
                
                // 分组按钮列表
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(AppGroupManager.shared.groups) { group in
                            Button(action: {
                                selectedAppGroup = group.id
                            }) {
                                HStack {
                                    Text(group.name)
                                        .foregroundColor(getTextColor(isSelected: selectedAppGroup == group.id))
                                    Spacer()
                                    if settings.showGroupCountInFloatingWindow {
                                        Text("\(getGroupAppCount(group: group))")
                                            .foregroundColor(getTextColor(isSelected: selectedAppGroup == group.id))
                                            .font(.caption)
                                    }
                                }
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
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(width: 160)
        .background(effectiveColorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.05))
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - 侧边网站分组视图
private struct SideWebGroupsView: View {
    @Binding var selectedWebGroup: UUID?
    @StateObject private var settings = AppSettings.shared
    @StateObject private var websiteManager = WebsiteManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    
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
        VStack(spacing: 8) {
            // 全部网站按钮
            Button(action: {
                selectedWebGroup = nil
            }) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(getTextColor(isSelected: selectedWebGroup == nil))
                    Spacer()
                    Text("全部网站")
                        .foregroundColor(getTextColor(isSelected: selectedWebGroup == nil))
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedWebGroup == nil ? buttonBackgroundColor : inactiveButtonBackgroundColor)
                )
            }
            .buttonStyle(.plain)
            .help("显示全部网站")
            
            if settings.showGroupsInFloatingWindow {
                Divider()
                    .padding(.vertical, 4)
                
                // 分组按钮列表
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(websiteManager.groups) { group in
                            Button(action: {
                                selectedWebGroup = group.id
                            }) {
                                HStack {
                                    Text(group.name)
                                        .foregroundColor(getTextColor(isSelected: selectedWebGroup == group.id))
                                    Spacer()
                                    if settings.showGroupCountInFloatingWindow {
                                        let count = websiteManager.getWebsites(mode: .all, groupId: group.id).count
                                        Text("\(count)")
                                            .foregroundColor(getTextColor(isSelected: selectedWebGroup == group.id))
                                            .font(.caption)
                                    }
                                }
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
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(width: 160)
        .background(effectiveColorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.05))
        .frame(maxHeight: .infinity, alignment: .top)
    }
} 
