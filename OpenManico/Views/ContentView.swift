import SwiftUI

struct ContentView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var selectedTab = 0
    @State private var isSidebarExpanded = true
    @State private var showingWebsiteList = false
    @State private var showingAddWebsite = false
    
    var body: some View {
        NavigationView {
            List {
                // 顶部应用名标题
                Text("OpenManico")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                
                NavigationLink(destination: ShortcutsView()
                    .navigationTitle("App快捷键")) {
                    Label("App快捷键", systemImage: "keyboard")
                }
                
                NavigationLink(destination: WebShortcutsView()
                    .navigationTitle("网站快捷键")) {
                    Label("网站快捷键", systemImage: "globe")
                }
                
                NavigationLink(destination: WebsiteListView()
                    .navigationTitle("网站列表")
                    .sheet(isPresented: $showingAddWebsite) {
                        AddWebsiteView()
                    }, isActive: $showingWebsiteList) {
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
                
                NavigationLink(destination: CircleRingSettingsView()
                    .navigationTitle("圆环模式")) {
                    Label("圆环模式", systemImage: "circle.dashed")
                }
                
                NavigationLink(destination: SettingsView()
                    .navigationTitle("通用设置")) {
                    Label("通用设置", systemImage: "gear")
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Spacer()
                }
                ToolbarItem(placement: .automatic) {
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
        .onAppear {
            // 添加通知观察者
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("SwitchToWebsiteList"),
                object: nil,
                queue: .main
            ) { notification in
                showingWebsiteList = true
                // 如果通知中包含打开新建对话框的标记，则打开新建对话框
                if let userInfo = notification.userInfo,
                   let showAddSheet = userInfo["showAddSheet"] as? Bool,
                   showAddSheet {
                    // 延迟一下再打开新建对话框，确保页面切换完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingAddWebsite = true
                    }
                }
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
} 