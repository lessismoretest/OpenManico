import SwiftUI

/**
 * 网站快捷键视图
 */
struct WebShortcutsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var websiteManager = WebsiteManager.shared
    @State private var showingAddScene = false
    @State private var showingRenameScene = false
    @State private var newSceneName = ""
    @State private var sceneToRename: Scene?
    
    private let keys = (1...9).map(String.init) + (65...90).map { String(UnicodeScalar($0)) }
    
    var body: some View {
        VStack(spacing: 16) {
            // 场景选择器
            HStack {
                Picker("场景", selection: Binding(
                    get: { settings.currentScene ?? settings.scenes.first ?? Scene(name: "", shortcuts: []) },
                    set: { settings.switchScene(to: $0) }
                )) {
                    ForEach(settings.scenes) { scene in
                        Text(scene.name).tag(scene)
                    }
                }
                .frame(width: 200)
                
                Button(action: {
                    if let currentScene = settings.currentScene {
                        sceneToRename = currentScene
                        newSceneName = currentScene.name
                        showingRenameScene = true
                    }
                }) {
                    Image(systemName: "pencil.circle")
                }
                .help("重命名当前场景")
                .disabled(settings.currentScene == nil)
                
                Button(action: {
                    if let currentScene = settings.currentScene {
                        settings.duplicateScene(currentScene)
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .help("复制当前场景")
                .disabled(settings.currentScene == nil)
                
                Button(action: {
                    showingAddScene = true
                }) {
                    Image(systemName: "plus.circle")
                }
                .help("添加新场景")
                
                if settings.scenes.count > 1 {
                    Button(action: {
                        if let currentScene = settings.currentScene {
                            settings.removeScene(currentScene)
                        }
                    }) {
                        Image(systemName: "minus.circle")
                    }
                    .help("删除当前场景")
                }
            }
            .padding(.horizontal)
            
            List {
                ForEach(keys, id: \.self) { key in
                    WebShortcutRow(key: key)
                }
            }
            .listStyle(InsetListStyle())
        }
        .padding()
        .sheet(isPresented: $showingAddScene) {
            VStack(spacing: 20) {
                Text("添加新场景")
                    .font(.headline)
                
                TextField("场景名称", text: $newSceneName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                HStack {
                    Button("取消") {
                        showingAddScene = false
                        newSceneName = ""
                    }
                    
                    Button("添加") {
                        if !newSceneName.isEmpty {
                            settings.addScene(name: newSceneName)
                            showingAddScene = false
                            newSceneName = ""
                        }
                    }
                    .disabled(newSceneName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300, height: 150)
        }
        .sheet(isPresented: $showingRenameScene) {
            VStack(spacing: 20) {
                Text("重命名场景")
                    .font(.headline)
                
                TextField("场景名称", text: $newSceneName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                HStack {
                    Button("取消") {
                        showingRenameScene = false
                        newSceneName = ""
                        sceneToRename = nil
                    }
                    
                    Button("确定") {
                        if !newSceneName.isEmpty, let scene = sceneToRename {
                            settings.renameScene(scene, to: newSceneName)
                            showingRenameScene = false
                            newSceneName = ""
                            sceneToRename = nil
                        }
                    }
                    .disabled(newSceneName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300, height: 150)
        }
    }
}

/**
 * 网站快捷键行视图
 */
struct WebShortcutRow: View {
    let key: String
    @StateObject private var websiteManager = WebsiteManager.shared
    @StateObject private var hotKeyManager = HotKeyManager.shared
    @State private var showingWebsiteSelector = false
    
    private var website: Website? {
        websiteManager.getWebsites(mode: .all).first { $0.shortcutKey == key }
    }
    
    private var keyText: String {
        if let num = Int(key) {
            return "Option + Command + \(num)"
        } else {
            return "Option + Command + \(key)"
        }
    }
    
    var body: some View {
        HStack {
            Text(keyText)
                .frame(width: 180, alignment: .leading)
                .font(.system(.body, design: .monospaced))
            
            if let website = website {
                HStack {
                    if let icon = WebIconManager.shared.icon(for: website.id) {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "globe")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    Text(website.name)
                }
                .frame(width: 200, alignment: .leading)
                
                Button("移除") {
                    var updatedWebsite = website
                    updatedWebsite.shortcutKey = nil
                    websiteManager.updateWebsite(updatedWebsite)
                    hotKeyManager.updateShortcuts()
                }
            } else {
                Button("选择网站") {
                    showingWebsiteSelector.toggle()
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingWebsiteSelector) {
            WebsiteSelectorView(key: key)
        }
    }
}

/**
 * 网站选择器视图
 */
struct WebsiteSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var websiteManager = WebsiteManager.shared
    @StateObject private var hotKeyManager = HotKeyManager.shared
    @StateObject private var settings = AppSettings.shared
    let key: String
    @State private var searchText = ""
    @State private var selectedGroup: UUID
    @State private var showingAddSheet = false
    
    init(key: String) {
        self.key = key
        // 初始化时设置默认分组
        _selectedGroup = State(initialValue: WebsiteManager.shared.groups.first?.id ?? UUID())
    }
    
    var filteredWebsites: [Website] {
        // 获取当前选中分组的网站
        let websites = websiteManager.getWebsites(mode: .all, groupId: selectedGroup)
        if searchText.isEmpty {
            return websites
        }
        return websites.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // 检查网站是否已被绑定为快捷键
    private func isWebsiteSelected(website: Website) -> Bool {
        return website.shortcutKey != nil
    }
    
    var body: some View {
        VStack {
            // 分组选择器
            HStack {
                Picker("分组", selection: $selectedGroup) {
                    ForEach(websiteManager.groups) { group in
                        Text(group.name).tag(group.id)
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
                
                Button(action: {
                    // 关闭当前选择器
                    dismiss()
                    // 切换到网站列表页面并打开新建对话框
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SwitchToWebsiteList"),
                        object: nil,
                        userInfo: ["showAddSheet": true]
                    )
                }) {
                    Image(systemName: "plus.circle")
                }
                .help("添加新网站")
            }
            .padding()
            
            TextField("搜索网站", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            List(filteredWebsites) { website in
                Button(action: {
                    var updatedWebsite = website
                    updatedWebsite.shortcutKey = key
                    websiteManager.updateWebsite(updatedWebsite)
                    hotKeyManager.updateShortcuts()
                    dismiss()
                }) {
                    HStack {
                        if let icon = WebIconManager.shared.icon(for: website.id) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "globe")
                                .frame(width: 20, height: 20)
                        }
                        VStack(alignment: .leading) {
                            Text(website.name)
                            Text(website.url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // 显示已绑定快捷键标识
                        if isWebsiteSelected(website: website) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 500, height: 300)
    }
} 