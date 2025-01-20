import SwiftUI

/**
 * 悬浮窗设置视图
 */
struct FloatingWindowSettingsView: View {
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        Form {
            // 基础设置组
            Section {
                Toggle("启用悬浮窗", isOn: $settings.showFloatingWindow)
                    .onChange(of: settings.showFloatingWindow) { _ in
                        settings.saveSettings()
                    }
            } header: {
                Text("基础设置")
            }
            
            if settings.showFloatingWindow {
                // 外观设置组
                Section {
                    // 窗口大小设置
                    VStack(alignment: .leading) {
                        Text("窗口宽度")
                        HStack {
                            Slider(value: $settings.floatingWindowWidth, in: 400...1200, step: 50)
                                .onChange(of: settings.floatingWindowWidth) { _ in
                                    DockIconsWindowController.shared.updatePreviewWindow()
                                }
                            Text("\(Int(settings.floatingWindowWidth))")
                                .frame(width: 50)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    VStack(alignment: .leading) {
                        Text("窗口高度")
                        HStack {
                            Slider(value: $settings.floatingWindowHeight, in: 300...800, step: 50)
                                .onChange(of: settings.floatingWindowHeight) { _ in
                                    DockIconsWindowController.shared.updatePreviewWindow()
                                }
                            Text("\(Int(settings.floatingWindowHeight))")
                                .frame(width: 50)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("窗口圆角")
                        HStack {
                            Slider(value: $settings.floatingWindowCornerRadius, in: 0...32, step: 2)
                                .onChange(of: settings.floatingWindowCornerRadius) { _ in
                                    DockIconsWindowController.shared.updatePreviewWindow()
                                }
                            Text("\(Int(settings.floatingWindowCornerRadius))")
                                .frame(width: 30)
                        }
                    }
                    
                    Divider()
                    
                    // 位置设置
                    VStack(alignment: .leading) {
                        Text("悬浮窗位置")
                        Picker("", selection: $settings.windowPosition) {
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
                        .pickerStyle(.menu)
                        .onChange(of: settings.windowPosition) { _ in
                            DockIconsWindowController.shared.updatePreviewWindow()
                        }
                        
                        if settings.windowPosition == .custom {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("水平位置")
                                    Spacer()
                                    TextField("X", value: $settings.floatingWindowX, formatter: NumberFormatter())
                                        .frame(width: 60)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: settings.floatingWindowX) { _ in
                                            DockIconsWindowController.shared.updatePreviewWindow()
                                        }
                                }
                                
                                HStack {
                                    Text("垂直位置")
                                    Spacer()
                                    TextField("Y", value: $settings.floatingWindowY, formatter: NumberFormatter())
                                        .frame(width: 60)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: settings.floatingWindowY) { _ in
                                            DockIconsWindowController.shared.updatePreviewWindow()
                                        }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    Divider()
                    
                    // 背景效果设置
                    Toggle("使用毛玻璃效果", isOn: $settings.useBlurEffect)
                        .onChange(of: settings.useBlurEffect) { _ in
                            settings.saveSettings()
                        }
                    
                    if settings.useBlurEffect {
                        // 毛玻璃效果设置
                        VStack(alignment: .leading) {
                            Text("毛玻璃强度")
                            HStack {
                                Slider(value: $settings.blurRadius, in: 5...40, step: 5)
                                Text("\(Int(settings.blurRadius))")
                                    .frame(width: 50)
                            }
                        }
                        .padding(.bottom, 4)
                    } else {
                        // 不透明度设置
                        VStack(alignment: .leading) {
                            Text("悬浮窗不透明度")
                            HStack {
                                Slider(value: $settings.floatingWindowOpacity, in: 0.1...1.0, step: 0.1)
                                Text("\(Int(settings.floatingWindowOpacity * 100))%")
                                    .frame(width: 50)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    
                    // 应用图标大小
                    VStack(alignment: .leading) {
                        Text("应用图标大小")
                        HStack {
                            Slider(value: $settings.appIconSize, in: 32...64, step: 4)
                            Text("\(Int(settings.appIconSize))")
                                .frame(width: 30)
                        }
                    }
                    
                    // 网站图标大小（仅在启用网站快捷键时显示）
                    if settings.showWebShortcutsInFloatingWindow {
                        VStack(alignment: .leading) {
                            Text("网站图标大小")
                            HStack {
                                Slider(value: $settings.webIconSize, in: 32...64, step: 4)
                                Text("\(Int(settings.webIconSize))")
                                    .frame(width: 30)
                            }
                        }
                    }
                    
                    // 图标样式设置
                    Group {
                        Text("图标样式")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        HStack {
                            Text("圆角半径")
                            Slider(value: $settings.iconCornerRadius, in: 0...16, step: 1)
                            Text("\(Int(settings.iconCornerRadius))")
                                .frame(width: 30)
                        }
                        
                        HStack {
                            Text("边框宽度")
                            Slider(value: $settings.iconBorderWidth, in: 0...4, step: 0.5)
                            Text(String(format: "%.1f", settings.iconBorderWidth))
                                .frame(width: 30)
                        }
                        
                        ColorPicker("边框颜色", selection: $settings.iconBorderColor)
                        
                        HStack {
                            Text("图标间距")
                            Slider(value: $settings.iconSpacing, in: 0...16, step: 1)
                            Text("\(Int(settings.iconSpacing))")
                                .frame(width: 30)
                        }
                        
                        Toggle("启用阴影", isOn: $settings.useIconShadow)
                        
                        if settings.useIconShadow {
                            HStack {
                                Text("阴影半径")
                                Slider(value: $settings.iconShadowRadius, in: 0...10, step: 0.5)
                                Text(String(format: "%.1f", settings.iconShadowRadius))
                                    .frame(width: 30)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // 应用快捷键标签设置
                        Text("应用快捷键标签")
                            .font(.headline)
                            .padding(.top, 8)
                        
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
                            .pickerStyle(.menu)
                            
                            ColorPicker("标签背景色", selection: $settings.appShortcutLabelBackgroundColor)
                            ColorPicker("标签文字色", selection: $settings.appShortcutLabelTextColor)
                            
                            HStack {
                                Text("标签大小")
                                Slider(value: $settings.appShortcutLabelFontSize, in: 8...16, step: 1)
                                Text("\(Int(settings.appShortcutLabelFontSize))")
                                    .frame(width: 30)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("标签位置微调")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("水平偏移")
                                    Slider(value: $settings.appShortcutLabelOffsetX, in: -20...20, step: 1)
                                    Text("\(Int(settings.appShortcutLabelOffsetX))")
                                        .frame(width: 30)
                                }
                                
                                HStack {
                                    Text("垂直偏移")
                                    Slider(value: $settings.appShortcutLabelOffsetY, in: -20...20, step: 1)
                                    Text("\(Int(settings.appShortcutLabelOffsetY))")
                                        .frame(width: 30)
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // 网站快捷键标签设置
                        Text("网站快捷键标签")
                            .font(.headline)
                            .padding(.top, 8)
                        
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
                            .pickerStyle(.menu)
                            
                            ColorPicker("标签背景色", selection: $settings.webShortcutLabelBackgroundColor)
                            ColorPicker("标签文字色", selection: $settings.webShortcutLabelTextColor)
                            
                            HStack {
                                Text("标签大小")
                                Slider(value: $settings.webShortcutLabelFontSize, in: 8...16, step: 1)
                                Text("\(Int(settings.webShortcutLabelFontSize))")
                                    .frame(width: 30)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("标签位置微调")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("水平偏移")
                                    Slider(value: $settings.webShortcutLabelOffsetX, in: -20...20, step: 1)
                                    Text("\(Int(settings.webShortcutLabelOffsetX))")
                                        .frame(width: 30)
                                }
                                
                                HStack {
                                    Text("垂直偏移")
                                    Slider(value: $settings.webShortcutLabelOffsetY, in: -20...20, step: 1)
                                    Text("\(Int(settings.webShortcutLabelOffsetY))")
                                        .frame(width: 30)
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // 图标悬停动画设置
                        Text("图标悬停动画")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        Toggle("启用悬停动画", isOn: $settings.useHoverAnimation)
                        
                        if settings.useHoverAnimation {
                            HStack {
                                Text("放大倍数")
                                Slider(value: $settings.hoverScale, in: 1.0...1.5, step: 0.05)
                                Text(String(format: "%.2f", settings.hoverScale))
                                    .frame(width: 40)
                            }
                            
                            HStack {
                                Text("动画时长")
                                Slider(value: $settings.hoverAnimationDuration, in: 0.1...0.5, step: 0.05)
                                Text(String(format: "%.2f", settings.hoverAnimationDuration))
                                    .frame(width: 40)
                            }
                        }
                    }
                } header: {
                    Text("外观设置")
                }
                
                // 显示内容设置组
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
                    
                    Toggle("显示网站快捷键", isOn: $settings.showWebShortcutsInFloatingWindow)
                        .onChange(of: settings.showWebShortcutsInFloatingWindow) { _ in
                            settings.saveSettings()
                        }
                    
                    if settings.showWebShortcutsInFloatingWindow {
                        Divider()
                            .padding(.vertical, 4)
                        
                        Toggle("显示分割线", isOn: $settings.showDivider)
                        
                        if settings.showDivider {
                            HStack {
                                Text("分割线不透明度")
                                Slider(value: $settings.dividerOpacity, in: 0.1...1.0, step: 0.1)
                                Text(String(format: "%.1f", settings.dividerOpacity))
                                    .frame(width: 30)
                            }
                        }
                        
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
                    Text("显示内容")
                }
                
                // 交互行为设置组
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
                } header: {
                    Text("交互行为")
                }
                
                // 说明信息组
                Section {
                    Text("长按 Option 键显示应用快捷键悬浮窗")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Text("悬浮窗会显示已配置的应用程序图标和对应的快捷键，帮助你快速找到需要的应用。")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    if settings.showWebShortcutsInFloatingWindow {
                        Text("开启网站快捷键显示后，悬浮窗下方会显示已配置的网站图标。")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("说明")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if settings.showFloatingWindow {
                // 隐藏原悬浮窗，显示预览窗口
                DockIconsWindowController.shared.hideWindow()
                DockIconsWindowController.shared.showPreviewWindow()
            }
        }
        .onDisappear {
            // 隐藏预览窗口，恢复原悬浮窗
            DockIconsWindowController.shared.hidePreviewWindow()
            if settings.showFloatingWindow {	
                DockIconsWindowController.shared.showWindow()
            }
        }
        // 添加点击手势，确保设置窗口保持在前台
        .onTapGesture {
            if let window = NSApp.windows.first(where: { $0.contentView?.subviews.contains(where: { $0 is NSHostingView<FloatingWindowSettingsView> }) ?? false }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
} 
