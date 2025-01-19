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
                } header: {
                    Text("外观设置")
                }
                
                // 显示内容设置组
                Section {
                    Toggle("显示场景切换菜单", isOn: $settings.showSceneSwitcherInFloatingWindow)
                        .onChange(of: settings.showSceneSwitcherInFloatingWindow) { _ in
                            settings.saveSettings()
                        }
                    
                    Picker("应用显示模式", selection: $settings.appDisplayMode) {
                        ForEach([AppDisplayMode.all, AppDisplayMode.running, AppDisplayMode.installed, AppDisplayMode.switcher], id: \.self) { mode in
                            Text(mode.description).tag(mode)
                        }
                    }
                    .onChange(of: settings.appDisplayMode) { _ in
                        settings.saveSettings()
                    }
                    
                    Toggle("显示网站快捷键", isOn: $settings.showWebShortcutsInFloatingWindow)
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