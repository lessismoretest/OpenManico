import Foundation
import Carbon
import AppKit

/**
 * 热键管理器
 */
class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    @Published private var lastUpdateTime = Date()
    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var lastActiveApp: NSRunningApplication?
    private var optionKeyMonitor: Any?
    private var isOptionKeyPressed = false
    private var websiteManager = WebsiteManager.shared
    private var appSwitchObserver: Any?
    private var currentApp: NSRunningApplication?
    private var isFloatingWindowPinned = false // 添加悬浮窗常驻状态标志
    
    // 数字键的键码映射
    private let numberKeyCodes: [Int: Int] = [
        1: 0x12, // 1
        2: 0x13, // 2
        3: 0x14, // 3
        4: 0x15, // 4
        5: 0x17, // 5
        6: 0x16, // 6
        7: 0x1A, // 7
        8: 0x1C, // 8
        9: 0x19  // 9
    ]
    
    // 字母键的键码映射
    private let letterKeyCodes: [String: Int] = [
        "A": 0x00,
        "B": 0x0B,
        "C": 0x08,
        "D": 0x02,
        "E": 0x0E,
        "F": 0x03,
        "G": 0x05,
        "H": 0x04,
        "I": 0x22,
        "J": 0x26,
        "K": 0x28,
        "L": 0x25,
        "M": 0x2E,
        "N": 0x2D,
        "O": 0x1F,
        "P": 0x23,
        "Q": 0x0C,
        "R": 0x0F,
        "S": 0x01,
        "T": 0x11,
        "U": 0x20,
        "V": 0x09,
        "W": 0x0D,
        "X": 0x07,
        "Y": 0x10,
        "Z": 0x06
    ]
    
    private init() {
        setupEventHandler()
        setupOptionKeyMonitor()
        setupAppSwitchObserver()
    }
    
    deinit {
        unregisterAllHotKeys()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        if let monitor = optionKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let observer = appSwitchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
    
    private func setupOptionKeyMonitor() {
        // 添加变量用于区分短按和双击
        var lastPressTime = Date()
        var lastReleaseTime = Date()
        var clickCount = 0
        var potentialDoubleClick = false // 标记是否可能为双击
        var singleClickTimer: Timer? // 单击延迟处理计时器
        var justHandledDoubleClick = false // 标记是否刚处理完双击事件
        
        optionKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            guard let self = self else { return }
            let optionKeyPressed = event.modifierFlags.contains(.option)
            
            // Option键状态改变
            if optionKeyPressed != self.isOptionKeyPressed {
                self.isOptionKeyPressed = optionKeyPressed
                
                if optionKeyPressed {
                    // ========== Option键被按下 ==========
                    let now = Date()
                    let timeSinceLastRelease = now.timeIntervalSince(lastReleaseTime)
                    lastPressTime = now
                    
                    // 重置刚处理双击的标记
                    if justHandledDoubleClick {
                        print("👆 重置双击处理标记")
                        justHandledDoubleClick = false
                    }
                    
                    // 取消之前的定时器
                    singleClickTimer?.invalidate()
                    
                    // 如果距上次释放时间小于0.5秒，可能是双击
                    if timeSinceLastRelease < 0.5 {
                        clickCount += 1
                        potentialDoubleClick = true
                        print("⚡ 检测到可能的双击: 点击计数=\(clickCount)")
                    } else {
                        clickCount = 1 // 重置点击计数
                        potentialDoubleClick = false
                        print("👇 首次点击或距离上次释放时间较长")
                    }
                } else {
                    // ========== Option键被松开 ==========
                    lastReleaseTime = Date()
                    let pressDuration = lastReleaseTime.timeIntervalSince(lastPressTime)
                    
                    // 双击检测：按下和松开的时间间隔短，且点击次数多于1次
                    let isDoubleClick = clickCount >= 2 && pressDuration < 0.3
                    
                    // 检测到双击Option键
                    if isDoubleClick && AppSettings.shared.showFloatingWindow {
                        // 处理双击：切换悬浮窗常驻状态
                        self.isFloatingWindowPinned = !self.isFloatingWindowPinned
                        
                        // 标记我们刚刚处理了双击事件
                        justHandledDoubleClick = true
                        
                        print("🔄 双击处理：悬浮窗固定状态切换为 \(self.isFloatingWindowPinned ? "固定" : "不固定")")
                        
                        if self.isFloatingWindowPinned {
                            print("📌 双击效果：显示并固定悬浮窗")
                            DockIconsWindowController.shared.showWindow()
                        } else {
                            print("🔽 双击效果：取消固定并隐藏悬浮窗")
                            DockIconsWindowController.shared.hideWindow()
                        }
                        
                        // 重置双击状态
                        clickCount = 0
                        potentialDoubleClick = false
                    } else if pressDuration < 0.3 && !potentialDoubleClick {
                        // 单击处理（如果是单击且不是双击的第一次点击）
                        singleClickTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            // 如果是短按并且启用了切换应用功能
                            if AppSettings.shared.switchToLastAppWithOptionClick {
                                print("🔍 单击检测：处理应用切换")
                                // 获取当前应用
                                if let currentApp = NSWorkspace.shared.frontmostApplication {
                                    if let lastApp = self.lastActiveApp,
                                       lastApp.bundleIdentifier != currentApp.bundleIdentifier, // 确保lastApp与currentApp不同
                                       lastApp.isTerminated == false { // 确保上一个应用没有被终止
                                        // 如果有上一个应用，切换到它
                                        print("✅ 切换到上一个应用: \(lastApp.localizedName ?? ""), 从: \(currentApp.localizedName ?? "")")
                                        
                                        // 增加使用次数
                                        AppSettings.shared.incrementUsageCount()
                                        
                                        // 先保存当前应用
                                        self.lastActiveApp = currentApp
                                        
                                        // 然后切换到上一个应用
                                        DispatchQueue.main.async {
                                            self.switchToApp(bundleIdentifier: lastApp.bundleIdentifier ?? "")
                                        }
                                    } else {
                                        // 首次点击或上一个应用已失效，记录当前应用
                                        print("📝 记录当前应用: \(currentApp.localizedName ?? "")")
                                        self.lastActiveApp = currentApp
                                    }
                                }
                            } else {
                                print("⏭️ 单击检测：未启用应用切换功能")
                            }
                        }
                    }
                    
                    // 如果不是常驻显示模式且没有刚处理过双击事件，则隐藏悬浮窗
                    if !self.isFloatingWindowPinned && !justHandledDoubleClick {
                        print("🔍 松开检测：悬浮窗未固定且非双击处理，隐藏悬浮窗")
                        DockIconsWindowController.shared.hideWindow()
                    } else if justHandledDoubleClick {
                        print("🔍 松开检测：刚处理过双击，跳过隐藏操作")
                    } else {
                        print("🔍 松开检测：悬浮窗已固定，保持显示")
                    }
                }
            }
        }
    }
    
    private func setupEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        let status = InstallEventHandler(
            GetEventMonitorTarget(),
            { (_, event, _) -> OSStatus in
                guard let event = event else { return OSStatus(eventNotHandledErr) }
                
                var hotkeyID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )
                
                if err == noErr {
                    HotKeyManager.shared.handleHotKey(hotkeyID.id)
                }
                
                return OSStatus(noErr)
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        if status == noErr {
            print("Event handler installed successfully")
            registerAllHotKeys()
        } else {
            print("Failed to install event handler: \(status)")
        }
    }
    
    private func registerAllHotKeys() {
        unregisterAllHotKeys()
        hotKeyRefs.removeAll()
        
        let appShortcuts = AppSettings.shared.shortcuts
        let websites = websiteManager.getWebsites(mode: .all)
        let configuredWebsiteKeys = websites.compactMap { $0.shortcutKey }
        
        // 创建热键映射表，用于调试
        var keyMappings: [Int: String] = [:]
        
        // 输出调试信息
        print("已配置的应用快捷键: \(appShortcuts.map { $0.key }.joined(separator: ", "))")
        print("已配置的网站快捷键: \(configuredWebsiteKeys.joined(separator: ", "))")
        
        // 获取所有已配置快捷键
        let configuredNumberKeys = appShortcuts.filter { Int($0.key) != nil }.map { $0.key }
        let configuredLetterKeys = appShortcuts.filter { Int($0.key) == nil }.map { $0.key }
        
        // 只注册用户配置了的数字键快捷键
        for i in 1...9 {
            let key = String(i)
            if configuredNumberKeys.contains(key) {
                let appId = i
                keyMappings[appId] = key
                registerHotKey(id: appId, keyCode: numberKeyCodes[i]!, isWebsite: false)
                print("注册应用快捷键: Option+\(key), ID: \(appId)")
            }
            // 只注册已配置的网站快捷键
            if configuredWebsiteKeys.contains(key) {
                let webId = i + 1000  // 使用更大的偏移值避免冲突
                keyMappings[webId] = key
                registerHotKey(id: webId, keyCode: numberKeyCodes[i]!, isWebsite: true)
                print("注册网站快捷键: Option+Command+\(key), ID: \(webId)")
            }
        }
        
        // 只注册用户配置了的字母键快捷键
        for (letter, keyCode) in letterKeyCodes {
            let asciiValue = Int(UnicodeScalar(letter)!.value)
            
            if configuredLetterKeys.contains(letter) {
                let appId = 100 + asciiValue  // 新的ID生成方式
                keyMappings[appId] = letter
                let registrationResult = registerHotKey(id: appId, keyCode: keyCode, isWebsite: false)
                print("注册应用快捷键: Option+\(letter), ID: \(appId) \(registrationResult ? "成功" : "失败")")
            }
            
            // 只注册已配置的网站快捷键
            if configuredWebsiteKeys.contains(letter) {
                let webId = 1000 + asciiValue  // 使用更大的偏移值避免冲突
                keyMappings[webId] = letter
                let registrationResult = registerHotKey(id: webId, keyCode: keyCode, isWebsite: true)
                print("注册网站快捷键: Option+Command+\(letter), ID: \(webId) \(registrationResult ? "成功" : "失败")")
            }
        }
        
        // 保存热键映射表，用于调试
        self.keyMappings = keyMappings
        
        print("已注册 \(hotKeyRefs.count) 个快捷键")
    }
    
    // 热键映射表，用于调试
    private var keyMappings: [Int: String] = [:]
    
    @discardableResult
    private func registerHotKey(id: Int, keyCode: Int, isWebsite: Bool) -> Bool {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(id)
        hotKeyID.id = UInt32(id)
        
        var hotKeyRef: EventHotKeyRef?
        
        let modifiers: UInt32 = isWebsite ? UInt32(optionKey | cmdKey) : UInt32(optionKey)
        
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            modifiers,
            hotKeyID,
            GetEventMonitorTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            hotKeyRefs.append(hotKeyRef)
            print("Successfully registered hotkey for ID \(id)")
            return true
        } else {
            print("Failed to register hotkey for ID \(id), error: \(status)")
            return false
        }
    }
    
    private func unregisterAllHotKeys() {
        for hotKeyRef in hotKeyRefs {
            if let ref = hotKeyRef {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()
    }
    
    private func handleHotKey(_ id: UInt32) {
        let number = Int(id)
        
        // 使用映射表直接获取键，避免复杂的计算
        guard let key = keyMappings[number] else {
            print("错误: 未找到ID \(number) 对应的热键")
            return
        }
        
        // 基于ID范围判断是否为网站快捷键
        let isWebsite = number >= 1000
        
        DispatchQueue.main.async {
            print("触发热键 ID: \(id), 键: \(key), 是否网站: \(isWebsite)")
            
            // 增加使用次数
            AppSettings.shared.incrementUsageCount()
            
            if isWebsite {
                // 处理网站快捷键
                let websites = self.websiteManager.getWebsites(mode: .all)
                if let website = websites.first(where: { $0.shortcutKey == key }) {
                    print("打开网站: \(website.name), URL: \(website.url)")
                    if let url = URL(string: website.url) {
                        NSWorkspace.shared.open(url)
                    }
                } else {
                    print("未找到快捷键为 \(key) 的网站")
                }
            } else {
                // 处理应用快捷键
                if let shortcut = AppSettings.shared.shortcuts.first(where: { $0.key == key }) {
                    print("Found shortcut for key \(key): \(shortcut.appName)")
                    
                    // 检查当前活跃的应用是否是目标应用
                    if let currentApp = NSWorkspace.shared.frontmostApplication,
                       currentApp.bundleIdentifier == shortcut.bundleIdentifier {
                        // 如果是，则切换回上一个应用
                        if let lastApp = self.lastActiveApp {
                            print("Switching back to previous app: \(lastApp.localizedName ?? "")")
                            self.switchToApp(bundleIdentifier: lastApp.bundleIdentifier ?? "")
                        }
                    } else {
                        // 如果不是，则记录当前应用并切换到目标应用
                        self.lastActiveApp = NSWorkspace.shared.frontmostApplication
                        self.switchToApp(bundleIdentifier: shortcut.bundleIdentifier)
                    }
                } else {
                    print("No shortcut found for key \(key)")
                }
            }
        }
    }
    
    func switchToApp(bundleIdentifier: String) {
        print("Attempting to switch to app with bundle ID: \(bundleIdentifier)")
        
        // 特殊处理访达
        if bundleIdentifier == "com.apple.finder" {
            // 更简单的方法处理访达，完全避免使用AppleScript
            
            // 如果访达已运行，直接激活它
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
                let options: NSApplication.ActivationOptions = [.activateIgnoringOtherApps]
                _ = app.activate(options: options)
                print("已激活访达")
            } else {
                // 如果访达未运行，启动它
                print("正在启动访达...")
                NSWorkspace.shared.launchApplication("Finder")
            }
            
            // 在激活后，使用特定的URL打开一个窗口，确保有至少一个窗口可见
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 打开一个新的访达窗口，访问home目录
                NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser)
            }
            return
        }
        
        // 先尝试激活已运行的应用
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            // 使用更强的激活选项
            let options: NSApplication.ActivationOptions = [.activateIgnoringOtherApps]
            let success = app.activate(options: options)
            
            // 如果第一次激活失败，尝试强制激活
            if !success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    _ = app.activate(options: options)
                }
            }
            print("Activating running app \(bundleIdentifier): \(success)")
            return
        }
        
        // 如果应用未运行，则启动它
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            do {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                
                try NSWorkspace.shared.openApplication(
                    at: url,
                    configuration: config
                )
                print("Launching app at \(url)")
            } catch {
                print("Error launching app: \(error)")
            }
        } else {
            print("Could not find app with bundle ID: \(bundleIdentifier)")
        }
    }
    
    func updateShortcuts() {
        registerAllHotKeys()
        // 触发观察者更新
        lastUpdateTime = Date()
    }
    
    // 添加应用切换观察者
    private func setupAppSwitchObserver() {
        // 初始化当前应用
        currentApp = NSWorkspace.shared.frontmostApplication
        
        // 监听应用切换事件
        appSwitchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            // 获取新激活的应用
            if let newApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                // 仅当通过非Option键切换应用时更新lastActiveApp
                if !self.isOptionKeyPressed && self.currentApp != nil {
                    // 将当前应用设为上一个应用
                    self.lastActiveApp = self.currentApp
                    print("应用切换: \(self.currentApp?.localizedName ?? "未知") -> \(newApp.localizedName ?? "未知")")
                }
                
                // 更新当前应用
                self.currentApp = newApp
            }
        }
    }
    
    // 提供一个方法让DockIconsWindowController通知窗口已关闭
    func notifyWindowClosed() {
        // 不在单独的地方重置isFloatingWindowPinned，而是只记录日志
        print("🔴 窗口关闭通知 - 悬浮窗固定状态：\(isFloatingWindowPinned ? "已固定" : "未固定")")
        
        // 注意：isFloatingWindowPinned的状态现在只在setupOptionKeyMonitor方法中维护
        // 这里不再修改它，避免与双击处理逻辑冲突
    }
    
    // 提供一个方法让其他类访问上一个活跃应用
    func getLastActiveApp() -> NSRunningApplication? {
        return lastActiveApp
    }
} 
