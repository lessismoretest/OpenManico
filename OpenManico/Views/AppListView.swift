import SwiftUI

/**
 * 应用列表视图
 */
struct AppListView: View {
    @StateObject private var groupManager = AppGroupManager.shared
    @State private var searchText = ""
    @State private var selectedApps: Set<String> = []
    @State private var installedApps: [AppInfo] = []
    @State private var isLoading = false
    @State private var showingGroupSheet = false
    @State private var newGroupName = ""
    @State private var selectedGroup: AppGroup?
    @State private var showingNewGroupSheet = false
    @State private var isScanning = false
    @State private var showingGroupManagement = false
    
    var filteredApps: [AppInfo] {
        var apps = installedApps
        
        // 如果选择了分组，只显示分组内的应用
        if let group = selectedGroup {
            let groupBundleIds = Set(group.apps.map { $0.bundleId })
            apps = apps.filter { groupBundleIds.contains($0.bundleId) }
        }
        
        // 搜索过滤
        if !searchText.isEmpty {
            apps = apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return apps
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 分组列表
            if !groupManager.groups.isEmpty {
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // 全部应用按钮
                            Button(action: { selectedGroup = nil }) {
                                Text("全部")
                                    .foregroundColor(selectedGroup == nil ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedGroup == nil ? Color.blue : Color(NSColor.controlBackgroundColor))
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            // 分组按钮
                            ForEach(groupManager.groups) { group in
                                Button(action: { selectedGroup = group }) {
                                    HStack {
                                        Text("\(group.name) (\(group.apps.count))")
                                    }
                                    .foregroundColor(selectedGroup?.id == group.id ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedGroup?.id == group.id ? Color.blue : Color(NSColor.controlBackgroundColor))
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
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("管理分组")
                    .padding(.trailing, 12)
                }
                .frame(height: 36)
                .padding(.vertical, 8)
            }
            
            // 搜索框和刷新按钮
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索应用...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Button(action: scanApps) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(isScanning ? 360 : 0))
                        .animation(isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isScanning)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isScanning)
            }
            .padding()
            
            // 应用列表
            if isLoading {
                ProgressView("扫描应用中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredApps, id: \.bundleId, selection: $selectedApps) {
                    AppRow(app: $0, installedApps: installedApps)
                }
                .listStyle(.inset)
            }
        }
        .onAppear {
            scanInstalledApps()
        }
        .sheet(isPresented: $showingGroupSheet) {
            VStack(spacing: 20) {
                Text("重命名分组")
                    .font(.headline)
                
                TextField("分组名称", text: $newGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                HStack {
                    Button("取消") {
                        showingGroupSheet = false
                        newGroupName = ""
                    }
                    
                    Button("保存") {
                        if !newGroupName.isEmpty {
                            if let group = selectedGroup {
                                renameGroup(group: group, to: newGroupName)
                            }
                            showingGroupSheet = false
                            newGroupName = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newGroupName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300, height: 150)
        }
        .sheet(isPresented: $showingNewGroupSheet) {
            VStack(spacing: 20) {
                Text("创建应用分组")
                    .font(.headline)
                
                TextField("分组名称", text: $newGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                HStack {
                    Button("取消") {
                        showingNewGroupSheet = false
                        newGroupName = ""
                    }
                    
                    Button("创建") {
                        if !newGroupName.isEmpty {
                            groupManager.createGroup(name: newGroupName, apps: [])
                            showingNewGroupSheet = false
                            newGroupName = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newGroupName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300, height: 150)
        }
        .sheet(isPresented: $showingGroupManagement) {
            AppGroupManagementView()
        }
    }
    
    private func scanInstalledApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. 使用当前的扫描方法（扫描目录）
            let systemApps = getAppsInDirectory(at: URL(fileURLWithPath: "/Applications"))
            let systemAppsDir = getAppsInDirectory(at: URL(fileURLWithPath: "/System/Applications"))
            let systemUtilitiesDir = getAppsInDirectory(at: URL(fileURLWithPath: "/System/Applications/Utilities"))
            let userApps = getAppsInDirectory(at: URL(fileURLWithPath: NSString(string: "~/Applications").expandingTildeInPath))
            
            // 2. 转换为AppInfo对象
            var apps = (systemApps + systemAppsDir + systemUtilitiesDir + userApps).compactMap { url -> AppInfo? in
                // 尝试通过Bundle获取信息
                if let bundle = Bundle(url: url),
                   let bundleId = bundle.bundleIdentifier,
                   let name = bundle.infoDictionary?["CFBundleName"] as? String ?? 
                              bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                              url.deletingPathExtension().lastPathComponent as String? {
                    let icon = NSWorkspace.shared.icon(forFile: url.path)
                    return AppInfo(bundleId: bundleId, name: name, icon: icon, url: url)
                }
                return nil
            }
            
            // 3. 使用NSWorkspace API获取可运行应用（如果系统支持）
            if #available(macOS 12.0, *) {
                // 在Monterey及以上版本使用新API
                let workspace = NSWorkspace.shared
                let fileURL = URL(fileURLWithPath: NSHomeDirectory())  // 使用任何文件作为参考
                if let appURLs = workspace.urlsForApplications(toOpen: fileURL) as? [URL] {
                    for appURL in appURLs {
                        // 避免重复添加
                        if let bundle = Bundle(url: appURL),
                           let bundleID = bundle.bundleIdentifier,
                           !bundleID.isEmpty && !apps.contains(where: { $0.bundleId == bundleID }),
                           let name = bundle.infoDictionary?["CFBundleName"] as? String ?? 
                                     bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                                     appURL.deletingPathExtension().lastPathComponent as String? {
                            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                            apps.append(AppInfo(bundleId: bundleID, name: name, icon: icon, url: appURL))
                        }
                    }
                }
            }
            
            // 4. 添加常用系统应用
            let commonSystemApps = [
                ("com.apple.finder", "访达", "Finder"),
                ("com.apple.systempreferences", "系统设置", "System Settings"),
                ("com.apple.Safari", "Safari", "Safari"),
                ("com.apple.mail", "邮件", "Mail"),
                ("com.apple.iCal", "日历", "Calendar"),
                ("com.apple.Photos", "照片", "Photos"),
                ("com.apple.iWork.Pages", "Pages", "Pages"),
                ("com.apple.iWork.Numbers", "Numbers", "Numbers"),
                ("com.apple.iWork.Keynote", "Keynote", "Keynote"),
                ("com.apple.Notes", "备忘录", "Notes"),
                ("com.apple.iMovie", "iMovie", "iMovie"),
                ("com.apple.Music", "音乐", "Music"),
                ("com.apple.Maps", "地图", "Maps"),
                ("com.apple.AppStore", "App Store", "App Store"),
                ("com.apple.TextEdit", "文本编辑", "TextEdit"),
                ("com.apple.Terminal", "终端", "Terminal")
            ]
            
            for (bundleId, localizedName, englishName) in commonSystemApps {
                // 检查是否已经添加
                if !apps.contains(where: { $0.bundleId == bundleId }) {
                    // 尝试获取应用URL
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                        let icon = NSWorkspace.shared.icon(forFile: url.path)
                        apps.append(AppInfo(bundleId: bundleId, name: localizedName, icon: icon, url: url))
                    }
                }
            }
            
            DispatchQueue.main.async {
                installedApps = apps.sorted { $0.name < $1.name }
            }
        }
    }
    
    private func getAppsInDirectory(at url: URL) -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isApplicationKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        return contents.filter { url in
            guard url.pathExtension == "app" else { return false }
            guard let isApp = try? url.resourceValues(forKeys: [.isApplicationKey]).isApplication else { return false }
            return isApp
        }
    }
    
    private func createGroup(name: String) {
        // 获取选中的应用
        let selectedAppInfos = installedApps.filter { selectedApps.contains($0.bundleId) }
        // 创建新分组
        groupManager.createGroup(name: name, apps: selectedAppInfos)
        selectedApps.removeAll()
    }
    
    private func renameGroup(group: AppGroup, to newName: String) {
        groupManager.renameGroup(group, to: newName)
        if selectedGroup?.id == group.id {
            selectedGroup = groupManager.groups.first { $0.id == group.id }
        }
    }
    
    private func scanApps() {
        isScanning = true
        scanInstalledApps()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isScanning = false
        }
    }
    
    private func removeSelectedAppsFromGroup(_ group: AppGroup) {
        let updatedApps = group.apps.filter { !selectedApps.contains($0.bundleId) }
        groupManager.updateGroupApps(group, apps: updatedApps.map { item in
            if let existingApp = installedApps.first(where: { $0.bundleId == item.bundleId }) {
                return existingApp
            }
            return AppInfo(bundleId: item.bundleId, name: item.name, icon: NSImage(named: NSImage.applicationIconName)!, url: nil)
        })
        selectedApps.removeAll()
    }
}

/**
 * 应用行视图
 */
struct AppRow: View {
    @StateObject private var groupManager = AppGroupManager.shared
    @State private var showingNewGroupSheet = false
    @State private var newGroupName = ""
    let app: AppInfo
    let installedApps: [AppInfo]
    
