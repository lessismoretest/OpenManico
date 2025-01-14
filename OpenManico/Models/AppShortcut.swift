import Foundation
import ServiceManagement

struct AppShortcut: Identifiable, Codable {
    let id = UUID()
    var key: String
    var bundleIdentifier: String
    var appName: String
    
    var displayKey: String {
        "Option + \(key)"
    }
}

enum AppTheme: String, Codable {
    case light
    case dark
    case system
}

class AppSettings: ObservableObject {
    @Published var shortcuts: [AppShortcut] = []
    @Published var theme: AppTheme = .system
    @Published var launchAtLogin: Bool = false
    @Published var totalUsageCount: Int = 0
    @Published var showFloatingWindow: Bool = true
    @Published var showWebShortcutsInFloatingWindow: Bool = false
    
    static let shared = AppSettings()
    
    private let shortcutsKey = "AppShortcuts"
    private let themeKey = "AppTheme"
    private let launchAtLoginKey = "LaunchAtLogin"
    private let usageCountKey = "UsageCount"
    private let showFloatingWindowKey = "ShowFloatingWindow"
    private let showWebShortcutsInFloatingWindowKey = "ShowWebShortcutsInFloatingWindow"
    
    private init() {
        loadSettings()
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
    
    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: shortcutsKey),
           let shortcuts = try? JSONDecoder().decode([AppShortcut].self, from: data) {
            self.shortcuts = shortcuts
        }
        
        if let themeString = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeString) {
            self.theme = theme
        }
        
        totalUsageCount = UserDefaults.standard.integer(forKey: usageCountKey)
        showFloatingWindow = UserDefaults.standard.bool(forKey: showFloatingWindowKey)
        showWebShortcutsInFloatingWindow = UserDefaults.standard.bool(forKey: showWebShortcutsInFloatingWindowKey)
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: shortcutsKey)
        }
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        UserDefaults.standard.set(totalUsageCount, forKey: usageCountKey)
        UserDefaults.standard.set(showFloatingWindow, forKey: showFloatingWindowKey)
        UserDefaults.standard.set(showWebShortcutsInFloatingWindow, forKey: showWebShortcutsInFloatingWindowKey)
    }
    
    func incrementUsageCount() {
        totalUsageCount += 1
        UserDefaults.standard.set(totalUsageCount, forKey: usageCountKey)
    }
    
    func toggleLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
            // 恢复状态
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    
    func exportSettings() -> URL? {
        // 导出应用快捷键
        let appShortcuts = self.shortcuts.map { shortcut -> [String: String] in
            return [
                "key": shortcut.key,
                "bundleIdentifier": shortcut.bundleIdentifier,
                "appName": shortcut.appName
            ]
        }
        
        // 导出网站快捷键
        let webShortcuts = HotKeyManager.shared.webShortcutManager.shortcuts.map { shortcut -> [String: String] in
            return [
                "key": shortcut.key,
                "url": shortcut.url,
                "name": shortcut.name
            ]
        }
        
        // 只导出快捷键配置
        let exportData: [String: Any] = [
            "appShortcuts": appShortcuts,
            "webShortcuts": webShortcuts
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) else {
            return nil
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let exportURL = tempDir.appendingPathComponent("OpenManico_Shortcuts.json")
        
        try? jsonData.write(to: exportURL)
        return exportURL
    }
} 