import SwiftUI

/**
 * Dock 栏程序图标视图
 */
struct DockIconsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var hotKeyManager = HotKeyManager.shared
    @State private var webIcons: [String: NSImage] = [:]
    
    var body: some View {
        VStack(spacing: 16) {
            // 应用程序图标
            HStack(spacing: 12) {
                ForEach(Array(settings.shortcuts.sorted(by: { $0.key < $1.key }).enumerated()), id: \.element.id) { index, shortcut in
                    if let app = NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first,
                       let icon = app.icon {
                        VStack(spacing: 4) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 48, height: 48)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: settings.selectedShortcutIndex == index ? 2 : 0)
                                )
                            
                            Text(shortcut.key)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            // 网站快捷键图标
            if settings.showWebShortcutsInFloatingWindow && !hotKeyManager.webShortcutManager.shortcuts.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.3))
                
                HStack(spacing: 12) {
                    ForEach(Array(hotKeyManager.webShortcutManager.shortcuts.sorted(by: { $0.key < $1.key }).enumerated()), id: \.element.id) { index, shortcut in
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
                contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            window.contentView = hostingView
            window.backgroundColor = .clear
            window.isOpaque = false
            window.level = .floating
            window.hasShadow = false
            
            self.window = window
        }
        
        if let window = window {
            // 计算窗口位置（屏幕中央）
            if let screen = NSScreen.main {
                let screenFrame = screen.frame
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