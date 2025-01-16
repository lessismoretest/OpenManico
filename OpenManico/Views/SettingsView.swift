import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var showingExportDialog = false
    @State private var showingImportDialog = false
    @State private var hasAccessibilityPermission = AXIsProcessTrusted()
    
    var body: some View {
        Form {
            Section {
                Picker("主题", selection: $settings.theme) {
                    Text("跟随系统").tag(Theme.system)
                    Text("浅色").tag(Theme.light)
                    Text("深色").tag(Theme.dark)
                }
                .pickerStyle(.menu)
                .onChange(of: settings.theme) { _ in
                    settings.saveSettings()
                    // 立即应用主题
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.applyTheme()
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
                print("Successfully exported settings to \(url)")
            case .failure(let error):
                print("Failed to export settings: \(error)")
            }
        }
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                // 读取并导入配置
                if let data = try? Data(contentsOf: url),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // 导入应用快捷键
                    if let appShortcuts = json["appShortcuts"] as? [[String: String]] {
                        let shortcuts = appShortcuts.compactMap { dict -> AppShortcut? in
                            guard let key = dict["key"],
                                  let bundleId = dict["bundleIdentifier"],
                                  let name = dict["appName"] else { return nil }
                            return AppShortcut(key: key,
                                            bundleIdentifier: bundleId,
                                            appName: name)
                        }
                        settings.shortcuts = shortcuts
                    }
                    
                    // 导入网站快捷键
                    if let webShortcuts = json["webShortcuts"] as? [[String: String]] {
                        let shortcuts = webShortcuts.compactMap { dict -> WebShortcut? in
                            guard let key = dict["key"],
                                  let url = dict["url"],
                                  let name = dict["name"] else { return nil }
                            return WebShortcut(key: key, url: url, name: name)
                        }
                        HotKeyManager.shared.webShortcutManager.shortcuts = shortcuts
                    }
                    
                    print("Successfully imported settings")
                } else {
                    print("Failed to parse import file")
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