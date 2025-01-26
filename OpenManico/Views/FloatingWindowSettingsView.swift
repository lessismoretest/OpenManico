import SwiftUI

/**
 * 悬浮窗设置视图
 */
struct FloatingWindowSettingsView: View {
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        Form {
            // 基础设置组
            Group {
                BasicSettingsSection(settings: settings)
            }
            
            if settings.showFloatingWindow {
                // 菜单栏悬停设置组
                Group {
                    MenuBarHoverSection(settings: settings)
                }
                
                // 工具栏设置组
                Group {
                    ToolbarSettingsSection(settings: settings)
                }
                
                // 显示内容设置组
                Group {
                    AppDisplaySection(settings: settings)
                    WebsiteDisplaySection(settings: settings)
                    GroupDisplaySection(settings: settings)
                }
                
                // 窗口设置组
                Group {
                    WindowSizeSection(settings: settings)
                    WindowPositionSection(settings: settings)
                    WindowAppearanceSection(settings: settings)
                }
                
                // 图标设置组
                Group {
                    IconSettingsSection(settings: settings)
                    NameDisplaySection(settings: settings)
                    ShortcutLabelSection(settings: settings)
                    RunningIndicatorSection(settings: settings)
                }
                
                // 分割线设置组
                if settings.showWebShortcutsInFloatingWindow {
                    Group {
                        DividerSection(settings: settings)
                    }
                }
                
                // 区域布局设置
                if settings.showAppsInFloatingWindow && settings.showWebShortcutsInFloatingWindow {
                    Group {
                        AreaLayoutSection(settings: settings)
                    }
                }
                
                // 悬停动画设置组
                Group {
                    HoverAnimationSection(settings: settings)
                }
                
                // 说明信息组
                Group {
                    InstructionSection()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: settings.floatingWindowWidth) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
        .onChange(of: settings.floatingWindowHeight) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
        .onChange(of: settings.floatingWindowCornerRadius) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
        .onChange(of: settings.floatingWindowTheme) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
        .onChange(of: settings.useBlurEffect) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
        .onChange(of: settings.floatingWindowOpacity) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
        .onChange(of: settings.windowPosition) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
        .onChange(of: settings.floatingWindowX) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
        .onChange(of: settings.floatingWindowY) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
        .onChange(of: settings.iconGridSpacing) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
        .onChange(of: settings.layoutDirection) { _ in
            DockIconsWindowController.shared.updateWindow()
        }
    }
}

/**
 * 通用滑块行组件
 */
private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var valueFormatter: ((Double) -> String)?
    var onChange: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            HStack {
                Slider(value: $value, in: range, step: step)
                    .onChange(of: value) { _ in
                        onChange?()
                    }
                Text(valueFormatter?(value) ?? "\(Int(value))")
                    .frame(width: 50)
            }
        }
        .padding(.vertical, 4)
    }
}

/**
 * 基础设置区域
 */
private struct BasicSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("启用悬浮窗", isOn: $settings.showFloatingWindow)
                .onChange(of: settings.showFloatingWindow) { _ in
                    settings.saveSettings()
                    if settings.showFloatingWindow {
                        DockIconsWindowController.shared.showWindow()
                    } else {
                        DockIconsWindowController.shared.hideWindow()
                    }
                }
        } header: {
            Text("基础设置")
        }
    }
}

/**
 * 菜单栏悬停设置区域
 */
private struct MenuBarHoverSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("鼠标滑过刘海区域时显示", isOn: $settings.showOnMenuBarHover)
                .onChange(of: settings.showOnMenuBarHover) { _ in
                    settings.saveSettings()
                }
                
            Text("当鼠标滑过屏幕顶部菜单栏刘海区域时自动显示悬浮窗")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("触发设置")
        }
    }
}

/**
 * 工具栏设置区域
 */
private struct ToolbarSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("显示工具栏", isOn: $settings.showToolbar)
                .onChange(of: settings.showToolbar) { _ in
                    settings.saveSettings()
                    // 刷新悬浮窗
                    DockIconsWindowController.shared.updateWindow()
                }
            
            Text("说明：工具栏上可以快速切换应用/网站显示，设置窗口置顶和关闭窗口")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("工具栏设置")
        }
    }
}

