import SwiftUI

/**
 * 分组管理视图
 */
struct GroupManagementView: View {
    @StateObject private var websiteManager = WebsiteManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var newGroupName = ""
    @State private var editingGroup: WebsiteGroup?
    @State private var editName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("分组管理")
                    .font(.headline)
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // 分组列表
            List {
                ForEach(websiteManager.groups) { group in
                    HStack {
                        // 拖动手柄
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.gray)
                            .opacity(group.name == "常用" ? 0 : 0.5)
                        
                        if editingGroup?.id == group.id {
                            // 编辑模式
                            TextField("分组名称", text: $editName)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    if !editName.isEmpty {
                                        var updatedGroup = group
                                        updatedGroup.name = editName
                                        websiteManager.updateGroup(updatedGroup)
                                        editingGroup = nil
                                    }
                                }
                        } else {
                            // 显示模式
                            Text(group.name)
                            Spacer()
                            Text("\(websiteManager.getWebsites(mode: .all, groupId: group.id).count) 个网站")
                                .foregroundColor(.secondary)
                            
                            if group.name != "常用" {
                                Button(action: {
                                    editingGroup = group
                                    editName = group.name
                                }) {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.borderless)
                                
                                Button(action: {
                                    websiteManager.deleteGroup(group)
                                }) {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                .onMove { from, to in
                    var groups = websiteManager.groups
                    groups.move(fromOffsets: from, toOffset: to)
                    // 确保"常用"分组始终在第一位
                    if let defaultGroupIndex = groups.firstIndex(where: { $0.name == "常用" }),
                       defaultGroupIndex != 0 {
                        groups.move(fromOffsets: IndexSet(integer: defaultGroupIndex), toOffset: 0)
                    }
                    // 更新分组顺序
                    websiteManager.groups = groups
                }
            }
            
            Divider()
            
            // 添加新分组
            HStack {
                TextField("新分组名称", text: $newGroupName)
                    .textFieldStyle(.roundedBorder)
                Button("添加") {
                    if !newGroupName.isEmpty {
                        websiteManager.addGroup(name: newGroupName)
                        newGroupName = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newGroupName.isEmpty)
            }
            .padding()
        }
    }
} 