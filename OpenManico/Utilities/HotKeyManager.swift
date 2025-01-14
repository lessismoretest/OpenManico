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
    private var isOptionKeyPressed = false
    private var isTabMonitoringEnabled = false
    
    init() {
        setupEventHandler()
        setupOptionKeyMonitor()
        setupTabKeyMonitor()
    }
    
    deinit {
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
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        var handlerRef: EventHandlerRef?
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
        unregisterAllHotKeys()
        hotKeyRefs.removeAll()
        
        // 注册数字键快捷键
        for i in 1...9 {
            registerHotKey(id: i, keyCode: numberKeyCodes[i]!)
        }
        
        // 注册字母键快捷键
        for (letter, keyCode) in letterKeyCodes {
            registerHotKey(id: 10 + Int(UnicodeScalar(letter)!.value), keyCode: keyCode)
        }
    }
    
    private func registerHotKey(id: Int, keyCode: Int) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(id)
        hotKeyID.id = UInt32(id)
        
        var hotKeyRef: EventHotKeyRef?
        
        // 注册 Option 快捷键
        let optionModifier: UInt32 = UInt32(optionKey)
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
        }
        
        // 注册 Option + Command 快捷键
        let optionCommandModifier: UInt32 = UInt32(optionKey | cmdKey)
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
        print("Hotkey pressed: \(number)")
        
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
            
            if isWebShortcut {
                // 处理网站快捷键 (Option + Command)
                if let shortcut = self.webShortcutManager.shortcuts.first(where: { $0.key == key && $0.isEnabled }),
                   let url = URL(string: shortcut.url) {
                    NSWorkspace.shared.open(url)
                }
            } else {
                // 处理应用程序快捷键 (Option)
                if let shortcut = AppSettings.shared.shortcuts.first(where: { $0.key == key }) {
                    print("Found shortcut for key \(key): \(shortcut.appName)")
                    
                    if let currentApp = NSWorkspace.shared.frontmostApplication,
                       currentApp.bundleIdentifier == shortcut.bundleIdentifier {
                        if let lastApp = self.lastActiveApp {
                            print("Switching back to previous app: \(lastApp.localizedName ?? "")")
                            self.switchToApp(bundleIdentifier: lastApp.bundleIdentifier ?? "")
                        }
                    } else {
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
        
        // 增加使用次数
        AppSettings.shared.incrementUsageCount()
        
        // 先尝试激活已运行的应用
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            let success = app.activate(options: [.activateIgnoringOtherApps])
            
            // 如果第一次激活失败，尝试强制激活
            if !success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    _ = app.activate(options: [.activateIgnoringOtherApps])
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
                config.hidesOthers = false
                
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
    
    /**
     * 设置 Tab 键监听
     */
    private func setupTabKeyMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self,
                  self.isOptionKeyPressed,
                  event.keyCode == 0x30 // Tab 键的键码
            else { return }
            
            AppSettings.shared.selectNextShortcut()
        }
    }
    
    /**
     * 设置 Option 键监听
     */
    private func setupOptionKeyMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            let optionKeyPressed = event.modifierFlags.contains(.option)
            guard let self = self else { return }
            
            if optionKeyPressed && !self.isOptionKeyPressed {
                // Option 键被按下
                self.isOptionKeyPressed = true
                self.optionKeyTimer?.invalidate()
                self.optionKeyTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    // Option 键长按超过 0.5 秒
                    DispatchQueue.main.async {
                        if AppSettings.shared.showFloatingWindow {
                            DockIconsWindowController.shared.showWindow()
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
                    // 如果有选中的应用，则打开它
                    if let shortcut = AppSettings.shared.selectedShortcut {
                        self.switchToApp(bundleIdentifier: shortcut.bundleIdentifier)
                    }
                    AppSettings.shared.resetSelection() // 重置选中状态
                }
            }
        }
    }
} 