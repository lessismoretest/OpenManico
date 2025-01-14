import SwiftUI

struct ContentView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(destination: ShortcutsView()) {
                    Label("快捷键设置", systemImage: "keyboard")
                }
                .tag(0)
                
                NavigationLink(destination: SettingsView()) {
                    Label("通用设置", systemImage: "gear")
                }
                .tag(1)
            }
            .listStyle(SidebarListStyle())
            .frame(width: 200)
        } detail: {
            if selectedTab == 0 {
                ShortcutsView()
            } else {
                SettingsView()
            }
        }
        .frame(width: 900, height: 600)
        .navigationSplitViewStyle(.automatic)
    }
} 