/**
 * 窗口尺寸设置区域
 */
private struct WindowSizeSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            SliderRow(
                title: "窗口宽度",
                value: $settings.floatingWindowWidth,
                range: 50...1600,
                step: 50,
                onChange: { DockIconsWindowController.shared.updateWindow() }
            )
            
            SliderRow(
                title: "窗口高度",
                value: $settings.floatingWindowHeight,
                range: 50...1200,
                step: 50,
                onChange: { DockIconsWindowController.shared.updateWindow() }
            )
            
            SliderRow(
                title: "窗口圆角",
                value: $settings.floatingWindowCornerRadius,
                range: 0...32,
                step: 2,
                onChange: { DockIconsWindowController.shared.updateWindow() }
            )
        } header: {
            Text("窗口尺寸")
        }
    }
}

/**
 * 窗口位置设置区域
 */
private struct WindowPositionSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Picker("悬浮窗位置", selection: $settings.windowPosition) {
                ForEach([
                    WindowPosition.topLeft,
                    WindowPosition.topCenter,
                    WindowPosition.topRight,
                    WindowPosition.centerLeft,
                    WindowPosition.center,
                    WindowPosition.centerRight,
                    WindowPosition.bottomLeft,
                    WindowPosition.bottomCenter,
                    WindowPosition.bottomRight,
                    WindowPosition.custom
                ], id: \.self) { position in
                    Text(position.description).tag(position)
                }
            }
            .onChange(of: settings.windowPosition) { _ in
                DockIconsWindowController.shared.updateWindow()
            }
            
            if settings.windowPosition == .custom {
                HStack {
                    Text("水平位置")
                    Spacer()
                    TextField("X", value: $settings.floatingWindowX, formatter: NumberFormatter())
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: settings.floatingWindowX) { _ in
                            DockIconsWindowController.shared.updateWindow()
                        }
                }
                
                HStack {
                    Text("垂直位置")
                    Spacer()
                    TextField("Y", value: $settings.floatingWindowY, formatter: NumberFormatter())
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: settings.floatingWindowY) { _ in
                            DockIconsWindowController.shared.updateWindow()
                        }
                }
            }
        } header: {
            Text("窗口位置")
        }
    }
}

/**
 * 窗口外观设置区域
 */
private struct WindowAppearanceSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Picker("主题", selection: $settings.floatingWindowTheme) {
                Text("跟随系统").tag(FloatingWindowTheme.system)
                Text("浅色").tag(FloatingWindowTheme.light)
                Text("深色").tag(FloatingWindowTheme.dark)
            }
            .onChange(of: settings.floatingWindowTheme) { _ in
                DockIconsWindowController.shared.updateWindow()
            }
            
            Toggle("使用毛玻璃效果", isOn: $settings.useBlurEffect)
                .onChange(of: settings.useBlurEffect) { _ in
                    settings.saveSettings()
                    DockIconsWindowController.shared.updateWindow()
                }
            
            if !settings.useBlurEffect {
                SliderRow(
                    title: "背景面板不透明度",
                    value: $settings.floatingWindowOpacity,
                    range: 0.1...1.0,
                    step: 0.1,
                    valueFormatter: { "\(Int($0 * 100))%" },
                    onChange: { DockIconsWindowController.shared.updateWindow() }
                )
            }
        } header: {
            Text("窗口外观")
        } footer: {
            if settings.useBlurEffect {
                Text("使用系统原生毛玻璃效果，自动适配系统主题")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/**
 * 图标设置区域
 */
private struct IconSettingsSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            SliderRow(
                title: "应用图标大小",
                value: $settings.appIconSize,
                range: 16...128,
                step: 4
            )
            
            if settings.showWebShortcutsInFloatingWindow {
                SliderRow(
                    title: "网站图标大小",
                    value: $settings.webIconSize,
                    range: 16...128,
                    step: 4
                )
            }
            
            SliderRow(
                title: "图标圆角",
                value: $settings.iconCornerRadius,
                range: 0...16,
                step: 1
            )
            
            SliderRow(
                title: "图标网格间距",
                value: $settings.iconGridSpacing,
                range: 8...32,
                step: 2,
                onChange: { DockIconsWindowController.shared.updateWindow() }
            )
            
            SliderRow(
                title: "图标与名称间距",
                value: $settings.iconSpacing,
                range: 0...16,
                step: 1
            )
            
            Toggle("启用阴影", isOn: $settings.useIconShadow)
            
            if settings.useIconShadow {
                SliderRow(
                    title: "阴影半径",
                    value: $settings.iconShadowRadius,
                    range: 0...10,
                    step: 0.5,
                    valueFormatter: { String(format: "%.1f", $0) }
                )
            }
        } header: {
            Text("图标设置")
        }
    }
}

