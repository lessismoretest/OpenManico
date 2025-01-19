import SwiftUI

struct ContentView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var selectedTab = 0
    @State private var isSidebarExpanded = true
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ShortcutsView()
                    .navigationTitle("App快捷键")) {
                    Label("App快捷键", systemImage: "keyboard")
                }
                
                NavigationLink(destination: WebShortcutsView()
                    .navigationTitle("网站快捷键")) {
                    Label("网站快捷键", systemImage: "globe")
                }
                
                NavigationLink(destination: WebsiteListView()
                    .navigationTitle("网站列表")) {
                    Label("网站列表", systemImage: "list.bullet")
                }
                
                NavigationLink(destination: AppListView()
                    .navigationTitle("应用列表")) {
                    Label("应用列表", systemImage: "square.grid.2x2")
                }
                
                NavigationLink(destination: FloatingWindowSettingsView()
                    .navigationTitle("悬浮窗")) {
                    Label("悬浮窗", systemImage: "rectangle.on.rectangle")
                }
                
                NavigationLink(destination: SettingsView()
                    .navigationTitle("通用设置")) {
                    Label("通用设置", systemImage: "gear")
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text("选择左侧选项进行设置")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("OpenManico")
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
} 