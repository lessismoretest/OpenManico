import SwiftUI

/**
 * 悬浮窗设置视图
 */
struct FloatingWindowSettingsView: View {
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        Form {
            Section {
                Toggle("启用悬浮窗", isOn: $settings.showFloatingWindow)
                    .onChange(of: settings.showFloatingWindow) { _ in
                        settings.saveSettings()
                    }
                
                if settings.showFloatingWindow {
                    Text("长按 Option 键显示应用快捷键悬浮窗")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("基本设置")
            }
            
            Section {
                Text("悬浮窗会显示已配置的应用程序图标和对应的快捷键，帮助你快速找到需要的应用。")
                    .font(.callout)
                    .foregroundColor(.secondary)
            } header: {
                Text("说明")
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 