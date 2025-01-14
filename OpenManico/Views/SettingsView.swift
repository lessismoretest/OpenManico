import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var showingExportDialog = false
    
    var body: some View {
        List {
            // 主题设置
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Text("主题")
                        .font(.headline)
                    
                    HStack {
                        Text("外观")
                        Spacer()
                        Picker("", selection: $settings.theme) {
                            Text("浅色").tag(AppTheme.light)
                            Text("深色").tag(AppTheme.dark)
                            Text("跟随系统").tag(AppTheme.system)
                        }
                        .frame(width: 120)
                        .pickerStyle(.menu)
                    }
                }
                .padding(8)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .padding(.vertical, 20)  // 上下都添加间距
            
            // 通用设置
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Text("通用")
                        .font(.headline)
                    
                    HStack {
                        Text("开机自动启动")
                        Spacer()
                        Toggle("", isOn: $settings.launchAtLogin)
                            .toggleStyle(.switch)
                            .onChange(of: settings.launchAtLogin) { _ in
                                settings.toggleLaunchAtLogin()
                            }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        showingExportDialog = true
                    }) {
                        HStack {
                            Text("导出设置")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .padding(.bottom, 20)  // 增加底部间距
            
            // 关于信息
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Text("关于")
                        .font(.headline)
                    
                    InfoRow(title: "版本", value: Bundle.main.appVersion)
                    InfoRow(title: "开发者", value: "Less is more")
                }
                .padding(8)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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

// 用于文件导出的文档类型
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

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

extension Bundle {
    var appVersion: String {
        return "\(infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (\(infoDictionary?["CFBundleVersion"] as? String ?? "1"))"
    }
} 