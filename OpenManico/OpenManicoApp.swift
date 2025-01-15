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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyManager: HotKeyManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化热键管理器
        hotKeyManager = HotKeyManager.shared
        
        // 设置应用在后台运行时保持活跃
        NSApp.setActivationPolicy(.accessory)
        
        // 防止应用在最后一个窗口关闭时退出
        NSApp.activate(ignoringOtherApps: true)
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
