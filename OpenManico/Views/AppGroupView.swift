import SwiftUI

/**
 * 应用分组视图
 */
struct AppGroupView: View {
    @StateObject private var groupManager = AppGroupManager.shared
    @State private var showingRenameSheet = false
    @State private var selectedGroup: AppGroup?
    @State private var newGroupName = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // 分组列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(groupManager.groups) { group in
                        GroupButton(group: group) {
                            selectedGroup = group
                        } onRename: {
                            selectedGroup = group
                            newGroupName = group.name
                            showingRenameSheet = true
                        } onDelete: {
                            groupManager.deleteGroup(group)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 36)
        }
        .sheet(isPresented: $showingRenameSheet) {
            VStack(spacing: 20) {
                Text("重命名分组")
                    .font(.headline)
                
                TextField("分组名称", text: $newGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                HStack {
                    Button("取消") {
                        showingRenameSheet = false
                        newGroupName = ""
                        selectedGroup = nil
                    }
                    
                    Button("确定") {
                        if !newGroupName.isEmpty, let group = selectedGroup {
                            groupManager.renameGroup(group, to: newGroupName)
                            showingRenameSheet = false
                            newGroupName = ""
                            selectedGroup = nil
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newGroupName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300, height: 150)
        }
    }
}

/**
 * 分组按钮视图
 */
struct GroupButton: View {
    let group: AppGroup
    let onSelect: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    @State private var showingMenu = false
    
    var body: some View {
        Button(action: onSelect) {
            Text(group.name)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("重命名") { onRename() }
            Button("删除") { onDelete() }
        }
    }
} 