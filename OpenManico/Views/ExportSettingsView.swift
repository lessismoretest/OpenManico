import SwiftUI
import UniformTypeIdentifiers

/**
 * 导出设置视图
 */
struct ExportSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = AppSettings.shared
    @StateObject private var websiteManager = WebsiteManager.shared
    @StateObject private var appGroupManager = AppGroupManager.shared
    @State private var exportURL: URL?
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("导出设置")
                .font(.headline)
            
            Text("将导出以下数据：")
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• \(settings.shortcuts.count) 个应用快捷键")
                Text("• \(websiteManager.getWebsites(mode: .shortcutOnly).count) 个网站快捷键")
                Text("• \(websiteManager.groups.count) 个网站分组")
                Text("• \(appGroupManager.groups.count) 个应用分组")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("导出") {
                    if let data = ExportManager.shared.exportData() {
                        let tempDir = FileManager.default.temporaryDirectory
                        let exportURL = tempDir.appendingPathComponent("OpenManico_Settings.json")
                        do {
                            try data.write(to: exportURL)
                            self.exportURL = exportURL
                        } catch {
                            showingError = true
                        }
                    } else {
                        showingError = true
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
        .fileExporter(
            isPresented: .init(
                get: { exportURL != nil },
                set: { if !$0 { exportURL = nil } }
            ),
            document: JSONFile(url: exportURL ?? URL(fileURLWithPath: "")),
            contentType: .json,
            defaultFilename: "OpenManico_Settings.json"
        ) { result in
            switch result {
            case .success(let url):
                print("成功导出设置到：\(url.path)")
                dismiss()
            case .failure(let error):
                print("导出设置失败：\(error.localizedDescription)")
                showingError = true
            }
        }
        .alert("导出失败", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("无法导出设置，请稍后重试")
        }
    }
}

struct JSONFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        url = URL(fileURLWithPath: "")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url)
    }
} 