/**
 * 名称显示设置区域
 */
private struct NameDisplaySection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("显示应用名称", isOn: $settings.showAppName)
            
            if settings.showAppName {
                SliderRow(
                    title: "应用名称大小",
                    value: $settings.appNameFontSize,
                    range: 8...16,
                    step: 1
                )
            }
            
            if settings.showWebShortcutsInFloatingWindow {
                Toggle("显示网站名称", isOn: $settings.showWebsiteName)
                
                if settings.showWebsiteName {
                    SliderRow(
                        title: "网站名称大小",
                        value: $settings.websiteNameFontSize,
                        range: 8...16,
                        step: 1
                    )
                }
            }
        } header: {
            Text("名称显示")
        }
    }
}

/**
 * 快捷键标签设置区域
 */
private struct ShortcutLabelSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("显示应用快捷键标签", isOn: $settings.showAppShortcutLabel)
            
            if settings.showAppShortcutLabel {
                Picker("标签位置", selection: $settings.appShortcutLabelPosition) {
                    ForEach([
                        ShortcutLabelPosition.top,
                        ShortcutLabelPosition.bottom,
                        ShortcutLabelPosition.left,
                        ShortcutLabelPosition.right
                    ], id: \.self) { position in
                        Text(position.description).tag(position)
                    }
                }
                
                SliderRow(
                    title: "水平偏移",
                    value: $settings.appShortcutLabelOffsetX,
                    range: -50...50,
                    step: 1
                )
                
                SliderRow(
                    title: "垂直偏移",
                    value: $settings.appShortcutLabelOffsetY,
                    range: -50...50,
                    step: 1
                )
                
                ColorPicker("标签背景色", selection: $settings.appShortcutLabelBackgroundColor)
                ColorPicker("标签文字色", selection: $settings.appShortcutLabelTextColor)
                
                SliderRow(
                    title: "标签大小",
                    value: $settings.appShortcutLabelFontSize,
                    range: 8...16,
                    step: 1
                )
            }
            
            if settings.showWebShortcutsInFloatingWindow {
                Toggle("显示网站快捷键标签", isOn: $settings.showWebShortcutLabel)
                
                if settings.showWebShortcutLabel {
                    Picker("标签位置", selection: $settings.webShortcutLabelPosition) {
                        ForEach([
                            ShortcutLabelPosition.top,
                            ShortcutLabelPosition.bottom,
                            ShortcutLabelPosition.left,
                            ShortcutLabelPosition.right
                        ], id: \.self) { position in
                            Text(position.description).tag(position)
                        }
                    }
                    
                    SliderRow(
                        title: "水平偏移",
                        value: $settings.webShortcutLabelOffsetX,
                        range: -50...50,
                        step: 1
                    )
                    
                    SliderRow(
                        title: "垂直偏移",
                        value: $settings.webShortcutLabelOffsetY,
                        range: -50...50,
                        step: 1
                    )
                    
                    ColorPicker("标签背景色", selection: $settings.webShortcutLabelBackgroundColor)
                    ColorPicker("标签文字色", selection: $settings.webShortcutLabelTextColor)
                    
                    SliderRow(
                        title: "标签大小",
                        value: $settings.webShortcutLabelFontSize,
                        range: 8...16,
                        step: 1
                    )
                }
            }
        } header: {
            Text("快捷键标签")
        }
    }
}

/**
 * 应用图标标识设置区域
 */
