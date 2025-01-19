import Foundation
import Carbon
import AppKit

/**
 * 热键管理器
 */
class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var lastActiveApp: NSRunningApplication?
    @Published var webShortcutManager = WebShortcutManager()
    private var shortcuts: [AppShortcut] = []
    private var hotKeys: [String: Any] = [:]
    
    // 修饰键常量
    private let optionKeyMask: UInt32 = 0x0800
    private let cmdKeyMask: UInt32 = 0x0100
    
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
        "A": 0x00, "B": 0x0B, "C": 0x08, "D": 0x02,
        "E": 0x0E, "F": 0x03, "G": 0x05, "H": 0x04,
        "I": 0x22, "J": 0x26, "K": 0x28, "L": 0x25,
        "M": 0x2E, "N": 0x2D, "O": 0x1F, "P": 0x23,
        "Q": 0x0C, "R": 0x0F, "S": 0x01, "T": 0x11,
        "U": 0x20, "V": 0x09, "W": 0x0D, "X": 0x07,
        "Y": 0x10, "Z": 0x06
    ]
    
    // Option 键长按计时器
    private var optionKeyTimer: Timer?
    @Published var isOptionKeyPressed = false
    private var isCommandKeyPressed = false
    
    init() {
        print("HotKeyManager initializing...")
        setupEventHandler()
        setupOptionKeyMonitor()
        setupTabKeyMonitor()
        print("HotKeyManager initialization completed")
        updateShortcuts()
    }
    
    deinit {
        print("HotKeyManager deinitializing...")
        unregisterAllHotKeys()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        optionKeyTimer?.invalidate()
    }
    
    /**
     * 设置事件处理器
     */
    private func setupEventHandler() {
        print("Setting up event handler...")
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        var handlerRef: EventHandlerRef?
        let status = InstallEventHandler(
            GetEventMonitorTarget(),
            { (_, event, _) -> OSStatus in
                print("Hot key event received")
                guard let event = event else { 
                    print("Event is nil")
                    return OSStatus(eventNotHandledErr) 
                }
                
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
                    print("Hot key ID received: \(hotkeyID.id)")
                    HotKeyManager.shared.handleHotKey(hotkeyID.id)
                } else {
                    print("Failed to get hot key ID: \(err)")
                }
                
                return OSStatus(noErr)
            },
            1,
            &eventType,
            nil,
            &handlerRef
        )
        
        if status == noErr {
            print("Event handler installed successfully")
            self.eventHandler = handlerRef
            registerAllHotKeys()
        } else {
            print("Failed to install event handler: \(status)")
        }
    }
    
    private func registerAllHotKeys() {
        print("Registering all hot keys...")
        unregisterAllHotKeys()
        hotKeyRefs.removeAll()
        
        // 注册数字键快捷键
        for i in 1...9 {
            if let shortcut = shortcuts.first(where: { $0.key == String(i) }) {
                print("Registering number key \(i)")
                registerHotKey(id: i, keyCode: numberKeyCodes[i]!)
            }
        }
        
        // 注册字母键快捷键
        for (letter, keyCode) in letterKeyCodes {
            if let shortcut = shortcuts.first(where: { $0.key == letter }) {
                print("Registering letter key \(letter)")
                registerHotKey(id: 10 + Int(UnicodeScalar(letter)!.value), keyCode: keyCode)
            }
        }
        print("All hot keys registered")
    }
    
    private func registerHotKey(id: Int, keyCode: Int) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(id)
        hotKeyID.id = UInt32(id)
        
        var hotKeyRef: EventHotKeyRef?
        
        // 注册 Option 快捷键
        let optionModifier: UInt32 = optionKeyMask
        let status1 = RegisterEventHotKey(
            UInt32(keyCode),
            optionModifier,
            hotKeyID,
            GetEventMonitorTarget(),
            0,
            &hotKeyRef
        )
        
        if status1 == noErr {
            hotKeyRefs.append(hotKeyRef)
            print("Successfully registered Option hotkey for ID \(id)")
        } else {
            print("Failed to register Option hotkey for ID \(id): \(status1)")
        }
        
        // 注册 Option + Command 快捷键
        let optionCommandModifier: UInt32 = optionKeyMask | cmdKeyMask
        var webHotKeyRef: EventHotKeyRef?
        let status2 = RegisterEventHotKey(
            UInt32(keyCode),
            optionCommandModifier,
            EventHotKeyID(signature: OSType(id + 1000), id: UInt32(id + 1000)),
            GetEventMonitorTarget(),
            0,
            &webHotKeyRef
        )
        
        if status2 == noErr {
            hotKeyRefs.append(webHotKeyRef)
            print("Successfully registered Option+Command hotkey for ID \(id)")
        } else {
            print("Failed to register Option+Command hotkey for ID \(id): \(status2)")
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
        print("[HotKeyManager] 快捷键被按下: \(number)")
        
        DispatchQueue.main.async {
            // 将 ID 转换为对应的键
            let key: String
            let isWebShortcut = number >= 1000
            let actualNumber = isWebShortcut ? number - 1000 : number
            
            if actualNumber <= 9 {
                key = String(actualNumber)
            } else {
                key = String(UnicodeScalar(actualNumber - 10)!)
            }
            
            print("[HotKeyManager] 转换后的按键: \(key)")
            print("[HotKeyManager] 是否为网站快捷键: \(isWebShortcut)")
            
            if isWebShortcut {
                // 处理网站快捷键 (Option + Command)
                print("[HotKeyManager] 正在查找网站快捷键: \(key)")
                print("[HotKeyManager] 当前场景: \(self.webShortcutManager.currentScene?.name ?? "无")")
                print("[HotKeyManager] 当前场景中的快捷键:")
                if let currentScene = self.webShortcutManager.currentScene {
                    for shortcut in currentScene.shortcuts {
                        print("- 键: \(shortcut.key), 名称: \(shortcut.name), URL: \(shortcut.url), 启用: \(shortcut.isEnabled)")
                    }
                }
                
                // 在当前场景的快捷键中查找匹配的快捷键
                if let shortcut = self.webShortcutManager.currentScene?.shortcuts.first(where: { $0.key == key && $0.isEnabled }) {
                    print("[HotKeyManager] ✅ 找到网站快捷键: \(shortcut.name)")
                    print("[HotKeyManager] 网站 URL: \(shortcut.url)")
                    print("[HotKeyManager] 网站 ID: \(shortcut.websiteId)")
                    if let url = URL(string: shortcut.url) {
                        print("[HotKeyManager] 正在打开网站: \(url)")
                        NSWorkspace.shared.open(url)
                        AppSettings.shared.incrementUsageCount()
                    } else {
                        print("[HotKeyManager] ❌ 无效的 URL: \(shortcut.url)")
                    }
                } else {
                    print("[HotKeyManager] ❌ 未找到对应的网站快捷键")
                    print("[HotKeyManager] 当前场景: \(self.webShortcutManager.currentScene?.name ?? "无")")
                    print("[HotKeyManager] 场景中的快捷键数量: \(self.webShortcutManager.currentScene?.shortcuts.count ?? 0)")
                }
            } else {
                // 处理应用程序快捷键 (Option)
                if let shortcut = AppSettings.shared.shortcuts.first(where: { $0.key == key }) {
                    print("[HotKeyManager] 找到应用快捷键: \(shortcut.appName)")
                    
                    if let currentApp = NSWorkspace.shared.frontmostApplication,
                       currentApp.bundleIdentifier == shortcut.bundleIdentifier {
                        if let lastApp = self.lastActiveApp {
                            print("[HotKeyManager] 切换回上一个应用: \(lastApp.localizedName ?? "")")
                            self.switchToApp(bundleIdentifier: lastApp.bundleIdentifier ?? "")
                            AppSettings.shared.incrementUsageCount()
                        }
                    } else {
                        self.lastActiveApp = NSWorkspace.shared.frontmostApplication
                        print("[HotKeyManager] 切换到应用: \(shortcut.appName)")
                        self.switchToApp(bundleIdentifier: shortcut.bundleIdentifier)
                        AppSettings.shared.incrementUsageCount()
                    }
                } else {
                    print("[HotKeyManager] ❌ 未找到对应的应用快捷键")
                }
            }
        }
    }
    
    private func switchToApp(bundleIdentifier: String) {
        // 尝试使用 NSWorkspace 切换应用
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            let success = app.activate(options: [.activateIgnoringOtherApps])
            if success {
                print("Successfully switched to app using NSWorkspace")
                return
            }
        }
        
        // 如果应用未运行，尝试启动它
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            do {
                try NSWorkspace.shared.launchApplication(at: appUrl,
                                                       options: [.default],
                                                       configuration: [:])
                print("Successfully launched app")
            } catch {
                print("Failed to launch app: \(error)")
            }
        }
    }
    
    /**
     * 设置 Tab 键监听
     */
    private func setupTabKeyMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self,
                  self.isOptionKeyPressed,
                  event.keyCode == 0x30 // Tab 键的键码
            else { return }
            
            // 根据是否按下 Command 键来决定选择应用还是网站
            if self.isCommandKeyPressed {
                AppSettings.shared.selectNextWebShortcut()
            } else {
                AppSettings.shared.selectNextShortcut()
            }
        }
    }
    
    /**
     * 设置 Option 键监听
     */
    private func setupOptionKeyMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            let optionKeyPressed = event.modifierFlags.contains(.option)
            let commandKeyPressed = event.modifierFlags.contains(.command)
            guard let self = self else { return }
            
            // 更新 Command 键状态
            self.isCommandKeyPressed = commandKeyPressed
            
            if optionKeyPressed && !self.isOptionKeyPressed {
                // Option 键被按下
                self.isOptionKeyPressed = true
                self.optionKeyTimer?.invalidate()
                self.optionKeyTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    // Option 键长按超过 0.5 秒
                    DispatchQueue.main.async {
                        if AppSettings.shared.showFloatingWindow {
                            DockIconsWindowController.shared.toggleWindow()
                            AppSettings.shared.resetSelection() // 重置选中状态
                        }
                    }
                }
            } else if !optionKeyPressed && self.isOptionKeyPressed {
                // Option 键被释放
                self.isOptionKeyPressed = false
                self.optionKeyTimer?.invalidate()
                self.optionKeyTimer = nil
                DispatchQueue.main.async {
                    DockIconsWindowController.shared.hideWindow()
                    
                    // 只有在有选中状态时才切换应用或网站
                    if AppSettings.shared.selectedWebShortcut != nil || AppSettings.shared.selectedShortcut != nil {
                        // 根据选中状态打开应用或网站
                        if let webShortcut = AppSettings.shared.selectedWebShortcut,
                           let url = URL(string: webShortcut.url) {
                            NSWorkspace.shared.open(url)
                        } else if let shortcut = AppSettings.shared.selectedShortcut {
                            self.switchToApp(bundleIdentifier: shortcut.bundleIdentifier)
                        }
                        
                        AppSettings.shared.resetSelection() // 重置选中状态
                    }
                }
            }
        }
    }
    
    func updateShortcuts() {
        print("Updating shortcuts...")
        unregisterAllHotKeys()
        print("Registering all hot keys...")
        
        // 注册数字键 (1-9)
        for i in 1...9 {
            if let keyCode = numberKeyCodes[i] {
                print("Registering number key \(i)")
                registerHotKey(id: i, keyCode: keyCode)
            }
        }
        
        // 注册字母键 (A-Z)
        for (letter, keyCode) in letterKeyCodes {
            print("Registering letter key \(letter)")
            let id = 10 + Int(UnicodeScalar(letter)!.value)
            registerHotKey(id: id, keyCode: keyCode)
        }
        
        print("All hot keys registered")
    }
} 
