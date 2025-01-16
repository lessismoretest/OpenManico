 import SwiftUI

/**
 * 导入设置视图
 */
struct ImportSettingsView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var webShortcutManager = HotKeyManager.shared.webShortcutManager
    @Environment(\.dismiss) private var dismiss
    
    let importData: ExportData
    @State private var selectedAppScenes: Set<UUID> = []
    @State private var selectedWebScenes: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("导入场景")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                if let appScenes = importData.appScenes, !appScenes.isEmpty {
                    // 应用场景选择
                    GroupBox("应用场景") {
                        ScrollView {
                            LazyVStack(alignment: .leading) {
                                ForEach(appScenes) { scene in
                                    SceneToggleRow(
                                        name: scene.name,
                                        isSelected: selectedAppScenes.contains(scene.id),
                                        onToggle: { isSelected in
                                            if isSelected {
                                                selectedAppScenes.insert(scene.id)
                                            } else {
                                                selectedAppScenes.remove(scene.id)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                if let webScenes = importData.webScenes, !webScenes.isEmpty {
                    // 网站场景选择
                    GroupBox("网站场景") {
                        ScrollView {
                            LazyVStack(alignment: .leading) {
                                ForEach(webScenes) { scene in
                                    SceneToggleRow(
                                        name: scene.name,
                                        isSelected: selectedWebScenes.contains(scene.id),
                                        onToggle: { isSelected in
                                            if isSelected {
                                                selectedWebScenes.insert(scene.id)
                                            } else {
                                                selectedWebScenes.remove(scene.id)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            
            HStack {
                Button("全选") {
                    if let appScenes = importData.appScenes {
                        selectedAppScenes = Set(appScenes.map { $0.id })
                    }
                    if let webScenes = importData.webScenes {
                        selectedWebScenes = Set(webScenes.map { $0.id })
                    }
                }
                
                Button("取消全选") {
                    selectedAppScenes.removeAll()
                    selectedWebScenes.removeAll()
                }
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
                
                Button("导入") {
                    importSelectedScenes()
                    dismiss()
                }
                .disabled(selectedAppScenes.isEmpty && selectedWebScenes.isEmpty)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 400)
    }
    
    private func importSelectedScenes() {
        // 导入选中的应用场景
        if let appScenes = importData.appScenes {
            let selectedScenes = appScenes.filter { selectedAppScenes.contains($0.id) }
            if !selectedScenes.isEmpty {
                // 将选中的场景添加到现有场景中
                var currentScenes = appSettings.scenes
                currentScenes.append(contentsOf: selectedScenes)
                appSettings.scenes = currentScenes
            }
        }
        
        // 导入选中的网站场景
        if let webScenes = importData.webScenes {
            let selectedScenes = webScenes.filter { selectedWebScenes.contains($0.id) }
            if !selectedScenes.isEmpty {
                // 将选中的场景添加到现有场景中
                var currentScenes = webShortcutManager.scenes
                currentScenes.append(contentsOf: selectedScenes)
                webShortcutManager.scenes = currentScenes
                webShortcutManager.saveShortcuts()
            }
        }
    }
}