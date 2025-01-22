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
                // 显示内容设置组
                Group {
                    AppDisplaySection(settings: settings)
                    WebsiteDisplaySection(settings: settings)
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
                }
                
                // 分割线设置组
                if settings.showWebShortcutsInFloatingWindow {
                    Group {
                        DividerSection(settings: settings)
                    }
                }
                
                // 交互设置组
                Group {
                    InteractionSection(settings: settings)
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
                }
        } header: {
            Text("基础设置")
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
                range: 400...1200,
                step: 50,
                onChange: { DockIconsWindowController.shared.updateWindow() }
            )
            
            SliderRow(
                title: "窗口高度",
                value: $settings.floatingWindowHeight,
                range: 300...800,
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
                    title: "悬浮窗不透明度",
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
                range: 32...64,
                step: 4
            )
            
            if settings.showWebShortcutsInFloatingWindow {
                SliderRow(
                    title: "网站图标大小",
                    value: $settings.webIconSize,
                    range: 32...64,
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
                title: "边框宽度",
                value: $settings.iconBorderWidth,
                range: 0...4,
                step: 0.5,
                valueFormatter: { String(format: "%.1f", $0) }
            )
            
            ColorPicker("边框颜色", selection: $settings.iconBorderColor)
            
            SliderRow(
                title: "图标间距",
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
 * 交互设置区域
 */
private struct InteractionSection: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Section {
            Toggle("鼠标滑过时打开应用", isOn: $settings.showWindowOnHover)
                .onChange(of: settings.showWindowOnHover) { _ in
                    settings.saveSettings()
                }
            
            if settings.showWebShortcutsInFloatingWindow {
                Toggle("鼠标滑过时打开网站", isOn: $settings.openWebOnHover)
                    .onChange(of: settings.openWebOnHover) { _ in
                        settings.saveSettings()
                    }
            }
            
            Toggle("鼠标悬停时松开按键打开", isOn: $settings.openOnMouseHover)
                .onChange(of: settings.openOnMouseHover) { _ in
                    settings.saveSettings()
                }
            
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
                    range: 0.1...0.5,
                    step: 0.05,
                    valueFormatter: { String(format: "%.2f", $0) }
                )
            }
        } header: {
            Text("交互行为")
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
            
            if settings.showAppsInFloatingWindow {
                Picker("应用显示模式", selection: $settings.appDisplayMode) {
                    ForEach([AppDisplayMode.all, AppDisplayMode.shortcutOnly, AppDisplayMode.runningOnly], id: \.self) { mode in
                        Text(mode.description).tag(mode)
                    }
                }
                .onChange(of: settings.appDisplayMode) { _ in
                    settings.saveSettings()
                }
            }
        } header: {
            Text("应用显示")
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
            
            if settings.showWebShortcutsInFloatingWindow {
                Picker("网站显示模式", selection: $settings.websiteDisplayMode) {
                    ForEach([WebsiteDisplayMode.shortcutOnly, WebsiteDisplayMode.all], id: \.self) { mode in
                        Text(mode.description).tag(mode)
                    }
                }
                .onChange(of: settings.websiteDisplayMode) { _ in
                    settings.saveSettings()
                }
            }
        } header: {
            Text("网站显示")
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
            Text("长按 Option 键显示悬浮窗")
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
