import SwiftUI

struct ShortcutsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var showingAddShortcut = false
    @State private var showingImportDialog = false
    @State private var showingExportDialog = false
    @State private var showingAddScene = false
    @State private var showingRenameScene = false
    @State private var newSceneName = ""
    @State private var sceneToRename: Scene?
    
    private let availableKeys = (1...9).map(String.init) + (65...90).map { String(UnicodeScalar($0)) }
    
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
                ForEach(availableKeys, id: \.self) { key in
                    ShortcutRow(key: key)
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
        // 监听快捷键变化
        .onChange(of: settings.shortcuts) { _ in
            settings.updateCurrentSceneShortcuts()
        }
    }
}

struct ShortcutRow: View {
    let key: String
    @StateObject private var settings = AppSettings.shared
    @State private var isSelectingApp = false
    
    private var shortcut: AppShortcut? {
        settings.shortcuts.first { $0.key == key }
    }
    
    var body: some View {
        HStack {
            Text("Option + \(key)")
                .frame(width: 100, alignment: .leading)
            
            if let shortcut = shortcut,
               let app = NSRunningApplication.runningApplications(withBundleIdentifier: shortcut.bundleIdentifier).first {
                HStack {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    Text(shortcut.appName)
                }
                .frame(width: 200, alignment: .leading)
                
                Button("移除") {
                    settings.shortcuts.removeAll { $0.key == key }
                    settings.saveSettings()
                }
            } else {
                Button("选择应用") {
                    isSelectingApp.toggle()
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $isSelectingApp) {
            AppSelectionView(key: key)
        }
    }
} 