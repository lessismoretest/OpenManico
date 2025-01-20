import SwiftUI

/**
 * 分组管理视图
 */
struct GroupManagementView: View {
    @StateObject private var groupManager = WebsiteGroupManager.shared
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
                ForEach(groupManager.groups) { group in
                    HStack {
                        // 拖动手柄
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.gray)
                            .opacity(group.name == "常用" ? 0 : 0.5)
                        
                        if editingGroup?.id == group.id {
                            TextField("分组名称", text: $editName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    if !editName.isEmpty {
                                        var updatedGroup = group
                                        updatedGroup.name = editName
                                        groupManager.updateGroup(updatedGroup)
                                        editingGroup = nil
                                    }
                                }
                        } else {
                            Text(group.name)
                        }
                        
                        Spacer()
                        
                        if group.name != "常用" {
                            // 编辑按钮
                            Button(action: {
                                editingGroup = group
                                editName = group.name
                            }) {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)
                            
                            // 删除按钮
                            Button(action: {
                                // 获取要删除的分组中的所有网站ID
                                let websiteIds = group.websiteIds
                                // 删除所有网站
                                for websiteId in websiteIds {
                                    if let website = WebsiteManager.shared.findWebsite(id: websiteId) {
                                        WebsiteManager.shared.deleteWebsite(website)
                                    }
                                }
                                // 删除分组
                                groupManager.deleteGroup(group)
                            }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onMove { source, destination in
                    // 确保不移动"常用"分组
                    if source.contains(0) {
                        return
                    }
                    // 更新分组顺序
                    var groups = groupManager.groups
                    groups.move(fromOffsets: source, toOffset: destination)
                    groupManager.updateGroups(groups)
                }
            }
            .listStyle(InsetListStyle())
            
            Divider()
            
            // 添加分组
            HStack {
                TextField("新分组名称", text: $newGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !newGroupName.isEmpty {
                        groupManager.addGroup(name: newGroupName)
                        newGroupName = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .disabled(newGroupName.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }
} 