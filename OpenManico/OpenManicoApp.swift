//
//  OpenManicoApp.swift
//  OpenManico
//
//  Created by Less is more on 2025/1/15.
//

import SwiftUI

@main
struct OpenManicoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = AppSettings.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch settings.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyManager: HotKeyManager?
    private var settingsObserver: NSObjectProtocol?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化热键管理器
        hotKeyManager = HotKeyManager.shared
        
        // 设置应用在后台运行时保持活跃
        NSApp.setActivationPolicy(.accessory)
        
        // 防止应用在最后一个窗口关闭时退出
        NSApp.activate(ignoringOtherApps: true)
        
        // 初始应用主题
        applyTheme()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let observer = settingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func applyTheme() {
        let settings = AppSettings.shared
        let appearance: NSAppearance?
        
        switch settings.theme {
        case .light:
            appearance = NSAppearance(named: .aqua)
        case .dark:
            appearance = NSAppearance(named: .darkAqua)
        case .system:
            appearance = nil
        }
        
        DispatchQueue.main.async {
            // 应用到应用程序
            NSApp.appearance = appearance
            
            // 应用到所有窗口
            for window in NSApp.windows {
                window.appearance = appearance
                
                // 强制更新窗口和其内容
                if let contentView = window.contentView {
                    contentView.needsDisplay = true
                    contentView.needsLayout = true
                    
                    // 递归更新所有子视图
                    self.updateSubviews(of: contentView)
                }
                
                // 刷新窗口
                window.invalidateShadow()
                window.display()
            }
        }
    }
    
    private func updateSubviews(of view: NSView) {
        view.needsDisplay = true
        view.needsLayout = true
        
        for subview in view.subviews {
            updateSubviews(of: subview)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 当用户点击 Dock 图标时显示主窗口
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
}
