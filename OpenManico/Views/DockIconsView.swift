import SwiftUI

/**
 * Dock 栏程序图标视图
 */
struct DockIconsView: View {
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(settings.shortcuts.sorted(by: { $0.key < $1.key })) { shortcut in
                if let app = NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first,
                   let icon = app.icon {
                    VStack(spacing: 4) {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 48, height: 48)
                            .cornerRadius(8)
                        
                        Text(shortcut.key)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
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