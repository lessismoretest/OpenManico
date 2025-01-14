import SwiftUI

struct AppSelectionView: View {
    let key: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = AppSettings.shared
    @State private var selectedTab = 0  // 0: 运行中, 1: 所有应用
    @State private var searchText = ""
    
    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications.filter { 
            $0.activationPolicy == .regular &&
            ($0.localizedName?.lowercased().contains(searchText.lowercased()) ?? false || searchText.isEmpty)
        }.sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }
    
    private func getAppsInDirectory(at url: URL) -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.localizedNameKey, .isApplicationKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        return contents.filter { url in
            guard url.pathExtension == "app" else { return false }
            guard let isApp = try? url.resourceValues(forKeys: [.isApplicationKey]).isApplication else { return false }
            guard isApp else { return false }
            
            if !searchText.isEmpty {
                guard let name = try? url.localizedName else { return false }
                return name.lowercased().contains(searchText.lowercased())
            }
            
            return true
        }.sorted {
            let name1 = (try? $0.localizedName) ?? ""
            let name2 = (try? $1.localizedName) ?? ""
            return name1 < name2
        }
    }
    
    private var allApps: [URL] {
        let systemApps = getAppsInDirectory(at: URL(fileURLWithPath: "/Applications"))
        let userApps = getAppsInDirectory(at: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"))
        return systemApps + userApps
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("选择要绑定到 Option + \(key) 的应用")
                .font(.headline)
                .padding()
            
            // 搜索栏
            TextField("搜索应用...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // 选项卡
            Picker("应用列表", selection: $selectedTab) {
                Text("运行中").tag(0)
                Text("所有应用").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // 应用列表
            if selectedTab == 0 {
                // 运行中的应用
                List {
                    ForEach(runningApps, id: \.bundleIdentifier) { app in
                        if let bundleId = app.bundleIdentifier {
                            AppRowView(
                                icon: app.icon,
                                name: app.localizedName ?? "未知应用",
                                bundleId: bundleId
                            ) {
                                addShortcut(bundleId: bundleId, name: app.localizedName ?? "未知应用")
                            }
                        }
                    }
                }
            } else {
                // 所有应用
                List {
                    ForEach(allApps, id: \.path) { appURL in
                        if let bundle = Bundle(url: appURL),
                           let bundleId = bundle.bundleIdentifier,
                           let name = try? appURL.localizedName {
                            AppRowView(
                                icon: NSWorkspace.shared.icon(forFile: appURL.path),
                                name: name,
                                bundleId: bundleId
                            ) {
                                addShortcut(bundleId: bundleId, name: name)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }
    
    private func addShortcut(bundleId: String, name: String) {
        // 创建快捷键
        let shortcut = AppShortcut(
            key: key,
            bundleIdentifier: bundleId,
            appName: name
        )
        
        // 直接保存快捷键设置
        settings.shortcuts.removeAll { $0.key == key }
        settings.shortcuts.append(shortcut)
        settings.saveSettings()
        dismiss()
    }
}

// 抽取的应用行视图组件
struct AppRowView: View {
    let icon: NSImage?
    let name: String
    let bundleId: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                VStack(alignment: .leading) {
                    Text(name)
                        .fontWeight(.medium)
                    Text(bundleId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// URL 扩展，用于获取本地化名称
extension URL {
    var localizedName: String? {
        get throws {
            try (resourceValues(forKeys: [.localizedNameKey]).localizedName)
        }
    }
} 