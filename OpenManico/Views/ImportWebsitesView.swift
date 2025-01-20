import SwiftUI

/**
 * 导入网站视图
 */
struct ImportWebsitesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var websiteManager = WebsiteManager.shared
    @State private var importText = ""
    @State private var importResult = ""
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("导入网站")
                .font(.headline)
            
            Text("请输入要导入的网站数据，每行一个网站，格式为：")
                .font(.caption)
            Text("网站名称,网站地址,分组名称")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
            
            TextEditor(text: $importText)
                .font(.system(.body, design: .monospaced))
                .frame(height: 200)
                .border(Color.secondary.opacity(0.2))
            
            if !importResult.isEmpty {
                Text(importResult)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("导入") {
                    importWebsites()
                }
                .buttonStyle(.borderedProminent)
                .disabled(importText.isEmpty)
            }
        }
        .padding()
        .frame(width: 500)
        .alert("导入失败", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("请检查输入格式是否正确")
        }
    }
    
    private func importWebsites() {
        var successCount = 0
        var failureCount = 0
        
        let lines = importText.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        for line in lines {
            let columns = line.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            
            if columns.count >= 2 {
                let name = columns[0]
                let url = columns[1]
                let groupName = columns.count > 2 ? columns[2] : "常用"
                
                // 创建网站
                let website = Website(url: url, name: name)
                websiteManager.addWebsite(website)
                
                // 查找或创建分组
                var groupId: UUID?
                if let existingGroup = websiteManager.groups.first(where: { $0.name == groupName }) {
                    groupId = existingGroup.id
                } else {
                    websiteManager.addGroup(name: groupName)
                    groupId = websiteManager.groups.first(where: { $0.name == groupName })?.id
                }
                
                // 添加网站到分组
                if let groupId = groupId {
                    websiteManager.addWebsiteToGroup(website.id, groupId: groupId)
                    successCount += 1
                } else {
                    failureCount += 1
                }
            } else {
                failureCount += 1
            }
        }
        
        if failureCount > 0 {
            importResult = "导入完成：成功 \(successCount) 个，失败 \(failureCount) 个"
        } else {
            importResult = "成功导入 \(successCount) 个网站"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        }
    }
} 