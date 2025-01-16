import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var showingImportDialog = false
    @State private var showingImportSheet = false
    @State private var importData: ExportData?
    @State private var hasAccessibilityPermission = AXIsProcessTrusted()
    @State private var showingExportSheet = false
    
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
                        showingExportSheet = true
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
        .sheet(isPresented: $showingExportSheet) {
            ExportSettingsView()
        }
        .sheet(isPresented: $showingImportSheet) {
            if let data = importData {
                ImportSettingsView(importData: data)
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
                
                // 读取并解析导入数据
                if let data = try? Data(contentsOf: url),
                   let importedData = ExportManager.shared.importScenes(from: data) {
                    self.importData = importedData
                    self.showingImportSheet = true
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

extension Bundle {
    var appVersion: String {
        return "\(infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (\(infoDictionary?["CFBundleVersion"] as? String ?? "1"))"
    }
} 