import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var showingExportDialog = false
    @State private var showingImportDialog = false
    @State private var hasAccessibilityPermission = AXIsProcessTrusted()
    @State private var hasAutomationPermission = false
    
    var body: some View {
        Form {
            Section {
                Picker("外观", selection: $settings.theme) {
                    Text("跟随系统").tag(AppTheme.system)
                    Text("浅色").tag(AppTheme.light)
                    Text("深色").tag(AppTheme.dark)
                }
                .pickerStyle(.menu)
                .onChange(of: settings.theme) { _ in
                    settings.saveSettings()
                    // 立即应用主题
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.applyTheme()
                    }
                    // 强制刷新所有窗口
                    for window in NSApp.windows {
                        window.invalidateShadow()
                        window.contentView?.needsDisplay = true
                        window.contentView?.needsLayout = true
                    }
                }
            } header: {
                Text("主题")
            }
            
            Section {
                Toggle("开机自动启动", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _ in
                        settings.toggleLaunchAtLogin()
                    }
                
                HStack {
                    Text("辅助功能权限")
                    Spacer()
                    if hasAccessibilityPermission {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("前往设置") {
                            openAccessibilityPreferences()
                        }
                    }
                }
                .onAppear {
                    // 每次视图出现时检查权限状态
                    hasAccessibilityPermission = AXIsProcessTrusted()
                }
                
                HStack {
                    Text("自动化权限")
                    Spacer()
                    if hasAutomationPermission {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("前往设置") {
                            openAutomationPreferences()
                        }
                    }
                }
                .onAppear {
                    checkAutomationPermission()
                }
                
                HStack {
                    Text("快捷键设置")
                    Spacer()
                    Button(action: {
                        showingImportDialog = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderless)
                    .help("导入快捷键设置")
                    
                    Button(action: {
                        showingExportDialog = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderless)
                    .help("导出快捷键设置")
                }
            } header: {
                Text("通用")
            }
            
            Section {
                LabeledContent("版本", value: Bundle.main.appVersion)
                LabeledContent("开发者", value: "Less is more")
                LabeledContent("使用次数", value: "\(settings.totalUsageCount)")
                
                Link(destination: URL(string: "https://github.com/lessismoretest/OpenManico")!) {
                    HStack {
                        GitHubIcon()
                            .foregroundColor(.primary)
                        Text("github.com/lessismoretest/OpenManico")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
            } header: {
                Text("关于")
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fileExporter(
            isPresented: $showingExportDialog,
            document: SettingsDocument(settings: settings),
            contentType: .json,
            defaultFilename: "OpenManico_Shortcuts"
        ) { result in
            switch result {
            case .success(let url):
                print("Shortcuts exported to \(url)")
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        let data = try Data(contentsOf: url)
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        
                        if let appShortcutsData = json?["appShortcuts"] as? [[String: String]] {
                            settings.shortcuts = appShortcutsData.compactMap { shortcutData in
                                guard let key = shortcutData["key"],
                                      let bundleIdentifier = shortcutData["bundleIdentifier"],
                                      let appName = shortcutData["appName"] else {
                                    return nil
                                }
                                return AppShortcut(key: key, bundleIdentifier: bundleIdentifier, appName: appName)
                            }
                        }
                        
                        if let webShortcutsData = json?["webShortcuts"] as? [[String: String]] {
                            HotKeyManager.shared.webShortcutManager.shortcuts = webShortcutsData.compactMap { shortcutData in
                                guard let key = shortcutData["key"],
                                      let url = shortcutData["url"],
                                      let name = shortcutData["name"] else {
                                    return nil
                                }
                                return WebShortcut(key: key, url: url, name: name)
                            }
                        }
                        
                        settings.saveSettings()
                        HotKeyManager.shared.webShortcutManager.saveShortcuts()
                    } catch {
                        print("Import failed: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func openAccessibilityPreferences() {
        let prefpaneUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(prefpaneUrl)
    }
    
    private func openAutomationPreferences() {
        let prefpaneUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
        NSWorkspace.shared.open(prefpaneUrl)
    }
    
    private func checkAutomationPermission() {
        // 检查是否有自动化权限
        let appleScriptCommand = """
        tell application "System Events"
            return true
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScriptCommand) {
            let output = scriptObject.executeAndReturnError(&error)
            hasAutomationPermission = error == nil && output.booleanValue
        }
    }
}

// GitHub 图标组件
struct GitHubIcon: View {
    var body: some View {
        Image("github")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
    }
}

// 文件导出相关代码保持不变
struct SettingsDocument: FileDocument {
    let settings: AppSettings
    
    static var readableContentTypes: [UTType] { [.json] }
    
    init(settings: AppSettings) {
        self.settings = settings
    }
    
    init(configuration: ReadConfiguration) throws {
        settings = AppSettings.shared
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let exportURL = settings.exportSettings(),
              let data = try? Data(contentsOf: exportURL) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

extension Bundle {
    var appVersion: String {
        return "\(infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (\(infoDictionary?["CFBundleVersion"] as? String ?? "1"))"
    }
} 