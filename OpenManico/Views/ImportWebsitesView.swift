import SwiftUI
import UniformTypeIdentifiers

/**
 * 导入网站视图
 */
struct ImportWebsitesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var websiteManager = WebsiteManager.shared
    @StateObject private var groupManager = WebsiteGroupManager.shared
    @State private var showingFilePicker = false
    @State private var showingSavePanel = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("导入网站")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("导入CSV文件")
                    }
                    .frame(width: 200)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    showingSavePanel = true
                }) {
                    Text("下载CSV模板")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importWebsites(from: url)
                }
            case .failure(let error):
                print("[ImportWebsitesView] ❌ 导入失败：\(error.localizedDescription)")
            }
        }
        .onChange(of: showingSavePanel) { newValue in
            if newValue {
                downloadTemplate()
            }
        }
    }
    
    private func importWebsites(from url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines)
            
            // 跳过标题行
            for row in rows.dropFirst() where !row.isEmpty {
                let columns = row.components(separatedBy: ",")
                if columns.count >= 3 {
                    let name = columns[0].trimmingCharacters(in: .whitespaces)
                    let url = columns[1].trimmingCharacters(in: .whitespaces)
                    let groupName = columns[2].trimmingCharacters(in: .whitespaces)
                    
                    // 创建网站
                    let website = Website(url: url, name: name)
                    websiteManager.addWebsite(website)
                    
                    // 查找或创建分组
                    var groupId: UUID
                    if let existingGroup = groupManager.groups.first(where: { $0.name == groupName }) {
                        groupId = existingGroup.id
                    } else {
                        // 如果分组不存在，创建新分组
                        groupManager.addGroup(name: groupName)
                        if let newGroup = groupManager.groups.first(where: { $0.name == groupName }) {
                            groupId = newGroup.id
                        } else {
                            // 如果创建分组失败，使用默认分组
                            groupId = groupManager.groups.first!.id
                        }
                    }
                    
                    // 添加网站到分组
                    groupManager.addWebsite(website.id, to: groupId)
                }
            }
            
            // 导入完成后关闭窗口
            dismiss()
            
        } catch {
            print("[ImportWebsitesView] ❌ 导入失败：\(error.localizedDescription)")
        }
    }
    
    private func downloadTemplate() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "网站导入模板.csv"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // 创建模板文件内容
                let templateContent = """
                网站名称,网站地址,分组
                百度,https://www.baidu.com,常用
                GitHub,https://github.com,开发工具
                ChatGPT,https://chat.openai.com,AI工具
                """
                do {
                    try templateContent.write(to: url, atomically: true, encoding: .utf8)
                    print("[ImportWebsitesView] ✅ 模板文件已保存到：\(url.path)")
                } catch {
                    print("[ImportWebsitesView] ❌ 保存模板失败：\(error.localizedDescription)")
                }
            }
            showingSavePanel = false
        }
    }
} 