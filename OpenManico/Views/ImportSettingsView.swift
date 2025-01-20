import SwiftUI
import UniformTypeIdentifiers

/**
 * 导入设置视图
 */
struct ImportSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var websiteManager = WebsiteManager.shared
    @State private var importText: String = ""
    @State private var importResult: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            Text("请输入要导入的网站数据")
                .font(.headline)
            
            TextEditor(text: $importText)
                .font(.system(.body, design: .monospaced))
                .frame(height: 200)
            
            if !importResult.isEmpty {
                Text(importResult)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button("取消") {
                    dismiss()
                }
                
                Button("导入") {
                    importWebsites()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .frame(width: 400)
        .padding()
        .alert("导入失败", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func importWebsites() {
        guard !importText.isEmpty else {
            showError("请输入要导入的数据")
            return
        }
        
        guard let data = importText.data(using: .utf8) else {
            showError("无法解析输入的数据")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let importedData = try decoder.decode(ImportData.self, from: data)
            
            // 导入分组
            for group in importedData.groups {
                websiteManager.addGroup(name: group.name)
            }
            
            // 导入网站
            for website in importedData.websites {
                websiteManager.addWebsite(website)
            }
            
            importResult = "成功导入 \(importedData.websites.count) 个网站"
            if !importedData.groups.isEmpty {
                importResult += "，\(importedData.groups.count) 个分组"
            }
            
            // 清空输入
            importText = ""
            
        } catch {
            showError("数据格式错误: \(error.localizedDescription)")
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