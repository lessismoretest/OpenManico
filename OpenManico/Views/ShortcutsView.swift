import SwiftUI

struct ShortcutsView: View {
    @StateObject private var settings = AppSettings.shared
    
    private let availableKeys = (1...9).map(String.init) + (65...90).map { String(UnicodeScalar($0)) }
    
    var body: some View {
        VStack {
            List {
                ForEach(availableKeys, id: \.self) { key in
                    ShortcutRow(key: key)
                }
            }
            .listStyle(InsetListStyle())
        }
        .padding()
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