    // 获取应用所在的分组
    private var appGroups: [AppGroup] {
        groupManager.groups.filter { group in
            group.apps.contains { $0.bundleId == app.bundleId }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .fontWeight(.medium)
                Text(app.bundleId)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 分组菜单
            Menu {
                if appGroups.isEmpty {
                    Text("未分组")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(appGroups) { group in
                        Button(action: {
                            removeFromGroup(group)
                        }) {
                            Label("从「\(group.name)」移除", systemImage: "minus.circle")
                        }
                    }
                }
                
                Divider()
                
                ForEach(groupManager.groups.filter { group in
                    !appGroups.contains(where: { $0.id == group.id })
                }) { group in
                    Button(action: {
                        addToGroup(group)
                    }) {
                        Label("添加到「\(group.name)」", systemImage: "plus.circle")
                    }
                }
                
                if !groupManager.groups.isEmpty {
                    Divider()
                }
                
                Button(action: {
                    createNewGroup()
                }) {
                    Label("创建新分组...", systemImage: "folder.badge.plus")
                }
            } label: {
                HStack {
                    if appGroups.isEmpty {
                        Text("未分组")
                            .foregroundColor(.secondary)
                    } else {
                        Text(appGroups.map { $0.name }.joined(separator: ", "))
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
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingNewGroupSheet) {
            VStack(spacing: 20) {
                Text("创建应用分组")
                    .font(.headline)
                
                TextField("分组名称", text: $newGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                HStack {
                    Button("取消") {
                        showingNewGroupSheet = false
                        newGroupName = ""
                    }
                    
                    Button("创建") {
                        if !newGroupName.isEmpty {
                            groupManager.createGroup(name: newGroupName, apps: [])
                            showingNewGroupSheet = false
                            newGroupName = ""
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
    
    private func addToGroup(_ group: AppGroup) {
        var updatedApps = group.apps
        updatedApps.append(AppGroupItem(bundleId: app.bundleId, name: app.name))
        groupManager.updateGroupApps(group, apps: updatedApps.map { item in
            // 如果是新添加的应用，使用当前应用的图标和URL
            if item.bundleId == app.bundleId {
                return app
            }
            // 对于其他应用，保持原有的图标和URL
            if let existingApp = installedApps.first(where: { $0.bundleId == item.bundleId }) {
                return existingApp
            }
            // 如果找不到应用信息，使用默认图标
            return AppInfo(bundleId: item.bundleId, name: item.name, icon: NSImage(named: NSImage.applicationIconName)!, url: nil)
        })
    }
    
    private func removeFromGroup(_ group: AppGroup) {
        let updatedApps = group.apps.filter { $0.bundleId != app.bundleId }
        groupManager.updateGroupApps(group, apps: updatedApps.map { item in
            if let existingApp = installedApps.first(where: { $0.bundleId == item.bundleId }) {
                return existingApp
            }
            return AppInfo(bundleId: item.bundleId, name: item.name, icon: NSImage(named: NSImage.applicationIconName)!, url: nil)
        })
    }
    
    private func createNewGroup() {
        showingNewGroupSheet = true
    }
} 