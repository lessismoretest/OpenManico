import SwiftUI

/**
 * 应用分组管理视图
 */
struct AppGroupManagementView: View {
    @StateObject private var appGroupManager = AppGroupManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var newGroupName = ""
    @State private var editingGroup: AppGroup?
    @State private var editName = ""
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("分组管理")
                    .font(.headline)
                Spacer()
                Button(isEditing ? "完成" : "编辑") {
                    isEditing.toggle()
                }
                .buttonStyle(.bordered)
                Button("关闭") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // 分组列表
            List {
                ForEach(appGroupManager.groups) { group in
                    HStack {
                        // 拖动手柄
                        if isEditing {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.gray)
                                .opacity(group.name == "默认" ? 0 : 0.5)
                        }
                        
                        if editingGroup?.id == group.id {
                            // 编辑模式
                            TextField("分组名称", text: $editName)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    if !editName.isEmpty {
                                        var updatedGroup = group
                                        updatedGroup.name = editName
                                        appGroupManager.updateGroup(updatedGroup)
                                        editingGroup = nil
                                    }
                                }
                        } else {
                            // 显示模式
                            Text(group.name)
                            Spacer()
                            Text("\(appGroupManager.getApps(groupId: group.id).count) 个应用")
                                .foregroundColor(.secondary)
                            
                            if group.name != "默认" && isEditing {
                                Button(action: {
                                    editingGroup = group
                                    editName = group.name
                                }) {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.borderless)
                                
                                Button(action: {
                                    appGroupManager.deleteGroup(group)
                                }) {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                .onMove { source, destination in
                    var groups = appGroupManager.groups
                    groups.move(fromOffsets: source, toOffset: destination)
                    // 确保"默认"分组始终在第一位
                    if let defaultGroupIndex = groups.firstIndex(where: { $0.name == "默认" }),
                       defaultGroupIndex != 0 {
                        groups.move(fromOffsets: IndexSet(integer: defaultGroupIndex), toOffset: 0)
                    }
                    // 更新分组顺序
                    appGroupManager.groups = groups
                }
            }
            
            Divider()
            
            // 添加新分组
            HStack {
                TextField("新分组名称", text: $newGroupName)
                    .textFieldStyle(.roundedBorder)
                Button("添加") {
                    if !newGroupName.isEmpty {
                        appGroupManager.createGroup(name: newGroupName, apps: [])
                        newGroupName = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newGroupName.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }
} 