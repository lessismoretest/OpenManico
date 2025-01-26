import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

/**
 * 设置视图
 */
struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    
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
                AppIconSelector()
            } header: {
                Text("应用图标")
            }
            
            Section {
                Toggle("开机自动启动", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _ in
                        settings.toggleLaunchAtLogin()
                    }
                
                Toggle("单击Option键切换上一个应用", isOn: $settings.switchToLastAppWithOptionClick)
                    .onChange(of: settings.switchToLastAppWithOptionClick) { _ in
                        settings.saveSettings()
                    }
                
                HStack {
                    Text("辅助功能权限")
                    Spacer()
                    if AXIsProcessTrusted() {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("前往设置") {
                            let prefpaneUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            NSWorkspace.shared.open(prefpaneUrl)
                        }
                    }
                }
            } header: {
                Text("通用")
            }
            
            Section {
                HStack {
                    Text("快捷键设置")
                    Spacer()
                    Button(action: {
                        showingImportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("导入")
                        }
                    }
                    .buttonStyle(.borderless)
                    .help("导入快捷键设置")
                    
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("导出")
                        }
                    }
                    .buttonStyle(.borderless)
                    .help("导出快捷键设置")
                }
            } header: {
                Text("导入导出")
            }
            
            Section {
                LabeledContent("版本", value: Bundle.main.appVersion)
                LabeledContent("开发者", value: "Less is more")
                
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
        .frame(width: 500)
        .sheet(isPresented: $showingExportSheet) {
            ExportSettingsView()
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportSettingsView()
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

extension Bundle {
    var appVersion: String {
        return "\(infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (\(infoDictionary?["CFBundleVersion"] as? String ?? "1"))"
    }
} 