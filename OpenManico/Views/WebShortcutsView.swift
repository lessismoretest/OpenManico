import SwiftUI

/**
 * 网站快捷键设置视图
 */
struct WebShortcutsView: View {
    @StateObject private var hotKeyManager = HotKeyManager.shared
    
    private let availableKeys = (1...9).map(String.init) + (65...90).map { String(UnicodeScalar($0)) }
    
    var body: some View {
        VStack {
            List {
                ForEach(availableKeys, id: \.self) { key in
                    WebShortcutRow(key: key, webShortcutManager: hotKeyManager.webShortcutManager)
                }
            }
            .listStyle(InsetListStyle())
        }
        .padding()
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
                        .frame(width: 16, height: 16)
                        .cornerRadius(2)
                } else {
                    Image(systemName: "globe")
                        .frame(width: 16, height: 16)
                }
                
                TextField("", text: .init(
                    get: { shortcut.url },
                    set: { newValue in
                        let updatedShortcut = WebShortcut(
                            id: shortcut.id,
                            key: shortcut.key,
                            url: newValue,
                            name: shortcut.name
                        )
                        webShortcutManager.updateShortcut(updatedShortcut)
                        loadIcon(for: updatedShortcut)
                    }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1)
                .truncationMode(.tail)
                
                Button("移除") {
                    webShortcutManager.deleteShortcut(shortcut)
                    icon = nil
                }
                .frame(width: 50)
            } else {
                TextField("输入网址", text: $url)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if !url.isEmpty {
                    Button("添加") {
                        let shortcut = WebShortcut(
                            key: key,
                            url: url,
                            name: URL(string: url)?.host ?? url
                        )
                        webShortcutManager.addShortcut(shortcut)
                        loadIcon(for: shortcut)
                        url = ""
                    }
                    .frame(width: 50)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if let shortcut = shortcut {
                loadIcon(for: shortcut)
            }
        }
    }
    
    private func loadIcon(for shortcut: WebShortcut) {
        shortcut.fetchIcon { fetchedIcon in
            self.icon = fetchedIcon
        }
    }
} 