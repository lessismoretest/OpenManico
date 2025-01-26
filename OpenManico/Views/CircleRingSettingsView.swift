import SwiftUI

/**
 * 圆环模式设置视图
 */
struct CircleRingSettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var selectedApps: Set<String> = []
    @State private var installedApps: [AppInfo] = []
    @State private var searchText: String = ""
    @State private var showingAppSelector = false
    @State private var selectedSectorIndex: Int? = nil
    
    var body: some View {
        Form {
            // 基础设置组
            Section {
                Toggle("启用圆环模式", isOn: $settings.enableCircleRingMode)
                    .onChange(of: settings.enableCircleRingMode) { newValue in
                        settings.saveSettings()
                    }
                
                Text("在系统中按住 Option 键会在鼠标周围显示圆环快捷应用面板")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                
                // 长按时间间隔设置
                CircleRingSliderRow(
                    title: "长按时间间隔",
                    value: $settings.circleRingLongPressThreshold,
                    range: 0.1...1.0,
                    step: 0.1,
                    valueFormatter: { String(format: "%.1f秒", $0) },
                    onChange: {
                        CircleRingController.shared.updateLongPressThreshold()
                    }
                )
                Text("按住Option键多长时间后显示圆环")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text("基础设置")
            }
            
            if settings.enableCircleRingMode {
                // 应用选择器
                Section {
                    Text("圆环应用设置")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // 移动扇区数量设置到这里
                    Picker("扇区数量", selection: $settings.circleRingSectorCount) {
                        ForEach(4...12, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .onChange(of: settings.circleRingSectorCount) { _ in
                        CircleRingController.shared.reloadCircleRing()
                    }
                    
                    // 圆环扇区可视化
                    CircleRingSectorVisualizer(
                        sectorCount: settings.circleRingSectorCount,
                        apps: getConfiguredApps(),
                        selectedIndex: $selectedSectorIndex,
                        onSelectSector: { index in
                            configureAppForSector(index)
                        },
                        settings: settings
                    )
                    .frame(height: 250)
                    .padding(.vertical, 10)
                    
                    if settings.circleRingApps.isEmpty {
                        Text("未选择应用，将使用系统默认应用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                } header: {
                    Text("应用设置")
                } footer: {
                    Text("点击圆环上的扇区可配置对应位置的应用。如果未选择应用，将使用系统默认应用。")
                        .font(.caption)
                }
                
                // 圆环外观
                Section {
                    Picker("主题模式", selection: $settings.circleRingTheme) {
                        Text("跟随系统").tag(CircleRingTheme.system)
                        Text("浅色模式").tag(CircleRingTheme.light)
                        Text("深色模式").tag(CircleRingTheme.dark)
                    }
                    .onChange(of: settings.circleRingTheme) { _ in
                        CircleRingController.shared.reloadCircleRing()
                    }
                    
                    Toggle("使用毛玻璃效果", isOn: $settings.useBlurEffectForCircleRing)
                        .onChange(of: settings.useBlurEffectForCircleRing) { _ in
                            CircleRingController.shared.reloadCircleRing()
                        }
                        .help("启用半透明毛玻璃背景效果")
                    
                    if !settings.useBlurEffectForCircleRing {
                        CircleRingSliderRow(
                            title: "圆环透明度",
                            value: $settings.circleRingOpacity,
                            range: 0.1...1.0,
                            step: 0.1,
                            valueFormatter: { String(format: "%.1f", $0) },
                            onChange: {
                                CircleRingController.shared.reloadCircleRing()
                            }
                        )
                        .help("调整圆环背景的透明度")
                    }
                    
                    CircleRingSliderRow(
                        title: "圆环直径",
                        value: $settings.circleRingDiameter,
                        range: 200...500,
                        step: 10,
                        valueFormatter: { "\(Int($0))px" },
                        onChange: {
                            CircleRingController.shared.reloadCircleRing()
                        }
                    )
                    
                    CircleRingSliderRow(
                        title: "内圈直径",
                        value: $settings.circleRingInnerDiameter,
                        range: 100...450,
                        step: 10,
                        valueFormatter: { "\(Int($0))px" },
                        onChange: {
                            CircleRingController.shared.reloadCircleRing()
                        }
                    )
                    .disabled(settings.circleRingInnerDiameter > settings.circleRingDiameter - 40)
                    
                    CircleRingSliderRow(
                        title: "应用图标大小",
                        value: $settings.circleRingIconSize,
                        range: 24...64,
                        step: 4,
                        valueFormatter: { "\(Int($0))px" }
                    )
                    
                    CircleRingSliderRow(
                        title: "图标圆角",
                        value: $settings.circleRingIconCornerRadius,
                        range: 0...20,
                        step: 2,
                        valueFormatter: { "\(Int($0))px" }
                    )
                    
                    Toggle("显示内圈线条", isOn: $settings.showInnerCircle)
                        .onChange(of: settings.showInnerCircle) { _ in
                            CircleRingController.shared.reloadCircleRing()
                        }
                        .help("显示内圈区域的边界线")
                    
                    if settings.showInnerCircle {
                        CircleRingSliderRow(
                            title: "内圈透明度",
                            value: $settings.innerCircleOpacity,
                            range: 0.1...1.0,
                            step: 0.1,
                            valueFormatter: { String(format: "%.1f", $0) },
                            onChange: {
                                CircleRingController.shared.reloadCircleRing()
                            }
                        )
                    }
                    
                    Toggle("显示中央指示器", isOn: $settings.showCenterIndicator)
                        .onChange(of: settings.showCenterIndicator) { _ in
                            CircleRingController.shared.reloadCircleRing()
                        }
                        .help("显示圆环中心的指示点")
                    
                    if settings.showCenterIndicator {
                        CircleRingSliderRow(
                            title: "圆心大小",
                            value: $settings.centerIndicatorSize,
                            range: 4...20,
                            step: 1,
                            valueFormatter: { "\(Int($0))px" },
                            onChange: {
                                CircleRingController.shared.reloadCircleRing()
                            }
                        )
                    }
                    
                    Toggle("内圆填充", isOn: $settings.showInnerCircleFill)
                        .onChange(of: settings.showInnerCircleFill) { _ in
                            CircleRingController.shared.reloadCircleRing()
                        }
                        .help("显示内圆区域的填充色")
                    
                    if settings.showInnerCircleFill {
                        CircleRingSliderRow(
                            title: "内圆透明度",
                            value: $settings.innerCircleFillOpacity,
                            range: 0.05...0.3,
                            step: 0.05,
                            valueFormatter: { String(format: "%.2f", $0) },
                            onChange: {
                                CircleRingController.shared.reloadCircleRing()
                            }
                        )
                    }
                } header: {
                    Text("圆环外观")
                }
                
                // 动画效果设置
                Section {
                    Toggle("启用扇区高亮", isOn: $settings.useSectorHighlight)
                        .onChange(of: settings.useSectorHighlight) { _ in
                            CircleRingController.shared.reloadCircleRing()
                        }
                    
                    if settings.useSectorHighlight {
                        CircleRingSliderRow(
                            title: "高亮不透明度",
                            value: $settings.sectorHighlightOpacity,
                            range: 0.05...0.4,
                            step: 0.05,
                            valueFormatter: { String(format: "%.2f", $0) },
                            onChange: {
                                CircleRingController.shared.reloadCircleRing()
                            }
                        )
                    }
                    
                    Toggle("启用扇区悬停音效", isOn: $settings.useSectorHoverSound)
                        .help("切换扇区时播放雷达扫描音效")
                    
                    if settings.useSectorHoverSound {
                        Picker("音效类型", selection: $settings.sectorHoverSoundType) {
                            Group {
                                Text("基础音效").foregroundColor(.secondary).font(.headline)
                                Text(SectorHoverSoundType.ping.description).tag(SectorHoverSoundType.ping)
                                Text(SectorHoverSoundType.tink.description).tag(SectorHoverSoundType.tink)
                                Text(SectorHoverSoundType.submarine.description).tag(SectorHoverSoundType.submarine)
                                Text(SectorHoverSoundType.bottle.description).tag(SectorHoverSoundType.bottle)
                            }
                            
                            Divider()
                            
                            Group {
                                Text("轻快音效").foregroundColor(.secondary).font(.headline)
                                Text(SectorHoverSoundType.click.description).tag(SectorHoverSoundType.click)
                                Text(SectorHoverSoundType.pop.description).tag(SectorHoverSoundType.pop)
                            }
                            
                            Divider()
                            
                            Group {
                                Text("动物音效").foregroundColor(.secondary).font(.headline)
                                Text(SectorHoverSoundType.frog.description).tag(SectorHoverSoundType.frog)
                                Text(SectorHoverSoundType.purr.description).tag(SectorHoverSoundType.purr)
                            }
                            
                            Divider()
                            
                            Group {
                                Text("其他音效").foregroundColor(.secondary).font(.headline)
                                Text(SectorHoverSoundType.basso.description).tag(SectorHoverSoundType.basso)
                                Text(SectorHoverSoundType.funk.description).tag(SectorHoverSoundType.funk)
                                Text(SectorHoverSoundType.glass.description).tag(SectorHoverSoundType.glass)
                                Text(SectorHoverSoundType.morse.description).tag(SectorHoverSoundType.morse)
                                Text(SectorHoverSoundType.sosumi.description).tag(SectorHoverSoundType.sosumi)
                            }
                        }
                        .onChange(of: settings.sectorHoverSoundType) { newValue in
                            // 播放示例音效
                            SoundPlayer.shared.playRadarSound()
                        }
                        .pickerStyle(.menu)
                        .help("选择扇区切换时播放的音效类型")
                    }
                    
                    Toggle("启用圆环展开动效", isOn: $settings.useCircleRingAnimation)
                        .onChange(of: settings.useCircleRingAnimation) { _ in
                            CircleRingController.shared.reloadCircleRing()
                        }
                        .help("显示圆环时播放展开动画效果")
                    
                    if settings.useCircleRingAnimation {
                        Picker("图标载入动效", selection: $settings.iconAppearAnimationType) {
                            Text(IconAppearAnimationType.none.description).tag(IconAppearAnimationType.none)
                            Text(IconAppearAnimationType.clockwise.description).tag(IconAppearAnimationType.clockwise)
                            Text(IconAppearAnimationType.counterClockwise.description).tag(IconAppearAnimationType.counterClockwise)
                        }
                        .onChange(of: settings.iconAppearAnimationType) { _ in
                            CircleRingController.shared.reloadCircleRing()
                        }
                        .help("图标显示时的动画效果")
                        
                        if settings.iconAppearAnimationType != .none {
                            CircleRingSliderRow(
                                title: "图标显示速度",
                                value: $settings.iconAppearSpeed,
                                range: 0.01...0.2,
                                step: 0.01,
                                valueFormatter: { value in
                                    let speed = 1 / value
                                    if speed >= 10 {
                                        return "快 (\(Int(speed))图标/秒)"
                                    } else {
                                        return "中等 (\(String(format: "%.1f", speed))图标/秒)"
                                    }
                                },
                                onChange: {
                                    CircleRingController.shared.reloadCircleRing()
                                }
                            )
                            .help("调整图标显示的速度，值越小显示越快")
                        }
                    }
                } header: {
                    Text("交互效果")
                }
                
                // 使用说明
                Section {
                    Text("1. 在任意位置按住 Option 键，圆环会出现在鼠标周围")
                    Text("2. 将鼠标移动到想要打开的应用图标上")
                    Text("3. 松开 Option 键即可打开对应的应用")
                } header: {
                    Text("使用说明")
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingAppSelector) {
            appSelectorView
        }
    }
    
    // 为特定扇区配置应用
    private func configureAppForSector(_ index: Int) {
        print("[CircleRingSettingsView] 配置扇区 \(index) 的应用")
        loadInstalledApps()
        
        // 重置状态
        selectedApps.removeAll()
        
        // 检查这个扇区是否已经配置了应用
        if index < settings.circleRingApps.count {
            let bundleId = settings.circleRingApps[index]
            if !bundleId.isEmpty {
                selectedApps.insert(bundleId)
                print("[CircleRingSettingsView] 扇区 \(index) 已配置应用: \(bundleId)")
            } else {
                print("[CircleRingSettingsView] 扇区 \(index) 未配置应用")
            }
        } else {
            print("[CircleRingSettingsView] 扇区 \(index) 超出当前配置范围")
        }
        
        // 设置选中的扇区索引并打开选择器
        selectedSectorIndex = index
        showingAppSelector = true
    }
    
    // 获取已配置的应用列表 - 确保返回正确数量的应用
    private func getConfiguredApps() -> [AppInfo] {
        let configuredApps = settings.circleRingApps
        let sectorCount = settings.circleRingSectorCount
        
        if configuredApps.isEmpty {
            let defaultApps = getDefaultApps()
            print("[CircleRingSettingsView] 使用默认应用列表: \(defaultApps.count) 个")
            return defaultApps
        }
        
        var apps: [AppInfo] = []
        
        // 确保应用映射到正确的扇区
        for i in 0..<sectorCount {
            if i < configuredApps.count && !configuredApps[i].isEmpty {
                if let appInfo = getAppInfo(for: configuredApps[i]) {
                    apps.append(appInfo)
                    print("[CircleRingSettingsView] 扇区 \(i): \(appInfo.name)")
                } else {
                    // 如果找不到应用，添加占位符
                    apps.append(AppInfo(bundleId: "placeholder.\(i)", name: "未找到", icon: NSImage(), url: nil))
                    print("[CircleRingSettingsView] 扇区 \(i): 应用未找到")
                }
            } else {
                // 如果该扇区没有配置，添加占位符
                apps.append(AppInfo(bundleId: "empty.\(i)", name: "未配置", icon: NSImage(), url: nil))
                print("[CircleRingSettingsView] 扇区 \(i): 未配置")
            }
        }
        
        return apps
    }
    
    // 获取默认应用列表
    private func getDefaultApps() -> [AppInfo] {
        let defaultBundleIds = [
            "com.apple.finder",
            "com.apple.Safari",
            "com.apple.mail",
            "com.apple.systempreferences",
            "com.apple.calculator"
        ]
        
        return defaultBundleIds.compactMap { getSystemAppInfo(for: $0) }
    }
    
    // 应用选择器视图
    private var appSelectorView: some View {
        VStack {
            HStack {
                if let index = selectedSectorIndex {
                    Text("选择扇区 \(index + 1) 应用")
                        .font(.headline)
                } else {
                    Text("选择圆环应用")
                        .font(.headline)
                }
                Spacer()
                Button("完成") {
                    let previousCount = settings.circleRingApps.count
                    
                    // 如果是为特定扇区选择应用
                    if let index = selectedSectorIndex {
                        // 更新现有应用
                        var updatedApps = settings.circleRingApps
                        
                        // 确保数组大小满足要求
                        while updatedApps.count <= index {
                            updatedApps.append("")
                        }
                        
                        // 更新特定扇区的应用
                        if let selectedApp = selectedApps.first {
                            updatedApps[index] = selectedApp
                        } else {
                            // 如果没有选择应用，则将该扇区设为空
                            updatedApps[index] = ""
                        }
                        
                        // 移除末尾的空字符串
                        while !updatedApps.isEmpty && updatedApps.last?.isEmpty == true {
                            updatedApps.removeLast()
                        }
                        
                        settings.circleRingApps = updatedApps
                    } else {
                        // 常规模式 - 更新整个应用列表
                        settings.circleRingApps = Array(selectedApps)
                    }
                    
                    print("[CircleRingSettingsView] 保存应用选择，从 \(previousCount) 个变为 \(settings.circleRingApps.count) 个")
                    
                    // 重置选择的扇区索引
                    selectedSectorIndex = nil
                    
                    // 重新加载圆环以应用新的应用列表
                    CircleRingController.shared.reloadCircleRing()
                    
                    showingAppSelector = false
                }
            }
            .padding()
            
            TextField("搜索应用", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            List {
                if let sectorIndex = selectedSectorIndex {
                    // 为特定扇区选择应用时，增加一个"不设置应用"选项
                    HStack {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.gray)
                        
                        Text("不设置应用")
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if selectedApps.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 清除该扇区的应用选择
                        selectedApps = []
                    }
                    .padding(.vertical, 4)
                }
                
                ForEach(filteredApps, id: \.bundleId) { app in
                    HStack {
                        Image(nsImage: app.icon)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .cornerRadius(4)
                        
                        Text(app.name)
                        
                        Spacer()
                        
                        if selectedSectorIndex != nil {
                            // 单选模式
                            if selectedApps.first == app.bundleId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        } else {
                            // 多选模式
                            if selectedApps.contains(app.bundleId) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let _ = selectedSectorIndex {
                            // 单选模式 - 为特定扇区选择应用
                            selectedApps = [app.bundleId]
                        } else {
                            // 多选模式 - 为整个圆环选择应用
                            if selectedApps.contains(app.bundleId) {
                                selectedApps.remove(app.bundleId)
                            } else {
                                selectedApps.insert(app.bundleId)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
        }
        .frame(width: 400, height: 500)
    }
    
    // 获取过滤后的应用列表
    private var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return installedApps
        } else {
            return installedApps.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // 加载已安装的应用
    private func loadInstalledApps() {
        // 避免重复加载
        if !installedApps.isEmpty {
            return
        }
        
        // 获取应用目录
        let appFolders = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications"
        ]
        
        var apps: [AppInfo] = []
        
        for folder in appFolders {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: folder) {
                for item in contents {
                    if item.hasSuffix(".app") {
                        let path = "\(folder)/\(item)"
                        let url = URL(fileURLWithPath: path)
                        
                        // 尝试获取应用信息
                        if let bundle = Bundle(url: url),
                           let bundleId = bundle.bundleIdentifier,
                           let name = bundle.infoDictionary?["CFBundleName"] as? String {
                            let icon = NSWorkspace.shared.icon(forFile: path)
                            apps.append(AppInfo(bundleId: bundleId, name: name, icon: icon, url: url))
                        }
                    }
                }
            }
        }
        
        // 添加特殊系统应用（某些系统应用可能没有bundleIdentifier）
        let specialSystemApps = [
            ("com.apple.finder", "访达", "Finder"),
            ("com.apple.systempreferences", "系统设置", "System Settings")
        ]
        
        for (bundleId, localizedName, englishName) in specialSystemApps {
            // 检查是否已经添加
            if !apps.contains(where: { $0.bundleId == bundleId }) {
                // 尝试获取应用URL
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                    let icon = NSWorkspace.shared.icon(forFile: url.path)
                    apps.append(AppInfo(bundleId: bundleId, name: localizedName, icon: icon, url: url))
                }
            }
        }
        
        // 按名称排序
        installedApps = apps.sorted { $0.name < $1.name }
    }
    
    // 根据Bundle ID获取应用信息
    private func getAppInfo(for bundleId: String) -> AppInfo? {
        if installedApps.isEmpty {
            loadInstalledApps()
        }
        
        return installedApps.first { $0.bundleId == bundleId } ?? getSystemAppInfo(for: bundleId)
    }
    
    // 获取系统应用信息
    private func getSystemAppInfo(for bundleId: String) -> AppInfo? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        
        let name = url.deletingPathExtension().lastPathComponent
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        return AppInfo(bundleId: bundleId, name: name, icon: icon, url: url)
    }
}

/**
 * 圆环扇区可视化组件
 * 用于在设置页面直观显示圆环扇区布局
 */
struct CircleRingSectorVisualizer: View {
    let sectorCount: Int
    let apps: [AppInfo]
    @Binding var selectedIndex: Int?
    let onSelectSector: (Int) -> Void
    @State private var hoveredIndex: Int? = nil
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var settings: AppSettings
    
    private let maxIconSize: CGFloat = 36
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景圆
                Circle()
                    .fill(colorScheme == .dark ? Color.black.opacity(0.1) : Color.gray.opacity(0.1))
                
                // 内圈
                if settings.showInnerCircle {
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(settings.innerCircleOpacity) : Color.black.opacity(settings.innerCircleOpacity * 0.5), lineWidth: 1)
                        .frame(width: geometry.size.height * 0.5, height: geometry.size.height * 0.5)
                }
                
                // 内圆填充
                if settings.showInnerCircleFill {
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(settings.innerCircleFillOpacity) : Color.black.opacity(settings.innerCircleFillOpacity * 0.5))
                        .frame(width: geometry.size.height * 0.5, height: geometry.size.height * 0.5)
                }
                
                // 中心点 - 只在设置中启用时显示
                if settings.showCenterIndicator {
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.2))
                        .frame(width: settings.centerIndicatorSize * 0.75, height: settings.centerIndicatorSize * 0.75)
                }
                
                // 绘制扇区 - 每个扇区拥有独立的点击事件
                ForEach(0..<sectorCount, id: \.self) { index in
                    Button(action: {
                        print("[CircleRingSectorVisualizer] 点击扇区 \(index)")
                        onSelectSector(index)
                    }) {
                        sectorView(for: index, in: geometry)
                            .contentShape(SectorShapePreview(
                                center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                                radius: min(geometry.size.width, geometry.size.height) * 0.45,
                                innerRadius: min(geometry.size.width, geometry.size.height) * 0.25,
                                startAngle: startAngle(for: index),
                                endAngle: endAngle(for: index),
                                sectorIndex: index
                            ))
                    }
                    .buttonStyle(PlainButtonStyle()) // 使用PlainButtonStyle避免默认按钮样式
                }
                
                // 绘制应用图标
                ForEach(0..<min(sectorCount, apps.count), id: \.self) { index in
                    appIconView(for: index, in: geometry)
                }
                
                // 扇区索引标记
                ForEach(0..<sectorCount, id: \.self) { index in
                    sectorIndexLabel(for: index, in: geometry)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onDisappear {
            // 确保在视图消失时清除选中状态
            selectedIndex = nil
        }
    }
    
    // 创建扇区视图
    private func sectorView(for index: Int, in geometry: GeometryProxy) -> some View {
        let isHovered = hoveredIndex == index
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) * 0.45
        let innerRadius = min(geometry.size.width, geometry.size.height) * 0.25
        
        return SectorShapePreview(
            center: center,
            radius: radius,
            innerRadius: innerRadius,
            startAngle: startAngle(for: index),
            endAngle: endAngle(for: index),
            sectorIndex: index
        )
        .fill(isHovered ? 
             (colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)) :
             Color.clear)
        .onHover { hovering in
            if hovering {
                hoveredIndex = index
                print("[CircleRingSectorVisualizer] 悬停扇区 \(index)")
            } else if hoveredIndex == index {
                hoveredIndex = nil
            }
        }
    }
    
    // 扇区索引标签
    private func sectorIndexLabel(for index: Int, in geometry: GeometryProxy) -> some View {
        let angleSlice = 2 * .pi / CGFloat(sectorCount)
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        let labelRadius = min(geometry.size.width, geometry.size.height) * 0.42
        
        // 计算扇区中心角度
        let angle = angleSlice * (CGFloat(index) + 0.5) - (.pi / 2)
        
        // 计算位置
        let x = centerX + labelRadius * cos(angle)
        let y = centerY + labelRadius * sin(angle)
        
        return Text("\(index + 1)")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
            .position(x: x, y: y)
    }
    
    // 创建应用图标视图
    private func appIconView(for index: Int, in geometry: GeometryProxy) -> some View {
        if index >= apps.count {
            return AnyView(EmptyView())
        }
        
        let app = apps[index]
        let position = positionForIndex(index, in: geometry)
        let isHovered = hoveredIndex == index
        
        return AnyView(
            ZStack {
                Circle()
                    .fill(isHovered ? 
                         (colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.1)) : 
                         Color.clear)
                    .frame(width: maxIconSize + 8, height: maxIconSize + 8)
                
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: maxIconSize, height: maxIconSize)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .position(position)
        )
    }
    
    // 计算扇区起始角度
    private func startAngle(for index: Int) -> CGFloat {
        let angleSlice = 2 * .pi / CGFloat(sectorCount)
        // 从正上方开始，顺时针旋转
        return angleSlice * CGFloat(index) - (.pi / 2)
    }
    
    // 计算扇区结束角度
    private func endAngle(for index: Int) -> CGFloat {
        let angleSlice = 2 * .pi / CGFloat(sectorCount)
        // 从正上方开始，顺时针旋转
        return angleSlice * CGFloat(index + 1) - (.pi / 2)
    }
    
    // 计算图标位置
    private func positionForIndex(_ index: Int, in geometry: GeometryProxy) -> CGPoint {
        let angleSlice = 2 * .pi / CGFloat(sectorCount)
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        let iconRadius = min(geometry.size.width, geometry.size.height) * 0.35
        
        // 计算扇区中心角度 - 从正上方开始，顺时针旋转
        let angle = angleSlice * (CGFloat(index) + 0.5) - (.pi / 2)
        
        // 计算位置
        let x = centerX + iconRadius * cos(angle)
        let y = centerY + iconRadius * sin(angle)
        
        return CGPoint(x: x, y: y)
    }
}

