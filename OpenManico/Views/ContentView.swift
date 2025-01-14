import SwiftUI

struct ContentView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ShortcutsView()) {
                    Label("App快捷键", systemImage: "keyboard")
                }
                
                NavigationLink(destination: WebShortcutsView()) {
                    Label("网站快捷键", systemImage: "globe")
                }
                
                NavigationLink(destination: SettingsView()) {
                    Label("通用设置", systemImage: "gear")
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            
            Text("选择左侧选项进行设置")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
} 