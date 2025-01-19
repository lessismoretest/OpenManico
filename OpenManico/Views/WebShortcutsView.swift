import SwiftUI

/**
 * 网站快捷键设置视图
 */
struct WebShortcutsView: View {
    @StateObject private var webShortcutManager = HotKeyManager.shared.webShortcutManager
    @StateObject private var websiteManager = WebsiteManager.shared
    @State private var showingAddScene = false
    @State private var showingRenameScene = false
    @State private var newSceneName = ""
    @State private var sceneToRename: WebScene?
    @State private var showingWebsiteSelector = false
    @State private var selectedKey = ""
    
    private let availableKeys = (1...9).map(String.init) + (65...90).map { String(UnicodeScalar($0)) }
    
    var body: some View {
        VStack(spacing: 16) {
            // 场景选择器
            HStack {
                Picker("场景", selection: Binding(
                    get: { webShortcutManager.currentScene ?? webShortcutManager.scenes.first ?? WebScene(name: "默认场景", shortcuts: []) },
                    set: { webShortcutManager.switchScene(to: $0) }
                )) {
                    ForEach(webShortcutManager.scenes.isEmpty ? [WebScene(name: "默认场景", shortcuts: [])] : webShortcutManager.scenes) { scene in
                        Text(scene.name).tag(scene)
                    }
                }
                .frame(width: 200)
                
                Button(action: {
                    if let currentScene = webShortcutManager.currentScene {
                        sceneToRename = currentScene
                        newSceneName = currentScene.name
                        showingRenameScene = true
                    }
                }) {
                    Image(systemName: "pencil.circle")
                }
                .help("重命名当前场景")
                .disabled(webShortcutManager.currentScene == nil)
                
                Button(action: {
                    if let currentScene = webShortcutManager.currentScene {
                        webShortcutManager.duplicateScene(currentScene)
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .help("复制当前场景")
                .disabled(webShortcutManager.currentScene == nil)
                
                Button(action: {
                    showingAddScene = true
                }) {
                    Image(systemName: "plus.circle")
                }
                .help("添加新场景")
                
                if webShortcutManager.scenes.count > 1 {
                    Button(action: {
                        if let currentScene = webShortcutManager.currentScene {
                            webShortcutManager.removeScene(currentScene)
                        }
                    }) {
                        Image(systemName: "minus.circle")
                    }
                    .help("删除当前场景")
                }
            }
            .padding(.bottom, 8)
            
            List {
                ForEach(availableKeys, id: \.self) { key in
                    WebShortcutRow(key: key,
                                 webShortcutManager: webShortcutManager,
                                 websiteManager: websiteManager,
                                 onAdd: {
                        selectedKey = key
                        showingWebsiteSelector = true
                    })
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
                            webShortcutManager.addScene(name: newSceneName)
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
                            webShortcutManager.renameScene(scene, to: newSceneName)
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
        .sheet(isPresented: $showingWebsiteSelector) {
            WebsiteSelectorView(selectedKey: selectedKey) { website in
                webShortcutManager.addShortcut(key: selectedKey, website: website)
                showingWebsiteSelector = false
            }
        }
    }
}

/**
 * 网站快捷键行视图
 */
struct WebShortcutRow: View {
    let key: String
    @ObservedObject var webShortcutManager: WebShortcutManager
    @ObservedObject var websiteManager: WebsiteManager
    let onAdd: () -> Void
    
    @State private var icon: NSImage?
    
    private var shortcut: WebShortcut? {
        webShortcutManager.shortcuts.first { $0.key == key }
    }
    
    private var website: Website? {
        if let shortcut = shortcut {
            return websiteManager.findWebsite(id: shortcut.websiteId)
        }
        return nil
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Option + Command + \(key)")
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .fixedSize()
            
            if let website = website {
                if let icon = icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
                
                Text(website.name)
                    .foregroundColor(.secondary)
                Spacer()
                Button("删除") {
                    if let shortcut = shortcut {
                        webShortcutManager.deleteShortcut(shortcut)
                    }
                }
            } else {
                Button("添加") {
                    onAdd()
                }
            }
        }
        .onAppear {
            loadIcon()
        }
        .onChange(of: shortcut) { _ in
            loadIcon()
        }
    }
    
    private func loadIcon() {
        icon = nil
        if let website = website {
            Task {
                await website.fetchIcon { fetchedIcon in
                    DispatchQueue.main.async {
                        self.icon = fetchedIcon
                    }
                }
            }
        }
    }
}

/**
 * 网站选择器视图
 */
struct WebsiteSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var websiteManager = WebsiteManager.shared
    @State private var searchText = ""
    let selectedKey: String
    let onSelect: (Website) -> Void
    
    private var filteredWebsites: [Website] {
        if searchText.isEmpty {
            return websiteManager.websites.sorted { $0.name < $1.name }
        }
        return websiteManager.websites.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
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
            .padding()
            
            Divider()
            
            // 网站列表
            List(filteredWebsites) { website in
                WebsiteSelectorRow(website: website) {
                    onSelect(website)
                }
            }
            .listStyle(InsetListStyle())
        }
        .frame(width: 400, height: 500)
    }
}

/**
 * 网站选择器行视图
 */
struct WebsiteSelectorRow: View {
    let website: Website
    let onSelect: () -> Void
    @State private var icon: NSImage?
    
    var body: some View {
        Button(action: onSelect) {
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
                
                VStack(alignment: .leading) {
                    Text(website.name)
                        .font(.headline)
                    Text(website.url)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
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