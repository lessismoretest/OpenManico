import SwiftUI

/**
 * 导出设置视图
 */
struct ExportSettingsView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var webShortcutManager = HotKeyManager.shared.webShortcutManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAppScenes: Set<UUID> = []
    @State private var selectedWebScenes: Set<UUID> = []
    @State private var showingSavePanel = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("导出场景")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                // 应用场景选择
                GroupBox("应用场景") {
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(appSettings.scenes) { scene in
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
                
                // 网站场景选择
                GroupBox("网站场景") {
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(webShortcutManager.scenes) { scene in
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
            
            HStack {
                Button("全选") {
                    selectedAppScenes = Set(appSettings.scenes.map { $0.id })
                    selectedWebScenes = Set(webShortcutManager.scenes.map { $0.id })
                }
                
                Button("取消全选") {
                    selectedAppScenes.removeAll()
                    selectedWebScenes.removeAll()
                }
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
                
                Button("导出") {
                    showingSavePanel = true
                }
                .disabled(selectedAppScenes.isEmpty && selectedWebScenes.isEmpty)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 400)
        .onChange(of: showingSavePanel) { show in
            if show {
                exportSelectedScenes()
            }
        }
    }
    
    private func exportSelectedScenes() {
        let selectedApps = appSettings.scenes.filter { selectedAppScenes.contains($0.id) }
        let selectedWebs = webShortcutManager.scenes.filter { selectedWebScenes.contains($0.id) }
        
        guard let exportData = ExportManager.shared.exportScenes(
            appScenes: selectedApps.isEmpty ? nil : selectedApps,
            webScenes: selectedWebs.isEmpty ? nil : selectedWebs
        ) else {
            // 处理导出失败
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        savePanel.nameFieldStringValue = "OpenManico_Scenes_\(dateFormatter.string(from: Date()))"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try exportData.write(to: url)
                } catch {
                    // 处理保存失败
                    print("Failed to save file: \(error)")
                }
            }
            showingSavePanel = false
        }
    }
}

/// 场景切换行视图
struct SceneToggleRow: View {
    let name: String
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { isSelected },
            set: { onToggle($0) }
        )) {
            Text(name)
        }
    }
} 