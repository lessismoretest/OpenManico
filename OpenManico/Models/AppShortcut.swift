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
    
    static let shared = AppSettings()
    
    private let shortcutsKey = "AppShortcuts"
    private let themeKey = "AppTheme"
    private let launchAtLoginKey = "LaunchAtLogin"
    
    private init() {
        loadSettings()
        // 初始化时检查自启动状态
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
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: shortcutsKey)
        }
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
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
        let shortcuts = self.shortcuts.map { shortcut -> [String: String] in
            return [
                "key": shortcut.key,
                "bundleIdentifier": shortcut.bundleIdentifier,
                "appName": shortcut.appName
            ]
        }
        
        // 只导出快捷键数据
        let exportData = ["shortcuts": shortcuts]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) else {
            return nil
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let exportURL = tempDir.appendingPathComponent("OpenManico_Shortcuts.json")
        
        try? jsonData.write(to: exportURL)
        return exportURL
    }
} 