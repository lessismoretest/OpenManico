import Foundation
import AppKit
import UserNotifications

class IconManager {
    static let shared = IconManager()
    
    // 存储当前图标的UserDefaults键名
    private let currentIconKey = "CurrentAppIcon"
    
    // 通知设置
    private let notificationForNewIconKey = "NotificationWhenIconUnlocked"
    
    private init() {
        // 初始化时加载当前图标
        loadCurrentIcon()
    }
    
    private var _currentIcon: AppIcon = AppIcon.defaultIcon
    
    var currentIcon: AppIcon {
        get { _currentIcon }
        set {
            _currentIcon = newValue
            UserDefaults.standard.set(newValue.iconName, forKey: currentIconKey)
            refreshCurrentAppIcon()
        }
    }
    
    var notificationForNewIcon: Bool {
        get { UserDefaults.standard.bool(forKey: notificationForNewIconKey) }
        set { UserDefaults.standard.set(newValue, forKey: notificationForNewIconKey) }
    }
    
    private func loadCurrentIcon() {
        // 从UserDefaults加载上次使用的图标
        if let iconName = UserDefaults.standard.string(forKey: currentIconKey),
           let icon = AppIcon.all.first(where: { $0.iconName == iconName }) {
            _currentIcon = icon
        } else {
            _currentIcon = AppIcon.defaultIcon
        }
    }
    
    // 获取已解锁的图标列表
    func getUnlockedIcons(usageCount: Int) -> [AppIcon] {
        // 返回所有图标，不再检查解锁次数
        return AppIcon.all
    }
    
    // 设置应用图标
    func setAppIcon(to icon: AppIcon) {
        currentIcon = icon
        print("已将应用图标设置为: \(icon.name)")
    }
    
    // 刷新当前应用图标
    func refreshCurrentAppIcon() {
        guard let image = NSImage(named: currentIcon.iconName) else {
            print("错误: 无法找到图标: \(currentIcon.iconName)")
            return
        }
        
        print("正在设置应用图标: \(currentIcon.name) (使用图片: \(currentIcon.iconName))")
        
        // 设置Dock栏图标
        NSApp.applicationIconImage = image
        
        // 尝试设置应用程序文件图标
        do {
            try NSWorkspace.shared.setIcon(image, forFile: Bundle.main.bundlePath, options: [])
            print("应用图标设置成功: \(currentIcon.name)")
        } catch {
            print("设置应用图标失败: \(error.localizedDescription)")
        }
    }
    
    // 检查是否解锁了新图标（现已禁用）
    func checkForNewUnlockedIcons(usageCount: Int) {
        // 该功能已禁用，所有图标默认可用
        return
    }
    
    // 创建通知附件
    private func createNotificationAttachment(from data: Data) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let tempFileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        
        do {
            try data.write(to: tempFileURL)
            let attachment = try UNNotificationAttachment(identifier: UUID().uuidString, url: tempFileURL, options: nil)
            return attachment
        } catch {
            print("创建通知附件失败: \(error)")
            return nil
        }
    }
    
    // 发送通知
    private func sendNotification(_ content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送通知失败: \(error)")
            }
        }
    }
} 