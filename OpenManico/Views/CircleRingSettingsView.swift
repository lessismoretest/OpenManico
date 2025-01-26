import SwiftUI

/**
 * 图片缓存类 - 用于缓存预定义图片和自定义图片
 */
class ImageCache {
    static let shared = ImageCache()
    private var cache: [String: NSImage] = [:]
    
    // 获取图片，如果缓存中有则直接返回，否则返回nil
    func getImage(path: String) -> NSImage? {
        return cache[path]
    }
    
    // 设置图片缓存
    func setImage(path: String, image: NSImage) {
        cache[path] = image
    }
    
    // 清除所有缓存
    func clearCache() {
        cache.removeAll()
    }
    
    // 预加载应用需要的图片
    func preloadCircleRingImage(settings: AppSettings) {
        if !settings.customCircleImagePath.isEmpty && settings.showCustomImageInCircle {
            _ = loadImageFromPath(settings.customCircleImagePath)
        }
    }
    
    // 从路径加载图片，如果缓存中有则直接返回，否则加载并缓存
    func loadImageFromPath(_ path: String) -> NSImage? {
        // 检查缓存
        if let cachedImage = cache[path] {
            print("[ImageCache] 命中缓存: \(path)")
            return cachedImage
        }
        
        // 从磁盘加载图片
        if let image = NSImage(contentsOfFile: path) {
            print("[ImageCache] 从磁盘加载: \(path)")
            // 缓存图片
            cache[path] = image
            return image
        }
        
        print("[ImageCache] 无法加载图片: \(path)")
        return nil
    }
}

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
    @State private var predefinedImages: [PredefinedImage] = []
    @State private var isLoadingImages: Bool = false
    
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
            } header: {
                Text("基础设置")
            }
            
            if settings.enableCircleRingMode {
                // 长按时间间隔设置
                Section {
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
                    Text("触发设置")
                }
                
                // 应用选择器
                Section {
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
                    Text("未配置应用的扇区将使用系统默认应用（访达、Safari等）")
                        .font(.caption)
                }
                
                // 圆环外观
                Section {
                    // 基础外观设置
                    Group {
                        Text("基础外观")
                            .font(.headline)
                            .padding(.bottom, 4)
                            
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
                    }
                    
                    Divider()
                        .padding(.vertical, 6)
                        
                    // 图标设置
                    Group {
                        Text("图标外观")
                            .font(.headline)
                            .padding(.bottom, 4)
                            
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
                        
                        Toggle("显示应用名称", isOn: $settings.showAppNameInCircleRing)
                            .onChange(of: settings.showAppNameInCircleRing) { _ in
                                CircleRingController.shared.reloadCircleRing()
                            }
                            .help("悬停图标时显示应用名称")
                    }
                    
                    Divider()
                        .padding(.vertical, 6)
                    
                    // 内圈设置
                    Group {
                        Text("内圈设置")
                            .font(.headline)
                            .padding(.bottom, 4)
                            
                        Toggle("显示内圈线条", isOn: $settings.showInnerCircle)
                            .onChange(of: settings.showInnerCircle) { _ in
                                CircleRingController.shared.reloadCircleRing()
                            }
                            .help("显示内圈区域的边界线")
                        
                        if settings.showInnerCircle {
                            CircleRingSliderRow(
                                title: "内圈线条透明度",
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
                                title: "中央指示器大小",
                                value: $settings.centerIndicatorSize,
                                range: 4...20,
                                step: 1,
                                valueFormatter: { "\(Int($0))px" },
                                onChange: {
                                    CircleRingController.shared.reloadCircleRing()
                                }
                            )
                        }
                        
                        Toggle("内圈填充", isOn: $settings.showInnerCircleFill)
                            .onChange(of: settings.showInnerCircleFill) { _ in
                                CircleRingController.shared.reloadCircleRing()
                            }
                            .help("显示内圆区域的填充色")
                        
                        if settings.showInnerCircleFill {
                            CircleRingSliderRow(
                                title: "内圈填充透明度",
                                value: $settings.innerCircleFillOpacity,
                                range: 0.05...0.3,
                                step: 0.05,
                                valueFormatter: { String(format: "%.2f", $0) },
                                onChange: {
                                    CircleRingController.shared.reloadCircleRing()
                                }
                            )
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 6)
                        
                    // 自定义图片设置
                    Group {
                        Text("自定义图片")
                            .font(.headline)
                            .padding(.bottom, 4)
                            
                        // 内圆自定义图片设置
                        Toggle("显示自定义图片", isOn: $settings.showCustomImageInCircle)
                            .onChange(of: settings.showCustomImageInCircle) { _ in
                                CircleRingController.shared.reloadCircleRing()
                            }
                            .help("在内圆中显示自定义图片")
                        
                        if settings.showCustomImageInCircle {
                            HStack {
                                Text("自定义图片")
                                Spacer()
                                if !settings.customCircleImagePath.isEmpty {
                                    Text("已选择图片").foregroundColor(.secondary).font(.caption)
                                    Spacer().frame(width: 8)
                                }
                                Button("选择图片") {
                                    selectCustomImage()
                                }
                                if !settings.customCircleImagePath.isEmpty {
                                    Button("清除") {
                                        settings.customCircleImagePath = ""
                                        CircleRingController.shared.reloadCircleRing()
                                    }
                                    .foregroundColor(.red)
                                }
                            }
                            
                            // 添加预定义图片选择器
                            VStack(alignment: .leading) {
                                Text("预定义图片")
                                    .font(.subheadline)
                                    .padding(.top, 8)
                                    
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(predefinedImages, id: \.name) { imageInfo in
                                            VStack {
                                                if let image = imageInfo.image {
                                                    Image(nsImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 60, height: 60)
                                                        .clipShape(Circle())
                                                        .overlay(Circle().stroke(
                                                            settings.customCircleImagePath == imageInfo.path ? Color.blue : Color.clear, lineWidth: 2))
                                                        .onTapGesture {
                                                            // 使用弱引用，避免闭包捕获self
                                                            let imagePathToSet = imageInfo.path
                                                            weak var weakSettings = settings
                                                            
                                                            // 异步更新设置
                                                            DispatchQueue.main.async {
                                                                weakSettings?.customCircleImagePath = imagePathToSet
                                                                
                                                                // 异步重新加载圆环
                                                                DispatchQueue.global(qos: .userInitiated).async {
                                                                    CircleRingController.shared.reloadCircleRing()
                                                                }
                                                            }
                                                        }
                                                    
                                                    Text(imageInfo.name)
                                                        .font(.caption)
                                                        .lineLimit(1)
                                                        .truncationMode(.middle)
                                                        .frame(width: 70)
                                                } else {
                                                    RoundedRectangle(cornerRadius: 30)
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(width: 60, height: 60)
                                                    
                                                    Text("加载失败")
                                                        .font(.caption)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                Text("所有素材来自网络，侵权请联系开发者删除。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                            
                            CircleRingSliderRow(
                                title: "图片大小",
                                value: $settings.customCircleImageScale,
                                range: 0.1...5.0,
                                step: 0.05,
                                valueFormatter: { String(format: "%.2f", $0) },
                                onChange: {
                                    CircleRingController.shared.reloadCircleRing()
                                }
                            )
                            
                            CircleRingSliderRow(
                                title: "图片透明度",
                                value: $settings.customCircleImageOpacity,
                                range: 0.1...1.0,
                                step: 0.1,
                                valueFormatter: { String(format: "%.1f", $0) },
                                onChange: {
                                    CircleRingController.shared.reloadCircleRing()
                                }
                            )
                        }
                    }
                } header: {
                    Text("圆环外观")
                }
                
                // 动画效果设置
                Section {
                    // 视觉反馈分组
                    Group {
                        Text("视觉反馈")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        Toggle("启用扇区高亮", isOn: $settings.useSectorHighlight)
                            .onChange(of: settings.useSectorHighlight) { _ in
                                CircleRingController.shared.reloadCircleRing()
                            }
                        
                        if settings.useSectorHighlight {
                            CircleRingSliderRow(
                                title: "高亮不透明度",
                                value: $settings.sectorHighlightOpacity,
                                range: 0.05...1.0,
                                step: 0.05,
                                valueFormatter: { String(format: "%.2f", $0) },
                                onChange: {
                                    CircleRingController.shared.reloadCircleRing()
                                }
                            )
                            
                            Picker("高亮颜色", selection: $settings.sectorHighlightColor) {
                                Text("自动").tag(SectorHighlightColorType.auto)
                                Text("白色").tag(SectorHighlightColorType.white)
                                Text("黑色").tag(SectorHighlightColorType.black)
                                Text("红色").tag(SectorHighlightColorType.red)
                                Text("蓝色").tag(SectorHighlightColorType.blue)
                                Text("绿色").tag(SectorHighlightColorType.green)
                                Text("黄色").tag(SectorHighlightColorType.yellow)
                                Text("紫色").tag(SectorHighlightColorType.purple)
                                Text("橙色").tag(SectorHighlightColorType.orange)
                            }
                            .onChange(of: settings.sectorHighlightColor) { _ in
                                CircleRingController.shared.reloadCircleRing()
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 6)
                    
                    // 听觉反馈分组
                    Group {
                        Text("听觉反馈")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        Toggle("启用扇区悬停音效", isOn: $settings.useSectorHoverSound)
                            .onChange(of: settings.useSectorHoverSound) { _ in
                                settings.saveSettings()
                            }
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
                                // 保存设置
                                settings.saveSettings()
                            }
                            .pickerStyle(.menu)
                            .help("选择扇区切换时播放的音效类型")
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Toggle("启用圆环启动音效", isOn: $settings.useCircleRingStartupSound)
                            .onChange(of: settings.useCircleRingStartupSound) { _ in
                                settings.saveSettings()
                            }
                            .help("显示圆环时播放启动音效")
                        
                        if settings.useCircleRingStartupSound {
                            Picker("启动音效", selection: $settings.circleRingStartupSoundType) {
                                Group {
                                    Text("基础音效").foregroundColor(.secondary).font(.headline)
                                    Text(CircleRingStartupSoundType.hero.description).tag(CircleRingStartupSoundType.hero)
                                    Text(CircleRingStartupSoundType.magic.description).tag(CircleRingStartupSoundType.magic)
                                    Text(CircleRingStartupSoundType.sparkle.description).tag(CircleRingStartupSoundType.sparkle)
                                }
                                
                                Divider()
                                
                                Group {
                                    Text("自然音效").foregroundColor(.secondary).font(.headline)
                                    Text(CircleRingStartupSoundType.chime.description).tag(CircleRingStartupSoundType.chime)
                                    Text(CircleRingStartupSoundType.bell.description).tag(CircleRingStartupSoundType.bell)
                                    Text(CircleRingStartupSoundType.crystal.description).tag(CircleRingStartupSoundType.crystal)
                                }
                                
                                Divider()
                                
                                Group {
                                    Text("奇幻音效").foregroundColor(.secondary).font(.headline)
                                    Text(CircleRingStartupSoundType.cosmic.description).tag(CircleRingStartupSoundType.cosmic)
                                    Text(CircleRingStartupSoundType.fairy.description).tag(CircleRingStartupSoundType.fairy)
                                    Text(CircleRingStartupSoundType.mystic.description).tag(CircleRingStartupSoundType.mystic)
                                }
                            }
                            .onChange(of: settings.circleRingStartupSoundType) { newValue in
                                // 播放示例音效
                                SoundPlayer.shared.playStartupSound()
                                // 保存设置
                                settings.saveSettings()
                            }
                            .pickerStyle(.menu)
                            .help("选择圆环启动时播放的音效类型")
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 6)
                    
                    // 触觉反馈分组
                    Group {
                        Text("触觉反馈")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        // 添加震动反馈设置
                        Toggle("启用扇区悬停触控板震动", isOn: $settings.useSectorHoverHaptic)
                            .onChange(of: settings.useSectorHoverHaptic) { _ in
                                settings.saveSettings()
                            }
                            .help("切换扇区时触发触控板震动反馈(需要Force Touch触控板)")
                        
                        if settings.useSectorHoverHaptic {
                            Picker("震动强度", selection: $settings.sectorHoverHapticStrength) {
                                Text(HapticFeedbackStrength.light.description).tag(HapticFeedbackStrength.light)
                                Text(HapticFeedbackStrength.medium.description).tag(HapticFeedbackStrength.medium)
                                Text(HapticFeedbackStrength.strong.description).tag(HapticFeedbackStrength.strong)
                            }
                            .onChange(of: settings.sectorHoverHapticStrength) { newValue in
                                // 播放示例震动
                                HapticFeedbackManager.shared.playHapticFeedback(strength: newValue)
                                // 保存设置
                                settings.saveSettings()
                            }
                            .pickerStyle(.menu)
                            .help("选择扇区切换时的触控板震动强度，需要Force Touch触控板支持")
                            
                            if HapticFeedbackManager.shared.isHapticFeedbackSupported {
                                Text("您的设备支持触控板震动")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            } else {
                                Text("注意：您的设备可能不支持Force Touch触控板震动")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 6)
                    
                    // 动画效果分组
                    Group {
                        Text("动画效果")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        Toggle("启用圆环展开动效", isOn: $settings.useCircleRingAnimation)
                            .onChange(of: settings.useCircleRingAnimation) { _ in
                                CircleRingController.shared.reloadCircleRing()
                            }
                            .help("显示圆环时播放展开动画效果")
                        
                        if settings.useCircleRingAnimation {
                            CircleRingSliderRow(
                                title: "展开动效速度",
                                value: $settings.circleRingAnimationSpeed,
                                range: 0.1...1.0,
                                step: 0.1,
                                valueFormatter: { value in
                                    let speed = 1 / value
                                    if speed >= 8 {
                                        return "快 (\(String(format: "%.1f", speed))x)"
                                    } else if speed >= 4 {
                                        return "中等 (\(String(format: "%.1f", speed))x)"
                                    } else {
                                        return "慢 (\(String(format: "%.1f", speed))x)"
                                    }
                                },
                                onChange: {
                                    CircleRingController.shared.reloadCircleRing()
                                }
                            )
                            .help("调整圆环展开的速度，值越小展开越快")
                            
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
                    }
                } header: {
                    Text("交互效果")
                }
                
                // 交互行为设置
                Group {
                    Text("交互行为")
                        .font(.headline)
                        .padding(.bottom, 4)
                        
                    Toggle("点击当前运行应用切换到上一个应用", isOn: $settings.clickCircleAppToToggle)
                        .onChange(of: settings.clickCircleAppToToggle) { _ in
                            settings.saveSettings()
                        }
                        .help("启用后，点击圆环中已在运行的当前应用时会切换回上一个使用的应用")
                        
                    Text("类似于 Command+Tab 的功能，可快速在两个应用之间切换")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
                
                Divider()
                    .padding(.vertical, 6)
                
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
        .onAppear {
            // 预加载当前设置中的自定义图片
            ImageCache.shared.preloadCircleRingImage(settings: settings)
            
            // 加载预定义图片
            if predefinedImages.isEmpty && !isLoadingImages {
                isLoadingImages = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let images = loadPredefinedImages()
                    DispatchQueue.main.async {
                        predefinedImages = images
                        isLoadingImages = false
                    }
                }
            }
        }
        .onDisappear {
            // 当前的设置页面消失时，清理不必要的图片缓存
            // 但保留当前选中的图片在缓存中
            if !settings.customCircleImagePath.isEmpty {
                let currentImagePath = settings.customCircleImagePath
                let cachedImage = ImageCache.shared.getImage(path: currentImagePath)
                
                // 清除所有缓存
                ImageCache.shared.clearCache()
                
                // 只保留当前使用的图片
                if let image = cachedImage {
                    ImageCache.shared.setImage(path: currentImagePath, image: image)
                }
            } else {
                // 如果没有选中的图片，则清除所有缓存
                ImageCache.shared.clearCache()
            }
        }
        .padding(.vertical, 8)
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
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
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
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        } else {
                            // 多选模式
                            if selectedApps.contains(app.bundleId) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
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
    
    // 创建选择自定义图片的对话框
    private func selectCustomImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["jpg", "jpeg", "png", "gif", "webp", "tiff", "heic"]
        panel.title = "选择圆环显示图片"
        
        // 获取对settings的弱引用，避免闭包捕获self
        weak var weakSettings = settings
        
        panel.begin { response in
            if response == .OK, let url = panel.urls.first {
                // 获取选择的文件URL和路径
                let path = url.path
                print("[CircleRingSettingsView] 用户选择了图片: \(path)")
                
                // 预先加载图片并缓存
                if let image = NSImage(contentsOfFile: path) {
                    ImageCache.shared.setImage(path: path, image: image)
                }
                
                // 在主线程更新UI
                DispatchQueue.main.async {
                    weakSettings?.customCircleImagePath = path
                    
                    // 异步重新加载圆环以应用新的图片
                    DispatchQueue.global(qos: .userInitiated).async {
                        CircleRingController.shared.reloadCircleRing()
                    }
                }
            }
        }
    }
    
    // 加载预定义图片
    private func loadPredefinedImages() -> [PredefinedImage] {
        let fileManager = FileManager.default
        var images: [PredefinedImage] = []
        
        // 获取图片目录路径
        guard let imageDirPath = getCirclePicturesPath() else {
            print("[CircleRingSettingsView] 无法找到预定义图片目录")
            return []
        }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(atPath: imageDirPath)
            
            for fileName in fileURLs.filter({ $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".gif") }) {
                let fullPath = imageDirPath + "/" + fileName
                
                // 处理文件名 - 保留原名但清理长ID
                let nameComponents = fileName.components(separatedBy: ".")
                var name = nameComponents.first ?? fileName
                
                // 如果是哈希值文件名，提供更友好的名称
                if name.count > 20 && name.replacingOccurrences(of: "[a-f0-9]", with: "", options: .regularExpression).isEmpty {
                    // 根据文件类型提供友好名称
                    if fileName.hasSuffix(".gif") {
                        name = "动态GIF_\(images.count + 1)"
                    } else if fileName.hasSuffix(".png") {
                        name = "图片_\(images.count + 1)"
                    } else {
                        name = "图片_\(images.count + 1)"
                    }
                }
                
                // 使用缓存加载图片
                if let image = ImageCache.shared.loadImageFromPath(fullPath) {
                    images.append(PredefinedImage(name: name, path: fullPath, image: image))
                    print("[CircleRingSettingsView] 成功加载预定义图片: \(name)")
                } else {
                    print("[CircleRingSettingsView] 无法加载图片: \(fullPath)")
                }
            }
            
            print("[CircleRingSettingsView] 总共加载了 \(images.count) 个预定义图片")
        } catch {
            print("[CircleRingSettingsView] 读取预定义图片文件夹失败: \(error)")
        }
        
        return images
    }
    
    // 获取预定义图片路径
    private func getCirclePicturesPath() -> String? {
        let fileManager = FileManager.default
        
        // 尝试多种可能的路径
        let possiblePaths = [
            // 优先尝试开发环境中的直接路径
            "/Users/lessismore/Desktop/Inbox/XcodeWithCursor/OpenManico/OpenManico/Views/circlepictures",
            
            // 然后尝试应用支持目录
            try? fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("OpenManico/circlepictures").path,
            
            // 最后尝试Bundle路径
            Bundle.main.resourcePath?.appending("/Views/circlepictures"),
            Bundle.main.resourcePath?.appending("/circlepictures")
        ].compactMap { $0 }
        
        // 检查哪个路径存在并包含图片
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: path)
                    let imageFiles = contents.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".gif") }
                    
                    if !imageFiles.isEmpty {
                        print("[CircleRingSettingsView] 找到预定义图片路径: \(path) 包含 \(imageFiles.count) 个图片")
                        
                        // 发现了有效源路径，尝试复制到应用支持目录以便今后使用
                        if let appSupportURL = try? fileManager.url(
                            for: .applicationSupportDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: true
                        ).appendingPathComponent("OpenManico/circlepictures") {
                            
                            let appSupportPath = appSupportURL.path
                            
                            // 确保目录存在
                            if !fileManager.fileExists(atPath: appSupportPath) {
                                try? fileManager.createDirectory(atPath: appSupportPath, withIntermediateDirectories: true)
                            }
                            
                            // 只有当源路径不是应用支持目录时才复制
                            if path != appSupportPath {
                                copyPredefinedImagesToCacheDirectory(sourcePath: path, targetPath: appSupportPath)
                            }
                        }
                        
                        return path
                    }
                } catch {
                    print("[CircleRingSettingsView] 检查路径内容失败: \(error)")
                }
            }
        }
        
        return nil
    }
    
    // 复制预定义图片到缓存目录
    private func copyPredefinedImagesToCacheDirectory(sourcePath: String? = nil, targetPath: String) {
        let fileManager = FileManager.default
        
        // 如果未提供源路径，尝试所有可能的路径
        let possibleSourcePaths: [String]
        if let sourcePath = sourcePath {
            possibleSourcePaths = [sourcePath]
        } else {
            possibleSourcePaths = [
                "/Users/lessismore/Desktop/Inbox/XcodeWithCursor/OpenManico/OpenManico/Views/circlepictures",  // 直接开发路径
                Bundle.main.resourcePath?.appending("/Views/circlepictures"),  // Bundle内路径
                Bundle.main.resourcePath?.appending("/circlepictures")         // Bundle根目录
            ].compactMap { $0 }
        }
        
        // 尝试每个可能的源路径
        for sourcePath in possibleSourcePaths {
            if fileManager.fileExists(atPath: sourcePath) {
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: sourcePath)
                    let imageFiles = contents.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".gif") }
                    
                    if !imageFiles.isEmpty {
                        print("[CircleRingSettingsView] 正在从 \(sourcePath) 复制 \(imageFiles.count) 个图片到 \(targetPath)")
                        
                        // 复制每个图片文件
                        for fileName in imageFiles {
                            let sourceFile = sourcePath + "/" + fileName
                            let targetFile = targetPath + "/" + fileName
                            
                            if !fileManager.fileExists(atPath: targetFile) {
                                try fileManager.copyItem(atPath: sourceFile, toPath: targetFile)
                                print("[CircleRingSettingsView] 已复制: \(fileName)")
                            }
                        }
                        
                        // 找到并复制了图片，不需要继续尝试其他源路径
                        break
                    }
                } catch {
                    print("[CircleRingSettingsView] 复制文件失败: \(error)")
                }
            }
        }
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
    
    // 添加拖放相关状态
    @State private var draggedIndex: Int? = nil
    @State private var isDragging: Bool = false
    @State private var dragStartPosition: CGPoint = .zero
    @State private var currentDragPosition: CGPoint = .zero
    @State private var showDragHint: Bool = false
    
    private let maxIconSize: CGFloat = 36
    
    var body: some View {
        VStack {
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
                        .allowsHitTesting(!isDragging) // 拖拽时禁用扇区点击
                    }
                    
                    // 绘制应用图标
                    ForEach(0..<min(sectorCount, apps.count), id: \.self) { index in
                        appIconView(for: index, in: geometry)
                    }
                    
                    // 扇区索引标记
                    ForEach(0..<sectorCount, id: \.self) { index in
                        sectorIndexLabel(for: index, in: geometry)
                    }
                    
                    // 绘制正在拖拽的图标
                    if isDragging, let draggedIndex = draggedIndex, draggedIndex < apps.count {
                        draggedIconView(for: draggedIndex, in: geometry)
                            .position(currentDragPosition)
                            .transition(.scale)
                    }
                    
                    // 目标指示器 - 显示拖拽目标位置
                    if isDragging, let hoveredIndex = hoveredIndex, hoveredIndex != draggedIndex {
                        targetIndicatorView(for: hoveredIndex, in: geometry)
                            .transition(.opacity)
                    }
                    
                    // 操作提示信息浮层
                    if showDragHint {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("拖拽图标调整位置 • 点击扇区选择应用")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.black.opacity(0.6))
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    .padding(.bottom, 10)
                                    .padding(.trailing, 10)
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { gesture in
                            handleDrag(gesture: gesture, in: geometry)
                        }
                        .onEnded { gesture in
                            handleDragEnd(gesture: gesture, in: geometry)
                        }
                )
                .onAppear {
                    // 在视图显示后稍作延迟显示提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showDragHint = true
                        }
                        
                        // 5秒后自动隐藏提示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showDragHint = false
                            }
                        }
                    }
                }
                .onDisappear {
                    // 确保在视图消失时清除选中状态
                    selectedIndex = nil
                    showDragHint = false
                }
            }
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
        let isDraggingThisIcon = draggedIndex == index && isDragging
        
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
            .opacity(isDraggingThisIcon ? 0.3 : 1) // 拖拽时原位置图标透明度降低
            .scaleEffect(isDraggingThisIcon ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.2), value: isDraggingThisIcon)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        if !isDragging {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                draggedIndex = index
                                isDragging = true
                                dragStartPosition = position
                                currentDragPosition = CGPoint(
                                    x: position.x + gesture.translation.width,
                                    y: position.y + gesture.translation.height
                                )
                            }
                            // 触觉反馈 - 如果支持的话
                            if HapticFeedbackManager.shared.isHapticFeedbackSupported {
                                HapticFeedbackManager.shared.playHapticFeedback(strength: .light)
                            }
                            print("[CircleRingSectorVisualizer] 开始拖拽图标 \(index)")
                        }
                    }
            )
        )
    }
    
    // 创建拖拽中的图标视图
    private func draggedIconView(for index: Int, in geometry: GeometryProxy) -> some View {
        if index >= apps.count {
            return AnyView(EmptyView())
        }
        
        let app = apps[index]
        
        return AnyView(
            ZStack {
                // 背景圆形
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                    .frame(width: maxIconSize + 16, height: maxIconSize + 16)
                
                // 图标
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: maxIconSize + 6, height: maxIconSize + 6)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .scaleEffect(1.15)
            .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentDragPosition)
        )
    }
    
    // 处理拖拽过程
    private func handleDrag(gesture: DragGesture.Value, in geometry: GeometryProxy) {
        guard let draggedIndex = draggedIndex, isDragging else { return }
        
        // 更新拖拽位置
        withAnimation(.interactiveSpring()) {
            currentDragPosition = CGPoint(
                x: dragStartPosition.x + gesture.translation.width,
                y: dragStartPosition.y + gesture.translation.height
            )
        }
        
        // 查找最近的扇区
        var closestIndex = draggedIndex
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for i in 0..<sectorCount {
            if i == draggedIndex { continue }
            
            let targetPosition = positionForIndex(i, in: geometry)
            let distance = sqrt(
                pow(currentDragPosition.x - targetPosition.x, 2) +
                pow(currentDragPosition.y - targetPosition.y, 2)
            )
            
            if distance < minDistance {
                minDistance = distance
                closestIndex = i
            }
        }
        
        // 如果拖拽到了较近的扇区，高亮该扇区
        if minDistance < maxIconSize * 1.5 && closestIndex != draggedIndex {
            if hoveredIndex != closestIndex {
                // 切换扇区时添加触觉反馈
                if HapticFeedbackManager.shared.isHapticFeedbackSupported {
                    HapticFeedbackManager.shared.playHapticFeedback(strength: .light)
                }
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    hoveredIndex = closestIndex
                }
            }
        } else if hoveredIndex != nil && hoveredIndex != draggedIndex {
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredIndex = nil
            }
        }
    }
    
    // 处理拖拽结束
    private func handleDragEnd(gesture: DragGesture.Value, in geometry: GeometryProxy) {
        guard let draggedIndex = draggedIndex, isDragging else { return }
        
        // 查找最近的扇区
        var closestIndex = draggedIndex
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for i in 0..<sectorCount {
            if i == draggedIndex { continue }
            
            let targetPosition = positionForIndex(i, in: geometry)
            let distance = sqrt(
                pow(currentDragPosition.x - targetPosition.x, 2) +
                pow(currentDragPosition.y - targetPosition.y, 2)
            )
            
            if distance < minDistance {
                minDistance = distance
                closestIndex = i
            }
        }
        
        // 如果拖拽到了不同的扇区，交换应用位置
        if closestIndex != draggedIndex && minDistance < maxIconSize * 2 {
            swapApps(draggedIndex, closestIndex)
            
            // 强触觉反馈表示交换成功
            if HapticFeedbackManager.shared.isHapticFeedbackSupported {
                HapticFeedbackManager.shared.playHapticFeedback(strength: .medium)
            }
            
            print("[CircleRingSectorVisualizer] 交换图标位置: \(draggedIndex) -> \(closestIndex)")
        }
        
        // 使用动画重置拖拽状态
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.draggedIndex = nil
            self.isDragging = false
            self.hoveredIndex = nil
        }
    }
    
    // 交换两个应用位置
    private func swapApps(_ index1: Int, _ index2: Int) {
        // 确保我们正在处理的是有效的索引
        guard index1 < sectorCount && index2 < sectorCount && index1 != index2 else {
            print("[CircleRingSectorVisualizer] 交换应用失败：无效的索引 \(index1), \(index2)")
            return
        }
        
        // 获取当前应用列表配置
        var circleRingApps = settings.circleRingApps
        
        // 如果是空数组且正在使用默认应用，则首先创建一个完整的默认应用列表
        if circleRingApps.isEmpty {
            // 获取默认应用的 bundleIds
            let defaultApps = apps.prefix(sectorCount).map { $0.bundleId }
            // 过滤掉占位符应用
            circleRingApps = defaultApps.filter { !$0.hasPrefix("empty.") && !$0.hasPrefix("placeholder.") }
            print("[CircleRingSectorVisualizer] 从默认应用创建初始配置: \(circleRingApps)")
        }
        
        // 确保数组有足够的容量
        while circleRingApps.count <= max(index1, index2) {
            circleRingApps.append("")
        }
        
        // 执行应用交换
        let app1 = circleRingApps[index1]
        let app2 = circleRingApps[index2]
        
        // 如果应用1是空的而应用2不是，则移动应用2到应用1的位置，应用2位置变空
        if app1.isEmpty && !app2.isEmpty {
            circleRingApps[index1] = app2
            circleRingApps[index2] = ""
            print("[CircleRingSectorVisualizer] 移动应用: \(app2) 从 \(index2) 到 \(index1)")
        }
        // 如果应用2是空的而应用1不是，则移动应用1到应用2的位置，应用1位置变空
        else if !app1.isEmpty && app2.isEmpty {
            circleRingApps[index2] = app1
            circleRingApps[index1] = ""
            print("[CircleRingSectorVisualizer] 移动应用: \(app1) 从 \(index1) 到 \(index2)")
        }
        // 如果两个位置都有应用，则交换它们
        else {
            circleRingApps[index1] = app2
            circleRingApps[index2] = app1
            print("[CircleRingSectorVisualizer] 交换应用: \(app1) <-> \(app2)")
        }
        
        // 移除末尾的空字符串
        while !circleRingApps.isEmpty && circleRingApps.last?.isEmpty == true {
            circleRingApps.removeLast()
        }
        
        // 更新设置并保存
        settings.circleRingApps = circleRingApps
        settings.saveSettings()
        
        // 重新加载圆环以应用新的配置
        CircleRingController.shared.reloadCircleRing()
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
    
    // 显示拖拽目标位置指示器
    private func targetIndicatorView(for index: Int, in geometry: GeometryProxy) -> some View {
        let position = positionForIndex(index, in: geometry)
        
        return Circle()
            .stroke(Color.blue, lineWidth: 2)
            .frame(width: maxIconSize + 16, height: maxIconSize + 16)
            .position(position)
            .opacity(0.7)
            .scaleEffect(1.1)
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

// 预定义图片信息结构体
struct PredefinedImage {
    let name: String
    let path: String
    let image: NSImage?
}

// 图片扩展 - 方便从路径加载图片时使用缓存
extension NSImage {
    // 从路径加载图片，使用缓存
    static func loadFromPath(_ path: String) -> NSImage? {
        return ImageCache.shared.loadImageFromPath(path)
    }
} 