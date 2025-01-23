import Foundation
import Carbon
import AppKit

/**
 * 热键管理器
 */
class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    
    // 字母键的键码映射
    private let letterKeyCodes: [String: UInt32] = [
        "A": 0x00, "B": 0x0B, "C": 0x08, "D": 0x02,
        "E": 0x0E, "F": 0x03, "G": 0x05, "H": 0x04,
        "I": 0x22, "J": 0x26, "K": 0x28, "L": 0x25,
        "M": 0x2E, "N": 0x2D, "O": 0x1F, "P": 0x23,
        "Q": 0x0C, "R": 0x0F, "S": 0x01, "T": 0x11,
        "U": 0x20, "V": 0x09, "W": 0x0D, "X": 0x07,
        "Y": 0x10, "Z": 0x06
    ]
    
    // 数字键的键码映射
    private let numberKeyCodes: [String: UInt32] = [
        "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15,
        "5": 0x17, "6": 0x16, "7": 0x1A, "8": 0x1C,
        "9": 0x19
    ]
    
    // 修饰键标志位
    private let optionKeyMask: UInt32 = 1 << 11  // Option 键的标志位
    private let commandKeyMask: UInt32 = 1 << 8   // Command 键的标志位
    
    // 存储热键引用和对应的按键信息
    private enum HotKeyType: Equatable {
        case website(UUID)
        case app(String)  // bundleIdentifier
        
        static func == (lhs: HotKeyType, rhs: HotKeyType) -> Bool {
            switch (lhs, rhs) {
            case (.website(let id1), .website(let id2)):
                return id1 == id2
            case (.app(let bundle1), .app(let bundle2)):
                return bundle1 == bundle2
            default:
                return false
            }
        }
    }
    
    private struct HotKeyInfo {
        let ref: EventHotKeyRef
        let keycode: UInt32
        let type: HotKeyType
        let signature: OSType
    }
    
    @Published private var hotKeyRefs: [String: HotKeyInfo] = [:]  // key -> HotKeyInfo
    private var websiteManager = WebsiteManager.shared
    private var settings = AppSettings.shared
    private var lastActiveApp: NSRunningApplication?
    
    // 监听 Option 键的状态
    private var optionKeyMonitor: Any?
    private var isOptionKeyPressed = false
    
    private init() {
        print("[HotKeyManager] 初始化")
        setupEventHandler()
        setupOptionKeyMonitor()
        updateShortcuts()
    }
    
    deinit {
        unregisterAllHotKeys()
        if let monitor = optionKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    // MARK: - Option 键监听
    
    private func setupOptionKeyMonitor() {
        print("[HotKeyManager] 设置 Option 键监听器")
        optionKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            let optionKeyPressed = (event.modifierFlags.intersection(.option)) == .option
            
            if optionKeyPressed != self?.isOptionKeyPressed {
                self?.isOptionKeyPressed = optionKeyPressed
                if optionKeyPressed {
                    print("[HotKeyManager] Option 键按下")
                    DockIconsWindowController.shared.showWindow()
                } else {
                    print("[HotKeyManager] Option 键释放")
                    DockIconsWindowController.shared.hideWindow()
                }
            }
        }
    }
    
    // MARK: - 快捷键管理
    
    /// 更新所有快捷键
    func updateShortcuts() {
        print("[HotKeyManager] 更新快捷键")
        unregisterAllHotKeys()
        
        // 注册所有网站的快捷键
        let websites = websiteManager.getWebsites(mode: .all)
        print("[HotKeyManager] 找到 \(websites.count) 个网站")
        for website in websites where website.shortcutKey != nil {
            print("[HotKeyManager] 注册网站快捷键: \(website.name) -> \(website.shortcutKey!)")
            registerWebsiteHotKey(key: website.shortcutKey!, websiteId: website.id)
        }
        
        // 注册所有应用的快捷键
        for shortcut in settings.shortcuts {
            print("[HotKeyManager] 注册应用快捷键: \(shortcut.appName) -> \(shortcut.key)")
            registerAppHotKey(key: shortcut.key, bundleId: shortcut.bundleIdentifier)
        }
    }
    
    /// 注册网站快捷键
    private func registerWebsiteHotKey(key: String, websiteId: UUID) {
        print("[HotKeyManager] 开始注册网站快捷键: key=\(key), websiteId=\(websiteId)")
        registerHotKey(key: key, type: .website(websiteId))
    }
    
    /// 注册应用快捷键
    private func registerAppHotKey(key: String, bundleId: String) {
        print("[HotKeyManager] 开始注册应用快捷键: key=\(key), bundleId=\(bundleId)")
        registerHotKey(key: key, type: .app(bundleId))
    }
    
    /// 注册快捷键
    private func registerHotKey(key: String, type: HotKeyType) {
        // 获取键码
        let keycode: UInt32
        if let numCode = numberKeyCodes[key] {
            keycode = numCode
        } else if let letterCode = letterKeyCodes[key] {
            keycode = letterCode
        } else {
            print("[HotKeyManager] ❌ 无效的按键: \(key)")
            return
        }
        
        print("[HotKeyManager] 按键转换成功: \(key) -> \(keycode)")
        
        // 创建热键 ID
        var hotKeyID = EventHotKeyID()
        let signature: OSType
        
        switch type {
        case let .website(websiteId):
            let uuidBytes = withUnsafeBytes(of: websiteId.uuid) { Array($0) }
            signature = OSType(uuidBytes[0]) | OSType(uuidBytes[1]) << 8 | OSType(uuidBytes[2]) << 16 | OSType(uuidBytes[3]) << 24
        case let .app(bundleId):
            signature = OSType(abs(bundleId.hashValue & 0x7FFFFFFF))
        }
        
        hotKeyID.signature = signature
        hotKeyID.id = keycode
        print("[HotKeyManager] 创建热键ID: signature=\(hotKeyID.signature), id=\(hotKeyID.id)")
        
        // 注册热键
        var hotKeyRef: EventHotKeyRef?
        let modifiers: UInt32
        switch type {
        case .website:
            modifiers = optionKeyMask | commandKeyMask  // 网站快捷键使用 Option + Command
        case .app:
            modifiers = optionKeyMask  // 应用快捷键只使用 Option
        }
        
        // 生成唯一的存储键
        let storageKey: String
        switch type {
        case .website:
            storageKey = "web_\(key)"  // 网站快捷键前缀
        case .app:
            storageKey = "app_\(key)"  // 应用快捷键前缀
        }
        
        // 如果已经注册了相同的快捷键，先注销它
        if let existingInfo = hotKeyRefs[storageKey] {
            UnregisterEventHotKey(existingInfo.ref)
            hotKeyRefs.removeValue(forKey: storageKey)
            print("[HotKeyManager] 注销已存在的快捷键: key=\(storageKey)")
        }
        
        let status = RegisterEventHotKey(
            keycode,
            modifiers,
            hotKeyID,
            GetEventMonitorTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let hotKeyRef = hotKeyRef {
            hotKeyRefs[storageKey] = HotKeyInfo(ref: hotKeyRef, keycode: keycode, type: type, signature: signature)
            print("[HotKeyManager] ✅ 快捷键注册成功: key=\(storageKey)")
        } else {
            print("[HotKeyManager] ❌ 快捷键注册失败: status=\(status)")
        }
    }
    
    /// 注销所有快捷键
    private func unregisterAllHotKeys() {
        print("[HotKeyManager] 开始注销所有快捷键: count=\(hotKeyRefs.count)")
        for (key, hotKeyInfo) in hotKeyRefs {
            UnregisterEventHotKey(hotKeyInfo.ref)
            print("[HotKeyManager] 注销快捷键: key=\(key)")
        }
        hotKeyRefs.removeAll()
        print("[HotKeyManager] ✅ 所有快捷键已注销")
    }
    
    // MARK: - 事件处理
    
    private func setupEventHandler() {
        print("[HotKeyManager] 开始设置事件处理器")
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        let result = InstallEventHandler(
            GetEventMonitorTarget(),
            { (_, event, _) -> OSStatus in
                print("[HotKeyManager] 收到热键事件")
                
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                if status == noErr {
                    print("[HotKeyManager] 获取热键ID成功: signature=\(hotKeyID.signature), id=\(hotKeyID.id)")
                    
                    // 获取当前修饰键状态
                    let currentFlags = NSEvent.modifierFlags
                    let isOptionPressed = currentFlags.contains(.option)
                    let isCommandPressed = currentFlags.contains(.command)
                    
                    print("[HotKeyManager] 当前修饰键状态: Option=\(isOptionPressed), Command=\(isCommandPressed)")
                    
                    // 查找对应的快捷键
                    if let hotKeyInfo = HotKeyManager.shared.hotKeyRefs.first(where: { 
                        $0.value.keycode == hotKeyID.id && $0.value.signature == hotKeyID.signature 
                    })?.value {
                        // 根据快捷键类型检查修饰键
                        let shouldHandle: Bool
                        switch hotKeyInfo.type {
                        case .website:
                            shouldHandle = isOptionPressed && isCommandPressed
                        case .app:
                            shouldHandle = isOptionPressed && !isCommandPressed
                        }
                        
                        if shouldHandle {
                            DispatchQueue.main.async {
                                print("[HotKeyManager] 处理热键事件: type=\(hotKeyInfo.type)")
                                HotKeyManager.shared.handleHotKey(info: hotKeyInfo)
                            }
                        } else {
                            print("[HotKeyManager] 修饰键不匹配，忽略事件")
                        }
                    } else {
                        print("[HotKeyManager] ❌ 未找到对应的快捷键: id=\(hotKeyID.id), signature=\(hotKeyID.signature)")
                    }
                } else {
                    print("[HotKeyManager] ❌ 获取热键ID失败: status=\(status)")
                }
                
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
        
        if result == noErr {
            print("[HotKeyManager] ✅ 事件处理器设置成功")
        } else {
            print("[HotKeyManager] ❌ 事件处理器设置失败: result=\(result)")
        }
    }
    
    private func handleHotKey(info: HotKeyInfo) {
        print("[HotKeyManager] 开始处理热键: type=\(info.type)")
        
        switch info.type {
        case .app(let bundleId):
            handleAppHotKey(bundleId: bundleId)
            
        case .website(let websiteId):
            handleWebsiteHotKey(websiteId: websiteId)
        }
    }
    
    private func handleWebsiteHotKey(websiteId: UUID) {
        print("[HotKeyManager] 开始处理网站热键事件: websiteId=\(websiteId)")
        
        // 查找并打开网站
        let websites = websiteManager.getWebsites(mode: .all)
        if let website = websites.first(where: { $0.id == websiteId }) {
            print("[HotKeyManager] 找到对应网站: name=\(website.name), url=\(website.url)")
            guard let url = URL(string: website.url) else {
                print("[HotKeyManager] ❌ URL无效: \(website.url)")
                return
            }
            NSWorkspace.shared.open(url)
            print("[HotKeyManager] ✅ 成功打开网站: \(website.name)")
        } else {
            print("[HotKeyManager] ❌ 未找到对应网站: websiteId=\(websiteId)")
        }
    }
    
    private func handleAppHotKey(bundleId: String) {
        print("[HotKeyManager] 开始处理应用热键事件: bundleId=\(bundleId)")
        
        // 检查当前活跃的应用是否是目标应用
        if let currentApp = NSWorkspace.shared.frontmostApplication,
           currentApp.bundleIdentifier == bundleId {
            // 如果是，则切换回上一个应用
            if let lastApp = lastActiveApp {
                print("[HotKeyManager] 切换回上一个应用: \(lastApp.localizedName ?? "")")
                lastApp.activate(options: [.activateIgnoringOtherApps])
            }
        } else {
            // 如果不是，则记录当前应用并切换到目标应用
            lastActiveApp = NSWorkspace.shared.frontmostApplication
            
            // 先尝试激活已运行的应用
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first {
                let success = app.activate(options: [.activateIgnoringOtherApps])
                print("[HotKeyManager] 激活运行中的应用: \(success)")
                return
            }
            
            // 如果应用未运行，则启动它
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                do {
                    let config = NSWorkspace.OpenConfiguration()
                    config.activates = true
                    try NSWorkspace.shared.openApplication(at: url, configuration: config)
                    print("[HotKeyManager] 启动应用: \(url)")
                } catch {
                    print("[HotKeyManager] ❌ 启动应用失败: \(error)")
                }
            } else {
                print("[HotKeyManager] ❌ 未找到应用: \(bundleId)")
            }
        }
    }
} 
