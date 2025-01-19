import SwiftUI

/**
 * Dock 栏程序图标视图
 */
struct DockIconsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var hotKeyManager = HotKeyManager.shared
    @StateObject private var webShortcutManager = HotKeyManager.shared.webShortcutManager
    @State private var webIcons: [String: NSImage] = [:]
    
    var body: some View {
        VStack(spacing: 16) {
            // 应用场景选择器
            if settings.showSceneSwitcherInFloatingWindow {
                HStack {
                    Image(systemName: "app.badge")
                        .foregroundColor(.white)
                    Picker("", selection: Binding(
                        get: { settings.currentScene ?? settings.scenes.first ?? Scene(name: "默认场景", shortcuts: []) },
                        set: { settings.switchScene(to: $0) }
                    )) {
                        ForEach(settings.scenes.isEmpty ? [Scene(name: "默认场景", shortcuts: [])] : settings.scenes) { scene in
                            Text(scene.name).tag(scene)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                .padding(.top, 8)
            }
            
            // 应用程序图标
            HStack(spacing: 12) {
                ForEach(Array(settings.shortcuts.sorted(by: { $0.key < $1.key }).enumerated()), id: \.element.id) { index, shortcut in
                    if settings.appDisplayMode == .all || NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first != nil,
                       let icon = settings.appDisplayMode == .all ? NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: shortcut.bundleIdentifier)?.path ?? "") : NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first?.icon {
                        VStack(spacing: 4) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 48, height: 48)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: settings.selectedShortcutIndex == index ? 2 : 0)
                                )
                                .onHover { hovering in
                                    if hovering {
                                        settings.selectedShortcutIndex = index
                                        if settings.showWindowOnHover {
                                            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first {
                                                app.activate(options: [.activateIgnoringOtherApps])
                                            }
                                            else if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: shortcut.bundleIdentifier) {
                                                try? NSWorkspace.shared.launchApplication(at: appUrl,
                                                                                       options: [.default],
                                                                                       configuration: [:])
                                            }
                                        }
                                    } else if settings.selectedShortcutIndex == index {
                                        settings.selectedShortcutIndex = -1
                                    }
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onEnded { _ in
                                            if settings.openOnMouseHover && settings.selectedShortcutIndex == index {
                                                if let app = NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first {
                                                    app.activate(options: .activateIgnoringOtherApps)
                                                }
                                                else if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: shortcut.bundleIdentifier) {
                                                    try? NSWorkspace.shared.launchApplication(at: appUrl,
                                                                                           options: [.default],
                                                                                           configuration: [:])
                                                }
                                                DockIconsWindowController.shared.hideWindow()
                                            }
                                        }
                                )
                            
                            Text(shortcut.key)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            // 网站快捷键图标
            if settings.showWebShortcutsInFloatingWindow {
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // 网站场景选择器
                if settings.showSceneSwitcherInFloatingWindow {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.white)
                        Picker("", selection: Binding(
                            get: { webShortcutManager.currentScene ?? webShortcutManager.scenes.first ?? WebScene(name: "默认场景", shortcuts: []) },
                            set: { webShortcutManager.switchScene(to: $0) }
                        )) {
                            ForEach(webShortcutManager.scenes.isEmpty ? [WebScene(name: "默认场景", shortcuts: [])] : webShortcutManager.scenes) { scene in
                                Text(scene.name).tag(scene)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    .padding(.vertical, 8)
                }
                
                // 网站快捷键图标
                HStack(spacing: 12) {
                    ForEach(Array(webShortcutManager.shortcuts.sorted(by: { $0.key < $1.key }).enumerated()), id: \.element.id) { index, shortcut in
                        VStack(spacing: 4) {
                            Group {
                                if let icon = webIcons[shortcut.key] {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                } else {
                                    Image(systemName: "globe")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(.white)
                                }
                            }
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white, lineWidth: settings.selectedWebShortcutIndex == index ? 2 : 0)
                            )
                            .onHover { hovering in
                                if hovering {
                                    settings.selectedWebShortcutIndex = index
                                    if settings.openWebOnHover {
                                        NSWorkspace.shared.open(URL(string: shortcut.url)!)
                                    }
                                } else if settings.selectedWebShortcutIndex == index {
                                    settings.selectedWebShortcutIndex = -1
                                }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { _ in
                                        if settings.openOnMouseHover && settings.selectedWebShortcutIndex == index {
                                            NSWorkspace.shared.open(URL(string: shortcut.url)!)
                                        }
                                    }
                            )
                            
                            Text("⌘\(shortcut.key)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .onAppear {
                            loadWebIcon(for: shortcut)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
        }
    }
    
    private func loadWebIcon(for shortcut: WebShortcut) {
        shortcut.fetchIcon { fetchedIcon in
            if let icon = fetchedIcon {
                webIcons[shortcut.key] = icon
            }
        }
    }
}

/**
 * Dock 栏程序图标窗口控制器
 */
class DockIconsWindowController {
    static let shared = DockIconsWindowController()
    private var window: NSWindow?
    
    private init() {}
    
    func showWindow() {
        if window == nil {
            let view = DockIconsView()
            let hostingView = NSHostingView(rootView: view)
            
            let window = NSWindow(
                contentRect: .zero,  // 初始设置为零，后面会自动调整
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            window.contentView = hostingView
            window.backgroundColor = .clear
            window.isOpaque = false
            window.level = .floating
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            
            // 让窗口大小适应内容
            hostingView.setFrameSize(hostingView.fittingSize)
            window.setContentSize(hostingView.fittingSize)
            
            self.window = window
        }
        
        if let window = window {
            // 确保窗口已经调整到正确的大小
            window.contentView?.layout()
            window.setContentSize(window.contentView?.fittingSize ?? window.frame.size)
            
            // 计算窗口位置（屏幕中央）
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = window.frame
                let x = screenFrame.midX - windowFrame.width / 2
                let y = screenFrame.midY - windowFrame.height / 2
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            window.orderFront(nil)
        }
    }
    
    func hideWindow() {
        window?.orderOut(nil)
    }
} 