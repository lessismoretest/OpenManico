//
//  OpenManicoApp.swift
//  OpenManico
//
//  Created by Less is more on 2025/1/15.
//

import SwiftUI

@main
struct OpenManicoApp: App {
    @StateObject private var settings = AppSettings.shared
    private let hotKeyManager = HotKeyManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
                .onAppear {
                    // 设置应用为代理应用
                    NSApp.setActivationPolicy(.accessory)
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // 添加一个自定义菜单项来显示主窗口
            CommandGroup(after: .appInfo) {
                Button("显示设置") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch settings.theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
