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
    }
    
    deinit {
        unregisterAllHotKeys()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        if let monitor = optionKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupOptionKeyMonitor() {
        optionKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            let optionKeyPressed = event.modifierFlags.contains(.option)
            if optionKeyPressed != self?.isOptionKeyPressed {
                self?.isOptionKeyPressed = optionKeyPressed
                if optionKeyPressed {
                    DockIconsWindowController.shared.showWindow()
                } else {
                    DockIconsWindowController.shared.hideWindow()
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
        
        // 注册数字键快捷键
        for i in 1...9 {
            registerHotKey(id: i, keyCode: numberKeyCodes[i]!, isWebsite: false)
            registerHotKey(id: i + 100, keyCode: numberKeyCodes[i]!, isWebsite: true)  // 为网站使用不同的 ID
        }
        
        // 注册字母键快捷键
        for (letter, keyCode) in letterKeyCodes {
            let id = 10 + Int(UnicodeScalar(letter)!.value)
            registerHotKey(id: id, keyCode: keyCode, isWebsite: false)
            registerHotKey(id: id + 100, keyCode: keyCode, isWebsite: true)  // 为网站使用不同的 ID
        }
    }
    
    private func registerHotKey(id: Int, keyCode: Int, isWebsite: Bool) {
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
        } else {
            print("Failed to register hotkey for ID \(id), error: \(status)")
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
        let isWebsite = number >= 100
        let actualNumber = isWebsite ? number - 100 : number
        
        DispatchQueue.main.async {
            // 将 ID 转换为对应的键
            let key: String
            if actualNumber <= 9 {
                key = String(actualNumber)
            } else {
                // 对于字母键，将 ID 转换回字母
                // ID = 10 + ASCII值，所以需要减去10再转换
                key = String(UnicodeScalar(actualNumber - 10)!)
            }
            
            if isWebsite {
                // 处理网站快捷键
                let websites = self.websiteManager.getWebsites(mode: .all)
                if let website = websites.first(where: { $0.shortcutKey == key }) {
                    if let url = URL(string: website.url) {
                        NSWorkspace.shared.open(url)
                    }
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
    
    func updateShortcuts() {
        registerAllHotKeys()
        // 触发观察者更新
        lastUpdateTime = Date()
    }
} 
