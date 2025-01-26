import SwiftUI
import UniformTypeIdentifiers

/**
 * 导入设置视图
 */
struct ImportSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var websiteManager = WebsiteManager.shared
    @StateObject private var appGroupManager = AppGroupManager.shared
    @State private var showingFilePicker = false
    @State private var importResult: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var importSuccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("导入设置")
                .font(.headline)
            
            if importSuccess {
                Text("导入完成")
                    .font(.subheadline)
                
                if !importResult.isEmpty {
                    Text(importResult)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                
            } else {
                Text("请选择要导入的设置文件")
                    .font(.subheadline)
                
                if !importResult.isEmpty {
                    Text(importResult)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
                
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("选择文件") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding()
        .frame(width: 400)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importFile(from: url)
                }
            case .failure(let error):
                showError("选择文件失败：\(error.localizedDescription)")
            }
        }
        .alert("导入失败", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func importFile(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            if ExportManager.shared.importData(data) {
                var resultMessage = "导入成功"
                let websiteCount = websiteManager.getWebsites(mode: .all).count
                let websiteGroupCount = websiteManager.groups.count
                let appGroupCount = appGroupManager.groups.count
                
                if websiteCount > 0 {
                    resultMessage += "\n• \(websiteCount) 个网站"
                }
                if websiteGroupCount > 0 {
                    resultMessage += "\n• \(websiteGroupCount) 个网站分组"
                }
                if appGroupCount > 0 {
                    resultMessage += "\n• \(appGroupCount) 个应用分组"
                }
                
                importResult = resultMessage
                importSuccess = true
            } else {
                showError("导入数据失败")
            }
        } catch {
            showError("读取文件失败：\(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

/**
 * 导入数据结构
 */
struct ImportData: Codable {
    let websites: [Website]
    let groups: [WebsiteGroup]
}