private struct RunningIndicatorSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("显示运行中应用标识", isOn: $settings.showRunningIndicator)
            
            if settings.showRunningIndicator {
                Picker("标识位置", selection: $settings.runningIndicatorPosition) {
                    ForEach([
                        ShortcutLabelPosition.top,
                        ShortcutLabelPosition.bottom,
                        ShortcutLabelPosition.left,
                        ShortcutLabelPosition.right
                    ], id: \.self) { position in
                        Text(position.description).tag(position)
                    }
                }
                
                SliderRow(
                    title: "标识大小",
                    value: $settings.runningIndicatorSize,
                    range: 4...12,
                    step: 1
                )
                
                ColorPicker("标识颜色", selection: $settings.runningIndicatorColor)
            }
        } header: {
            Text("运行中应用标识")
        } footer: {
            Text("为正在运行的应用显示一个小圆点，类似macOS Dock")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/**
 * 区域布局设置区域
 */
private struct AreaLayoutSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Picker("布局方向", selection: $settings.layoutDirection) {
                Text("上下布局").tag(LayoutDirection.vertical)
                Text("左右布局").tag(LayoutDirection.horizontal)
            }
            .onChange(of: settings.layoutDirection) { _ in
                DockIconsWindowController.shared.updateWindow()
            }
            
            Picker("区域显示顺序", selection: $settings.appWebsiteOrder) {
                Text(settings.layoutDirection == .vertical ? "应用区域在上" : "应用区域在左").tag(AppWebsiteOrder.appFirst)
                Text(settings.layoutDirection == .vertical ? "网站区域在上" : "网站区域在左").tag(AppWebsiteOrder.websiteFirst)
            }
            .onChange(of: settings.appWebsiteOrder) { _ in
                DockIconsWindowController.shared.updateWindow()
            }
            
            VStack(alignment: .leading) {
                Text("应用区域占比: \(Int(settings.appAreaRatio * 100))%")
                HStack {
                    Text("10%")
                    Slider(value: $settings.appAreaRatio, in: 0.1...0.9, step: 0.05)
                        .onChange(of: settings.appAreaRatio) { _ in
                            DockIconsWindowController.shared.updateWindow()
                        }
                    Text("90%")
                }
            }
            .padding(.vertical, 4)
            
            SliderRow(
                title: "区域间隔大小",
                value: $settings.areaSeparatorSize,
                range: 0...32,
                step: 2,
                onChange: { DockIconsWindowController.shared.updateWindow() }
            )
            
            Text("提示：拖动滑块调整应用区域与网站区域的比例")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("区域布局")
        }
    }
}

/**
 * 悬停动画设置区域
 */
private struct HoverAnimationSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("启用悬停动画", isOn: $settings.useHoverAnimation)
            
            if settings.useHoverAnimation {
                SliderRow(
                    title: "放大倍数",
                    value: $settings.hoverScale,
                    range: 1.0...1.5,
                    step: 0.05,
                    valueFormatter: { String(format: "%.2f", $0) }
                )
                
                SliderRow(
                    title: "动画时长",
                    value: $settings.hoverAnimationDuration,
                    range: 0.1...0.8,
                    step: 0.05,
                    valueFormatter: { String(format: "%.2f", $0) }
                )
                
                SliderRow(
                    title: "边框宽度",
                    value: $settings.iconBorderWidth,
                    range: 0...4,
                    step: 0.5,
                    valueFormatter: { String(format: "%.1f", $0) }
                )
                
                ColorPicker("边框颜色", selection: $settings.iconBorderColor)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Toggle("启用悬停背景", isOn: $settings.useHoverBackground)
            
            if settings.useHoverBackground {
                ColorPicker("背景颜色", selection: $settings.iconHoverBackgroundColor)
                
                SliderRow(
                    title: "背景内边距",
                    value: $settings.iconHoverBackgroundPadding,
                    range: 0...20,
                    step: 1
                )
                
                SliderRow(
                    title: "背景圆角",
                    value: $settings.iconHoverBackgroundCornerRadius,
                    range: 0...20,
                    step: 1
                )
            }
        } header: {
            Text("交互效果")
        }
    }
}

/**
 * 显示内容设置区域 - 应用显示
 */
