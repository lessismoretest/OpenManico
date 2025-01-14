import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var showingExportDialog = false
    
    var body: some View {
        Form {
            Section {
                Picker("外观", selection: $settings.theme) {
                    Text("跟随系统").tag(AppTheme.system)
                    Text("浅色").tag(AppTheme.light)
                    Text("深色").tag(AppTheme.dark)
                }
                .pickerStyle(.menu)
            } header: {
                Text("主题")
            }
            
            Section {
                Toggle("开机自动启动", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _ in
                        settings.toggleLaunchAtLogin()
                    }
                
                HStack {
                    Text("导出快捷键设置")
                    Spacer()
                    Button(action: {
                        showingExportDialog = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderless)
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