/**
 * 扇区形状预览
 * 专门用于设置页面的扇区可视化
 */
struct SectorShapePreview: Shape {
    let center: CGPoint
    let radius: CGFloat
    let innerRadius: CGFloat
    let startAngle: CGFloat
    let endAngle: CGFloat
    let sectorIndex: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 外弧起点
        let startPointOuter = CGPoint(
            x: center.x + radius * cos(startAngle),
            y: center.y + radius * sin(startAngle)
        )
        
        // 内弧起点
        let startPointInner = CGPoint(
            x: center.x + innerRadius * cos(startAngle),
            y: center.y + innerRadius * sin(startAngle)
        )
        
        // 外弧终点
        let endPointOuter = CGPoint(
            x: center.x + radius * cos(endAngle),
            y: center.y + radius * sin(endAngle)
        )
        
        // 内弧终点
        let endPointInner = CGPoint(
            x: center.x + innerRadius * cos(endAngle),
            y: center.y + innerRadius * sin(endAngle)
        )
        
        // 绘制路径
        path.move(to: startPointOuter)
        
        // 外弧
        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(radians: Double(startAngle)),
            endAngle: Angle(radians: Double(endAngle)),
            clockwise: false
        )
        
        // 连接到内弧终点
        path.addLine(to: endPointInner)
        
        // 内弧
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: Angle(radians: Double(endAngle)),
            endAngle: Angle(radians: Double(startAngle)),
            clockwise: true
        )
        
        // 闭合路径
        path.closeSubpath()
        
        return path
    }
}

/**
 * 圆环模式滑块行视图
 */
struct CircleRingSliderRow: View {
    let title: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let step: CGFloat
    var valueFormatter: ((CGFloat) -> String)?
    var onChange: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(valueFormatter?(value) ?? "\(Int(value))")
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range, step: step)
                .onChange(of: value) { _ in
                    onChange?()
                }
        }
    }
} 