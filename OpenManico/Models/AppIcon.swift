import Foundation
import SwiftUI

struct AppIcon: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let iconName: String
    let unlockTime: Int
    let unlockMessage: String?
    
    static func == (lhs: AppIcon, rhs: AppIcon) -> Bool {
        return lhs.iconName == rhs.iconName
    }
    
    // 默认图标
    static let defaultIcon = AppIcon(
        name: "默认",
        iconName: "AppIcon", 
        unlockTime: 0,
        unlockMessage: nil
    )
    
    // 所有可用图标
    static let all: [AppIcon] = [
        defaultIcon,
        AppIcon(
            name: "Ghostty",
            iconName: "AppIconGhosttyImage", 
            unlockTime: 0,
            unlockMessage: "Ghostty图标"
        ),
        AppIcon(
            name: "Manico",
            iconName: "AppIconManicoImage", 
            unlockTime: 0,
            unlockMessage: "Manico图标"
        ),
        AppIcon(
            name: "Doraemon",
            iconName: "AppIconDoraemonImage", 
            unlockTime: 0,
            unlockMessage: "Doraemon图标"
        ),
        AppIcon(
            name: "手绘",
            iconName: "AppIconHandDrawnImage", 
            unlockTime: 0,
            unlockMessage: "手绘图标"
        ),
        AppIcon(
            name: "Emoji",
            iconName: "AppIconEmojiImage", 
            unlockTime: 0,
            unlockMessage: "Emoji图标"
        )
    ]
} 