private struct AppDisplaySection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("显示应用", isOn: $settings.showAppsInFloatingWindow)
                .onChange(of: settings.showAppsInFloatingWindow) { _ in
                    settings.saveSettings()
                }
            
            Toggle("点击当前运行应用切换到上一个应用", isOn: $settings.clickAppToToggle)
                .onChange(of: settings.clickAppToToggle) { _ in
                    settings.saveSettings()
                }
            
            Text("启用后，点击悬浮窗中的已运行应用会切换回上一个使用的应用")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
                
            Toggle("鼠标滑过应用图标立即打开应用", isOn: $settings.openAppOnMouseHover)
                .onChange(of: settings.openAppOnMouseHover) { _ in
                    settings.saveSettings()
                }
                
            Text("启用后，当鼠标滑过悬浮窗中的应用图标时会立即打开应用，无需点击")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("应用显示")
        } footer: {
            Text("可以在悬浮窗内通过左上角按钮切换显示所有应用或仅显示运行中的应用")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/**
 * 显示内容设置区域 - 网站显示
 */
private struct WebsiteDisplaySection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("显示网站", isOn: $settings.showWebShortcutsInFloatingWindow)
                .onChange(of: settings.showWebShortcutsInFloatingWindow) { _ in
                    settings.saveSettings()
                }
        } header: {
            Text("网站显示")
        }
    }
}

/**
 * 分组显示设置区域
 */
private struct GroupDisplaySection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("显示分组", isOn: $settings.showGroupsInFloatingWindow)
                .onChange(of: settings.showGroupsInFloatingWindow) { _ in
                    settings.saveSettings()
                    // 刷新悬浮窗
                    DockIconsWindowController.shared.updateWindow()
                }
            
            Toggle("显示分组数字", isOn: $settings.showGroupCountInFloatingWindow)
                .onChange(of: settings.showGroupCountInFloatingWindow) { _ in
                    settings.saveSettings()
                    // 刷新悬浮窗
                    DockIconsWindowController.shared.updateWindow()
                }
            
            // 应用分组显示位置设置
            if settings.showAppsInFloatingWindow && settings.showGroupsInFloatingWindow {
                Picker("应用分组显示位置", selection: $settings.groupDisplayPosition) {
                    ForEach(GroupDisplayPosition.allCases) { position in
                        Text(position.description).tag(position)
                    }
                }
                .onChange(of: settings.groupDisplayPosition) { _ in
                    settings.saveSettings()
                    // 刷新悬浮窗
                    DockIconsWindowController.shared.updateWindow()
                }
            }
            
            // 网站分组显示位置设置
            if settings.showWebShortcutsInFloatingWindow && settings.showGroupsInFloatingWindow {
                Picker("网站分组显示位置", selection: $settings.webGroupDisplayPosition) {
                    ForEach(GroupDisplayPosition.allCases) { position in
                        Text(position.description).tag(position)
                    }
                }
                .onChange(of: settings.webGroupDisplayPosition) { _ in
                    settings.saveSettings()
                    // 刷新悬浮窗
                    DockIconsWindowController.shared.updateWindow()
                }
            }
        } header: {
            Text("分组显示")
        } footer: {
            Text("分组可以帮助你快速筛选应用和网站")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/**
 * 分割线设置区域
 */
private struct DividerSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("显示分割线", isOn: $settings.showDivider)
            
            if settings.showDivider {
                SliderRow(
                    title: "分割线不透明度",
                    value: $settings.dividerOpacity,
                    range: 0.1...1.0,
                    step: 0.1,
                    valueFormatter: { String(format: "%.1f", $0) }
                )
            }
        } header: {
            Text("分割线")
        }
    }
}

/**
 * 说明信息区域
 */
private struct InstructionSection: View {
    var body: some View {
        Section {
            Text("双击 Option 键可以显示或固定悬浮窗")
                .font(.callout)
                .foregroundColor(.secondary)
            
            Text("再次双击 Option 键可隐藏悬浮窗")
                .font(.callout)
                .foregroundColor(.secondary)
            
            Text("悬浮窗会显示已配置的应用程序图标和对应的快捷键，帮助你快速找到需要的应用。")
                .font(.callout)
                .foregroundColor(.secondary)
        } header: {
            Text("说明")
        }
    }
} 
