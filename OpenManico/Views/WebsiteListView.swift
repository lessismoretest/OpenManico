import SwiftUI
import AppKit

/**
 * 网站列表视图
 */
struct WebsiteListView: View {
    @StateObject private var websiteManager = WebsiteManager.shared
    @StateObject private var groupManager = WebsiteGroupManager.shared
    @State private var searchText = ""
    @State private var editingWebsite: Website?
    @State private var showingAddSheet = false
    @State private var showingGroupSheet = false
    @State private var selectedGroup: UUID? = nil
    @State private var newGroupName = ""
    @State private var editingGroup: WebsiteGroup?
    
    private var filteredWebsites: [Website] {
        let websites = if let groupId = selectedGroup {
            websiteManager.websites.filter { website in
                groupManager.groups.first(where: { $0.id == groupId })?.websiteIds.contains(website.id) ?? false
            }
        } else {
            websiteManager.websites
        }
        
        if searchText.isEmpty {
            return websites.sorted { $0.name < $1.name }
        }
        return websites.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.name < $1.name }
    }
    
    private func onGroupSelect(_ website: Website, groupId: UUID) {
        if groupManager.groups.first(where: { $0.id == groupId })?.websiteIds.contains(website.id) ?? false {
            groupManager.removeWebsite(website.id, from: groupId)
        } else {
            groupManager.addWebsite(website.id, to: groupId)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 分组选择器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 全部网站按钮
                    Button(action: { selectedGroup = nil }) {
                        Text("全部")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedGroup == nil ? Color.blue : Color.gray.opacity(0.3))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // 分组按钮
                    ForEach(groupManager.groups) { group in
                        HStack {
                            Button(action: { selectedGroup = group.id }) {
                                Text("\(group.name) (\(group.websiteIds.count))")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedGroup == group.id ? Color.blue : Color.gray.opacity(0.3))
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            // 编辑分组按钮
                            if selectedGroup == group.id {
                                Button(action: {
                                    editingGroup = group
                                    newGroupName = group.name
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    groupManager.deleteGroup(group)
                                    selectedGroup = nil
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 添加分组按钮
                    Button(action: { showingGroupSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // 搜索框和添加按钮
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索网站...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // 网站列表
            List {
                ForEach(filteredWebsites) { website in
                    WebsiteRow(website: website,
                             isEditing: editingWebsite?.id == website.id,
                             onEdit: {
                        editingWebsite = website
                    },
                             onSave: { url, name in
                        var updatedWebsite = website
                        updatedWebsite.url = url
                        updatedWebsite.name = name
                        websiteManager.updateWebsite(updatedWebsite)
                        editingWebsite = nil
                    },
                             onCancel: {
                        editingWebsite = nil
                    },
                             onDelete: {
                        websiteManager.deleteWebsite(website)
                    },
                             onGroupSelect: { groupId in
                        onGroupSelect(website, groupId: groupId)
                    })
                }
            }
            .listStyle(InsetListStyle())
        }
        .sheet(isPresented: $showingAddSheet) {
            AddWebsiteView { url, name in
                let website = Website(url: url, name: name)
                websiteManager.addWebsite(website)
                if let groupId = selectedGroup {
                    groupManager.addWebsite(website.id, to: groupId)
                }
                showingAddSheet = false
            }
        }
        .sheet(isPresented: $showingGroupSheet) {
            VStack(spacing: 20) {
                Text("添加新分组")
                    .font(.headline)
                
                TextField("分组名称", text: $newGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                HStack {
                    Button("取消") {
                        showingGroupSheet = false
                        newGroupName = ""
                    }
                    
                    Button("添加") {
                        if !newGroupName.isEmpty {
                            groupManager.addGroup(name: newGroupName)
                            showingGroupSheet = false
                            newGroupName = ""
                        }
                    }
                    .disabled(newGroupName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300, height: 150)
        }
        .sheet(isPresented: Binding(
            get: { editingGroup != nil },
            set: { if !$0 { editingGroup = nil } }
        )) {
            if let group = editingGroup {
                VStack(spacing: 20) {
                    Text("重命名分组")
                        .font(.headline)
                    
                    TextField("分组名称", text: $newGroupName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                    
                    HStack {
                        Button("取消") {
                            editingGroup = nil
                            newGroupName = ""
                        }
                        
                        Button("保存") {
                            if !newGroupName.isEmpty {
                                var updatedGroup = group
                                updatedGroup.name = newGroupName
                                groupManager.updateGroup(updatedGroup)
                                editingGroup = nil
                                newGroupName = ""
                            }
                        }
                        .disabled(newGroupName.isEmpty)
                    }
                }
                .padding()
                .frame(width: 300, height: 150)
            }
        }
    }
}

/**
 * 网站列表行视图
 */
struct WebsiteRow: View {
    let website: Website
    let isEditing: Bool
    let onEdit: () -> Void
    let onSave: (String, String) -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    let onGroupSelect: (UUID) -> Void
    
    @StateObject private var groupManager = WebsiteGroupManager.shared
    @State private var icon: NSImage?
    @State private var editUrl: String = ""
    @State private var editName: String = ""
    
    // 获取网站所在的分组
    private var websiteGroups: [WebsiteGroup] {
        groupManager.getGroups(for: website.id)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 网站图标
            Group {
                if let icon = icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "globe")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 24)
            
            if isEditing {
                // 编辑模式
                VStack(alignment: .leading, spacing: 8) {
                    TextField("网站名称", text: $editName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("网站地址", text: $editUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Button("保存") {
                        onSave(editUrl, editName)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("取消") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // 显示模式
                VStack(alignment: .leading) {
                    Text(website.name)
                        .font(.headline)
                    Text(website.url)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack {
                    // 分组菜单
                    Menu {
                        if websiteGroups.isEmpty {
                            Text("未分组")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(websiteGroups) { group in
                                Button(action: {
                                    onGroupSelect(group.id)
                                }) {
                                    Label("从「\(group.name)」移除", systemImage: "minus.circle")
                                }
                            }
                            
                            if !websiteGroups.isEmpty {
                                Divider()
                            }
                        }
                        
                        ForEach(groupManager.groups.filter { group in
                            !websiteGroups.contains(where: { $0.id == group.id })
                        }) { group in
                            Button(action: {
                                onGroupSelect(group.id)
                            }) {
                                Label("添加到「\(group.name)」", systemImage: "plus.circle")
                            }
                        }
                    } label: {
                        HStack {
                            if websiteGroups.isEmpty {
                                Text("未分组")
                                    .foregroundColor(.secondary)
                            } else {
                                Text(websiteGroups.map { $0.name }.joined(separator: ", "))
                            }
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 150)
                    
                    Button(action: {
                        editUrl = website.url
                        editName = website.name
                        onEdit()
                    }) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            loadIcon()
        }
    }
    
    private func loadIcon() {
        Task {
            await website.fetchIcon { fetchedIcon in
                DispatchQueue.main.async {
                    self.icon = fetchedIcon
                }
            }
        }
    }
}

/**
 * 添加网站视图
 */
struct AddWebsiteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var url = ""
    @State private var name = ""
    @State private var icon: NSImage?
    let onAdd: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("添加新网站")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("网站地址", text: $url)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: url) { newValue in
                        if let urlObj = URL(string: newValue),
                           let host = urlObj.host {
                            name = host
                            fetchIcon(for: newValue)
                        }
                    }
                
                TextField("网站名称", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let icon = icon {
                    HStack {
                        Text("网站图标：")
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            
            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("添加") {
                    onAdd(url, name)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty || name.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private func fetchIcon(for url: String) {
        let dummyWebsite = Website(url: url, name: "")
        Task {
            await dummyWebsite.fetchIcon { fetchedIcon in
                DispatchQueue.main.async {
                    self.icon = fetchedIcon
                }
            }
        }
    }
} 