import SwiftUI

/**
 * 网站快捷键设置视图
 */
struct WebShortcutsView: View {
    @StateObject private var hotKeyManager = HotKeyManager.shared
    @State private var showingAddScene = false
    @State private var newSceneName = ""
    @State private var selectedSceneId: UUID?
    
    private let availableKeys = (1...9).map(String.init) + (65...90).map { String(UnicodeScalar($0)) }
    
    var body: some View {
        VStack(spacing: 16) {
            // 场景选择器
            HStack {
                Picker("场景", selection: Binding(
                    get: { selectedSceneId ?? hotKeyManager.webShortcutManager.currentScene?.id ?? UUID() },
                    set: { newId in
                        selectedSceneId = newId
                        if let scene = hotKeyManager.webShortcutManager.scenes.first(where: { $0.id == newId }) {
                            hotKeyManager.webShortcutManager.switchScene(to: scene)
                        }
                    }
                )) {
                    ForEach(hotKeyManager.webShortcutManager.scenes) { scene in
                        Text(scene.name).tag(scene.id)
                    }
                }
                .frame(width: 200)
                .onChange(of: hotKeyManager.webShortcutManager.currentScene?.id) { newId in
                    selectedSceneId = newId
                }
                
                Button(action: {
                    showingAddScene = true
                }) {
                    Image(systemName: "plus.circle")
                }
                .help("添加新场景")
                
                if hotKeyManager.webShortcutManager.scenes.count > 1 {
                    Button(action: {
                        if let currentScene = hotKeyManager.webShortcutManager.currentScene {
                            hotKeyManager.webShortcutManager.removeScene(currentScene)
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
                    WebShortcutRow(key: key, webShortcutManager: hotKeyManager.webShortcutManager)
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
                            hotKeyManager.webShortcutManager.addScene(name: newSceneName)
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
        // 监听快捷键变化
        .onChange(of: hotKeyManager.webShortcutManager.shortcuts) { _ in
            hotKeyManager.webShortcutManager.updateCurrentSceneShortcuts()
        }
    }
}

/**
 * 网站快捷键行视图
 */
struct WebShortcutRow: View {
    let key: String
    @ObservedObject var webShortcutManager: WebShortcutManager
    @State private var isEditing = false
    @State private var url = ""
    @State private var icon: NSImage?
    
    private var shortcut: WebShortcut? {
        webShortcutManager.shortcuts.first { $0.key == key }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Option + Command + \(key)")
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .fixedSize()
            
            if let shortcut = shortcut {
                if let icon = icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
                
                if isEditing {
                    TextField("输入网址", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            updateShortcut()
                        }
                } else {
                    Text(shortcut.name)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("编辑") {
                        url = shortcut.url
                        isEditing = true
                    }
                    Button("删除") {
                        removeShortcut()
                    }
                }
            } else {
                if isEditing {
                    TextField("输入网址", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addShortcut()
                        }
                } else {
                    Button("添加") {
                        isEditing = true
                    }
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
        
        guard let shortcut = shortcut else { return }
        
        Task {
            await shortcut.fetchIcon { newIcon in
                DispatchQueue.main.async {
                    self.icon = newIcon
                }
            }
        }
    }
    
    private func addShortcut() {
        guard !url.isEmpty else { return }
        
        let name = URL(string: url)?.host ?? url
        let shortcut = WebShortcut(key: key, url: url, name: name)
        webShortcutManager.shortcuts.append(shortcut)
        webShortcutManager.saveShortcuts()
        
        isEditing = false
        loadIcon()
    }
    
    private func updateShortcut() {
        guard !url.isEmpty else { return }
        
        let name = URL(string: url)?.host ?? url
        let shortcut = WebShortcut(key: key, url: url, name: name)
        
        if let index = webShortcutManager.shortcuts.firstIndex(where: { $0.key == key }) {
            webShortcutManager.shortcuts[index] = shortcut
            webShortcutManager.saveShortcuts()
        }
        
        isEditing = false
        loadIcon()
    }
    
    private func removeShortcut() {
        webShortcutManager.shortcuts.removeAll { $0.key == key }
        webShortcutManager.saveShortcuts()
        icon = nil
    }
} 