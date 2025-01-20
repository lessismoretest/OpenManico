import SwiftUI
import AppKit

/**
 * 网站列表视图
 */
struct WebsiteListView: View {
    @StateObject private var websiteManager = WebsiteManager.shared
    @State private var searchText = ""
    @State private var editingWebsite: Website?
    @State private var showingAddSheet = false
    @State private var showingGroupManagement = false
    @State private var selectedGroup: UUID? = nil
    @State private var showingImportSheet = false
    
    // 添加视图显示范围追踪
    @State private var visibleRows: Set<UUID> = []
    
    private var filteredWebsites: [Website] {
        var websites = websiteManager.getWebsites(mode: .all, groupId: selectedGroup)
        
        // 如果有搜索文本，进行过滤
        if !searchText.isEmpty {
            websites = websites.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.url.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return websites.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 分组选择器
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 分组按钮
                        ForEach(websiteManager.groups) { group in
                            Button(action: { selectedGroup = group.id }) {
                                Text("\(group.name) (\(websiteManager.getWebsites(mode: .all, groupId: group.id).count))")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedGroup == group.id ? Color.blue : Color.gray.opacity(0.3))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.horizontal, 8)
                
                // 管理按钮
                Button(action: { showingGroupManagement = true }) {
                    Image(systemName: "folder.badge.gearshape")
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
            }
            .frame(height: 36)
            .padding(.vertical, 8)
            
            // 搜索和工具栏
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
                
                Spacer()
                
                Button(action: { showingImportSheet = true }) {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                
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
                    WebsiteRow(
                        website: website,
                        isEditing: editingWebsite?.id == website.id,
                        onEdit: { editingWebsite = website },
                        onSave: { name, url in
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
                        onGroupSelect: { website, groupId in
                            if website.groupIds.contains(groupId) {
                                websiteManager.removeWebsiteFromGroup(website.id, groupId: groupId)
                            } else {
                                websiteManager.addWebsiteToGroup(website.id, groupId: groupId)
                            }
                        },
                        isVisible: visibleRows.contains(website.id)
                    )
                    .id(website.id)
                    .onAppear {
                        visibleRows.insert(website.id)
                    }
                    .onDisappear {
                        visibleRows.remove(website.id)
                    }
                }
            }
            .listStyle(.inset)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddWebsiteView { url, name in
                let website = Website(url: url, name: name)
                websiteManager.addWebsite(website)
                // 添加到当前选中的分组
                if let groupId = selectedGroup {
                    websiteManager.addWebsiteToGroup(website.id, groupId: groupId)
                }
                showingAddSheet = false
            }
        }
        .sheet(isPresented: $showingGroupManagement) {
            GroupManagementView()
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportWebsitesView()
        }
        .onAppear {
            // 如果没有选中分组，选中第一个分组
            if selectedGroup == nil {
                selectedGroup = websiteManager.groups.first?.id
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
    let onGroupSelect: (Website, UUID) -> Void
    let isVisible: Bool
    
    @StateObject private var websiteManager = WebsiteManager.shared
    @ObservedObject private var iconManager = WebIconManager.shared
    @State private var editUrl: String = ""
    @State private var editName: String = ""
    
    private var websiteGroups: [WebsiteGroup] {
        websiteManager.groups.filter { website.groupIds.contains($0.id) }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 网站图标
            Group {
                if let icon = iconManager.icon(for: website.id) {
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
                        .textFieldStyle(.roundedBorder)
                    TextField("网站地址", text: $editUrl)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Button("保存") {
                            onSave(editName, editUrl)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("取消") {
                            onCancel()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .onAppear {
                    editName = website.name
                    editUrl = website.url
                }
            } else {
                // 显示模式
                VStack(alignment: .leading, spacing: 4) {
                    Text(website.name)
                        .lineLimit(1)
                    Text(website.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 分组菜单
                Menu {
                    if let currentGroup = websiteGroups.first {
                        Text("当前分组：\(currentGroup.name)")
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        ForEach(websiteManager.groups.filter { $0.id != currentGroup.id }) { group in
                            Button(action: {
                                onGroupSelect(website, group.id)
                            }) {
                                Label("移动到「\(group.name)」", systemImage: "arrow.right.circle")
                            }
                        }
                    } else {
                        Text("未分组")
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        ForEach(websiteManager.groups) { group in
                            Button(action: {
                                onGroupSelect(website, group.id)
                            }) {
                                Label("移动到「\(group.name)」", systemImage: "arrow.right.circle")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "folder")
                }
                .menuStyle(.borderlessButton)
                
                // 快捷键标识
                if website.shortcutKey != nil {
                    Image(systemName: "command")
                        .foregroundColor(.secondary)
                }
                
                // 操作按钮
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
        .onChange(of: isVisible) { newValue in
            if newValue {
                iconManager.loadIcon(for: website)
            } else {
                iconManager.cancelLoading(for: website.id)
            }
        }
    }
}

/**
 * 添加网站视图
 */
struct AddWebsiteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var websiteManager = WebsiteManager.shared
    @State private var url = ""
    @State private var name = ""
    @State private var icon: NSImage?
    @State private var selectedGroupId: UUID?
    @State private var showingGroupManagement = false
    let onAdd: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("添加新网站")
                .font(.headline)
            
            // 分组选择
            HStack {
                Menu {
                    ForEach(websiteManager.groups) { group in
                        Button(action: {
                            selectedGroupId = group.id
                        }) {
                            if selectedGroupId == group.id {
                                Label(group.name, systemImage: "checkmark")
                            } else {
                                Text(group.name)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: { showingGroupManagement = true }) {
                        Label("管理分组...", systemImage: "folder.badge.gearshape")
                    }
                } label: {
                    HStack {
                        Text(selectedGroupId.flatMap { id in
                            websiteManager.groups.first { $0.id == id }?.name
                        } ?? "选择分组")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 200)
            }
            
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
                    let website = Website(url: url, name: name)
                    websiteManager.addWebsite(website)
                    // 添加到选中的分组，如果没有选择分组则添加到默认分组
                    let groupId = selectedGroupId ?? websiteManager.groups.first?.id
                    if let groupId = groupId {
                        websiteManager.addWebsiteToGroup(website.id, groupId: groupId)
                    }
                    onAdd(url, name)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty || name.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            // 默认选中第一个分组（常用）
            if selectedGroupId == nil {
                selectedGroupId = websiteManager.groups.first?.id
            }
        }
        .sheet(isPresented: $showingGroupManagement) {
            GroupManagementView()
        }
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

// 滚动检测扩展
extension View {
    func onScrollStarted(perform action: @escaping () -> Void) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    action()
                }
        )
    }
    
    func onScrollEnded(perform action: @escaping () -> Void) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    action()
                }
        )
    }
} 