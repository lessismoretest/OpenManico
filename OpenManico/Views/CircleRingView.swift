import SwiftUI
import AppKit
import AVFoundation
import AudioToolbox

/**
 * 圆环视图
 * 显示圆环形式的应用快捷图标
 */
struct CircleRingView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var circleController = CircleRingController.shared
    @State private var hoveredIndex: Int? = nil
    @State var apps: [AppInfo] = []
    @State var selectedIndex: Int? = nil
    @Environment(\.colorScheme) var systemColorScheme
    
    // 音效播放器
    private let soundPlayer = SoundPlayer.shared
    
    // 添加状态变量追踪动画
    @State private var showRingAnimation: Bool = false
    @State private var ringScale: CGFloat = 0.5
    
    // 添加图标显示动画状态
    @State private var showIcons: [Bool] = []
    @State private var iconAnimationCompleted: Bool = false
    @State private var iconScales: [CGFloat] = []
    
    private var circleRadius: CGFloat {
        settings.circleRingDiameter / 2
    }
    
    // 根据设置获取当前应该使用的颜色方案
    private var effectiveColorScheme: ColorScheme {
        switch settings.circleRingTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return systemColorScheme
        }
    }
    
    // 获取背景颜色
    private var backgroundColor: Color {
        if settings.useBlurEffectForCircleRing {
            return effectiveColorScheme == .dark ? Color.black.opacity(0.15) : Color.white.opacity(0.15)
        } else {
            // 当不使用毛玻璃效果时，使用设置的透明度
            return effectiveColorScheme == .dark ? Color.black.opacity(settings.circleRingOpacity) : Color.white.opacity(settings.circleRingOpacity)
        }
    }
    
    // 获取内圈颜色
    private var innerCircleColor: Color {
        effectiveColorScheme == .dark ? Color.white.opacity(settings.innerCircleOpacity) : Color.black.opacity(settings.innerCircleOpacity * 0.5)
    }
    
    // 获取内圆填充颜色
    private var innerCircleFillColor: Color {
        effectiveColorScheme == .dark ? Color.white.opacity(settings.innerCircleFillOpacity) : Color.black.opacity(settings.innerCircleFillOpacity * 0.5)
    }
    
    // 获取中央指示颜色
    private var centerIndicatorColor: Color {
        effectiveColorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
    }
    
    // 获取悬停背景颜色
    private var hoverBackgroundColor: Color {
        effectiveColorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.2)
    }
    
    // 获取扇区高亮颜色
    private var sectorHighlightColor: Color {
        if effectiveColorScheme == .dark {
            return Color.white.opacity(settings.sectorHighlightOpacity)
        } else {
            return Color.black.opacity(settings.sectorHighlightOpacity)
        }
    }
    
    // 获取文本颜色
    private var textColor: Color {
        effectiveColorScheme == .dark ? Color.white : Color.black
    }
    
    // 获取文本背景颜色
    private var textBackgroundColor: Color {
        effectiveColorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.7)
    }
    
    // 获取毛玻璃效果材质
    private var blurMaterial: NSVisualEffectView.Material {
        // 使用与悬浮窗一致的材质
        .hudWindow
    }
    
    // 记录当前鼠标在哪个扇区
    private var currentSectorIndex: Int = -1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 创建一个完全透明的视图作为占位符
                Color.clear
                
                // 圆环形毛玻璃效果 - 只渲染环形部分
                RingShape(
                    innerRadius: settings.circleRingInnerDiameter / 2,
                    outerRadius: settings.circleRingDiameter / 2
                )
                .fill(Color.clear) // 先用透明色填充形状
                .background(
                    Group {
                        if settings.useBlurEffectForCircleRing {
                            // 启用毛玻璃效果
                            VisualEffectView(material: blurMaterial, blendingMode: .behindWindow)
                                .clipShape(
                                    RingShape(
                                        innerRadius: settings.circleRingInnerDiameter / 2,
                                        outerRadius: settings.circleRingDiameter / 2
                                    )
                                )
                        } else {
                            // 不使用毛玻璃效果，仅使用半透明背景色
                            RingShape(
                                innerRadius: settings.circleRingInnerDiameter / 2,
                                outerRadius: settings.circleRingDiameter / 2
                            )
                            .fill(backgroundColor)
                        }
                    }
                )
                .scaleEffect(settings.useCircleRingAnimation ? ringScale : 1)
                .opacity(settings.useCircleRingAnimation ? (showRingAnimation ? 1 : 0) : 1)
                
                // 当不使用毛玻璃效果时，不再需要额外的圆环颜色层
                if settings.useBlurEffectForCircleRing {
                    // 圆环颜色层 - 半透明填充，仅在使用毛玻璃效果时需要
                    RingShape(
                        innerRadius: settings.circleRingInnerDiameter / 2,
                        outerRadius: settings.circleRingDiameter / 2
                    )
                    .fill(backgroundColor)
                    .scaleEffect(settings.useCircleRingAnimation ? ringScale : 1)
                    .opacity(settings.useCircleRingAnimation ? (showRingAnimation ? 1 : 0) : 1)
                }
                
                // 当鼠标悬停时绘制扇区高亮
                if settings.useSectorHighlight, let hoveredIdx = hoveredIndex {
                    // 使用一个ZStack包裹以确保id正确应用于整个扇区
                    ZStack {
                        sectorHighlightShape(for: hoveredIdx)
                            .fill(sectorHighlightColor)
                    }
                    .animation(.easeInOut(duration: 0.2), value: hoveredIdx)
                    .transition(.opacity)
                    .id("sector-\(hoveredIdx)")  // 确保使用唯一id
                }
                
                // 内圆填充 - 只有在设置启用时才显示
                if settings.showInnerCircleFill {
                    Circle()
                        .fill(innerCircleFillColor)
                        .frame(width: settings.circleRingInnerDiameter, height: settings.circleRingInnerDiameter)
                        .scaleEffect(settings.useCircleRingAnimation ? ringScale : 1)
                        .opacity(settings.useCircleRingAnimation ? (showRingAnimation ? 1 : 0) : 1)
                }
                
                // 内圈边框 - 只有在设置启用时才显示
                if settings.showInnerCircle {
                    Circle()
                        .stroke(innerCircleColor, lineWidth: 1)
                        .frame(width: settings.circleRingInnerDiameter, height: settings.circleRingInnerDiameter)
                        .scaleEffect(settings.useCircleRingAnimation ? ringScale : 1)
                        .opacity(settings.useCircleRingAnimation ? (showRingAnimation ? 1 : 0) : 1)
                }
                
                // 中央指示 - 只有在设置启用时才显示
                if settings.showCenterIndicator {
                    Circle()
                        .fill(centerIndicatorColor)
                        .frame(width: settings.centerIndicatorSize, height: settings.centerIndicatorSize)
                        .scaleEffect(settings.useCircleRingAnimation ? ringScale : 1)
                        .opacity(settings.useCircleRingAnimation ? (showRingAnimation ? 1 : 0) : 1)
                }
                
                // 应用图标
                ForEach(0..<min(settings.circleRingSectorCount, apps.count), id: \.self) { index in
                    appIconView(for: index)
                        .opacity(settings.useCircleRingAnimation ? 
                                (settings.iconAppearAnimationType != .none ? 
                                 (index < showIcons.count && showIcons[index] ? 1 : 0) : 
                                 (showRingAnimation ? 1 : 0)) : 
                                1)
                }
                
                // 圆环背景，用于捕获全局鼠标移动
                Circle()
                    .fill(Color.clear)
                    .frame(width: settings.circleRingDiameter, height: settings.circleRingDiameter)
                    .contentShape(Circle()) // 显式设置命中测试形状
                    .allowsHitTesting(true)
                    .onHover { isHovered in
                        print("[CircleRingView] 鼠标悬停状态: \(isHovered ? "进入" : "离开")")
                        
                        // 如果鼠标离开视图，清除悬停索引
                        if !isHovered {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredIndex = nil
                            }
                        } else {
                            // 鼠标进入时，立即检测位置
                            DispatchQueue.main.async {
                                // 获取当前鼠标位置并处理
                                // 寻找圆环窗口 - 使用更可靠的窗口检测方法
                                var circleRingWindow: NSWindow?
                                
                                // 1. 先尝试找没有标题的窗口（圆环窗口通常没有标题）
                                for window in NSApp.windows where window.isVisible && window.title.isEmpty {
                                    // 检查窗口尺寸是否接近圆环尺寸，帮助识别圆环窗口
                                    if abs(window.frame.width - settings.circleRingDiameter) < 10 {
                                        circleRingWindow = window
                                        print("[CircleRingView] 悬停检测找到圆环窗口：尺寸匹配")
                                        break
                                    }
                                }
                                
                                // 2. 如果没找到，查找层级为popUpMenu的窗口
                                if circleRingWindow == nil {
                                    for window in NSApp.windows where window.isVisible && window.level.rawValue >= NSWindow.Level.popUpMenu.rawValue {
                                        circleRingWindow = window
                                        print("[CircleRingView] 悬停检测找到圆环窗口：层级匹配")
                                        break
                                    }
                                }
                                
                                if let window = circleRingWindow {
                                    let mouseLocation = NSEvent.mouseLocation
                                    let windowOrigin = window.frame.origin
                                    
                                    // 将全局鼠标位置转换为视图内位置
                                    let viewX = mouseLocation.x - windowOrigin.x
                                    let viewY = mouseLocation.y - windowOrigin.y
                                    handleMouseMoved(location: CGPoint(x: viewX, y: viewY))
                                } else {
                                    print("[CircleRingView] 悬停检测无法找到窗口")
                                }
                            }
                        }
                    }
                    .gesture( // 使用普通手势以确保最高优先级
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // 当拖动手势开始或改变时，处理鼠标移动
                                handleMouseMoved(location: value.location)
                            }
                    )
                    .onAppear {
                        // 窗口出现时自动检测当前鼠标位置
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            // 获取窗口中心点，用于计算相对位置
                            let center = CGPoint(x: circleRadius, y: circleRadius)
                            handleMouseMoved(location: center)
                            print("[CircleRingView] 初始检测鼠标位置: \(center)")
                        }
                        
                        // 添加通知监听来强制更新鼠标位置
                        NotificationCenter.default.addObserver(
                            forName: NSNotification.Name("ForceUpdateMousePosition"),
                            object: nil,
                            queue: .main) { _ in
                                
                                // 寻找圆环窗口 - 使用更可靠的窗口检测方法
                                var circleRingWindow: NSWindow?
                                
                                // 1. 先尝试找没有标题的窗口（圆环窗口通常没有标题）
                                for window in NSApp.windows where window.isVisible && window.title.isEmpty {
                                    // 检查窗口尺寸是否接近圆环尺寸，帮助识别圆环窗口
                                    if abs(window.frame.width - settings.circleRingDiameter) < 10 {
                                        circleRingWindow = window
                                        print("[CircleRingView] 强制更新找到圆环窗口：尺寸匹配")
                                        break
                                    }
                                }
                                
                                // 2. 如果没找到，查找层级为popUpMenu的窗口
                                if circleRingWindow == nil {
                                    for window in NSApp.windows where window.isVisible && window.level.rawValue >= NSWindow.Level.popUpMenu.rawValue {
                                        circleRingWindow = window
                                        print("[CircleRingView] 强制更新找到圆环窗口：层级匹配")
                                        break
                                    }
                                }
                                
                                // 获取最新的鼠标位置
                                if let window = circleRingWindow {
                                    let mouseLocation = NSEvent.mouseLocation
                                    let windowOrigin = window.frame.origin
                                    
                                    // 将全局鼠标位置转换为视图内位置
                                    let viewX = mouseLocation.x - windowOrigin.x
                                    let viewY = mouseLocation.y - windowOrigin.y
                                    
                                    // 处理鼠标移动
                                    self.handleMouseMoved(location: CGPoint(x: viewX, y: viewY))
                                } else {
                                    print("[CircleRingView] 强制更新无法找到圆环窗口")
                                }
                            }
                    }
                    .onDisappear {
                        // 移除通知监听
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ForceUpdateMousePosition"), object: nil)
                    }
            }
            .frame(width: settings.circleRingDiameter, height: settings.circleRingDiameter)
        }
        .frame(width: settings.circleRingDiameter, height: settings.circleRingDiameter)
        .onAppear {
            loadApps()
            print("[CircleRingView] 视图已出现，加载了 \(apps.count) 个应用")
            
            // 添加动画效果
            if settings.useCircleRingAnimation {
                // 确保每次视图出现时都重置动画状态
                ringScale = 0.5
                showRingAnimation = false
                iconAnimationCompleted = false
                
                // 重置图标显示状态
                if settings.iconAppearAnimationType != .none {
                    showIcons = Array(repeating: false, count: min(settings.circleRingSectorCount, apps.count))
                    iconScales = Array(repeating: 0.5, count: min(settings.circleRingSectorCount, apps.count))
                }
                
                // 延迟一点点再开始动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showRingAnimation = true
                        ringScale = 1.0
                    }
                    
                    // 如果启用了图标显示动画
                    if settings.iconAppearAnimationType != .none {
                        // 圆环展开后开始图标动画
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let iconCount = min(settings.circleRingSectorCount, apps.count)
                            
                            // 根据动效类型确定图标显示顺序
                            let indices: [Int]
                            switch settings.iconAppearAnimationType {
                            case .clockwise:
                                indices = Array(0..<iconCount) // 顺时针：0,1,2,3...
                            case .counterClockwise:
                                indices = Array((0..<iconCount).reversed()) // 逆时针：n,n-1,n-2...
                            default:
                                indices = Array(0..<iconCount)
                            }
                            
                            // 按确定的顺序显示图标
                            for (displayOrder, i) in indices.enumerated() {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(displayOrder) * Double(settings.iconAppearSpeed)) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2)) {
                                        if i < showIcons.count {
                                            showIcons[i] = true
                                            iconScales[i] = 1.2 // 先放大超过目标大小
                                        }
                                    }
                                    
                                    // 额外添加一个弹性回弹动画，延迟时间与显示速度成比例
                                    DispatchQueue.main.asyncAfter(deadline: .now() + max(0.08, Double(settings.iconAppearSpeed) * 2)) {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                            if i < iconScales.count {
                                                iconScales[i] = 1.0 // 回弹到正常大小
                                            }
                                        }
                                    }
                                    
                                    // 最后一个图标显示完成后，标记动画完成
                                    if displayOrder == iconCount - 1 {
                                        let completionDelay = max(0.1, Double(settings.iconAppearSpeed) * 3)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) {
                                            iconAnimationCompleted = true
                                            circleController.iconsAnimationCompleted = true
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // 如果未启用图标显示动画，直接标记为完成
                        iconAnimationCompleted = true
                        circleController.iconsAnimationCompleted = true
                    }
                }
            } else {
                // 如果不使用动画，确保直接显示
                showRingAnimation = true
                ringScale = 1.0
                iconAnimationCompleted = true
                circleController.iconsAnimationCompleted = true
            }
            
            // 添加通知观察者，用于响应圆环重新显示的通知
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("CircleRingDidAppear"),
                object: nil,
                queue: .main) { [self] _ in
                    guard settings.useCircleRingAnimation else { return }
                    
                    // 重置动画状态
                    self.ringScale = 0.5
                    self.showRingAnimation = false
                    self.iconAnimationCompleted = false
                    
                    // 重置图标显示状态
                    if settings.iconAppearAnimationType != .none {
                        self.showIcons = Array(repeating: false, count: min(settings.circleRingSectorCount, self.apps.count))
                        self.iconScales = Array(repeating: 0.5, count: min(settings.circleRingSectorCount, self.apps.count))
                    }
                    
                    // 立即应用动画
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            self.showRingAnimation = true
                            self.ringScale = 1.0
                        }
                        
                        // 如果启用了图标显示动画
                        if settings.iconAppearAnimationType != .none {
                            // 圆环展开后开始图标动画
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                let iconCount = min(settings.circleRingSectorCount, self.apps.count)
                                
                                // 根据动效类型确定图标显示顺序
                                let indices: [Int]
                                switch settings.iconAppearAnimationType {
                                case .clockwise:
                                    indices = Array(0..<iconCount) // 顺时针：0,1,2,3...
                                case .counterClockwise:
                                    indices = Array((0..<iconCount).reversed()) // 逆时针：n,n-1,n-2...
                                default:
                                    indices = Array(0..<iconCount)
                                }
                                
                                // 按确定的顺序显示图标
                                for (displayOrder, i) in indices.enumerated() {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(displayOrder) * Double(settings.iconAppearSpeed)) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2)) {
                                            if i < self.showIcons.count {
                                                self.showIcons[i] = true
                                                self.iconScales[i] = 1.2 // 先放大超过目标大小
                                            }
                                        }
                                        
                                        // 额外添加一个弹性回弹动画，延迟时间与显示速度成比例
                                        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.08, Double(settings.iconAppearSpeed) * 2)) {
                                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                                if i < self.iconScales.count {
                                                    self.iconScales[i] = 1.0 // 回弹到正常大小
                                                }
                                            }
                                        }
                                        
                                        // 最后一个图标显示完成后，标记动画完成
                                        if displayOrder == iconCount - 1 {
                                            let completionDelay = max(0.1, Double(settings.iconAppearSpeed) * 3)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) {
                                                self.iconAnimationCompleted = true
                                                self.circleController.iconsAnimationCompleted = true
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // 如果未启用图标显示动画，直接标记为完成
                            self.iconAnimationCompleted = true
                            self.circleController.iconsAnimationCompleted = true
                        }
                    }
                    
                    print("[CircleRingView] 响应圆环显示通知，应用动画效果")
                }
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ForceUpdateMousePosition"), object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("CircleRingDidAppear"), object: nil)
        }
    }
    
    // 处理鼠标移动
    private func handleMouseMoved(location: CGPoint) {
        // 计算鼠标相对于圆心的位置
        let relativeX = location.x - circleRadius
        let relativeY = circleRadius - location.y
        
        // 打印原始相对位置，帮助调试
        print("[CircleRingView] 原始相对位置: (\(relativeX), \(relativeY))")
        
        // 计算当前角度 - 使用标准数学坐标系中的atan2
        var angle = atan2(relativeY, relativeX)
        
        // 将角度规范化为 [0, 2π] 范围
        if angle < 0 {
            angle += 2 * .pi
        }
        
        // 计算距离圆心的距离
        let distance = sqrt(relativeX * relativeX + relativeY * relativeY)
        
        // 获取扇区总数
        let totalSectors = min(settings.circleRingSectorCount, apps.count)
        if totalSectors == 0 {
            // 没有应用，不处理扇区
            return
        }
        
        // 检查位置是否在屏幕边缘
        // 如果在屏幕边缘，则放宽检测标准，以便于用户在屏幕边缘也能选择应用
        var isNearScreenEdge = false
        
        // 寻找圆环窗口 - 使用更可靠的窗口检测方法
        var circleRingWindow: NSWindow?
        
        // 1. 先尝试找没有标题的窗口（圆环窗口通常没有标题）
        for window in NSApp.windows where window.isVisible && window.title.isEmpty {
            // 检查窗口尺寸是否接近圆环尺寸，帮助识别圆环窗口
            if abs(window.frame.width - settings.circleRingDiameter) < 10 {
                circleRingWindow = window
                break
            }
        }
        
        // 2. 如果没找到，查找层级为popUpMenu的窗口
        if circleRingWindow == nil {
            for window in NSApp.windows where window.isVisible && window.level.rawValue >= NSWindow.Level.popUpMenu.rawValue {
                circleRingWindow = window
                break
            }
        }
        
        if let window = circleRingWindow {
            let mouseLocation = NSEvent.mouseLocation
            if let screen = NSScreen.screens.first(where: { NSPointInRect(mouseLocation, $0.frame) }) {
                let screenFrame = screen.visibleFrame
                
                // 计算鼠标距离屏幕边缘的距离
                let distanceToLeftEdge = mouseLocation.x - screenFrame.minX
                let distanceToRightEdge = screenFrame.maxX - mouseLocation.x
                let distanceToTopEdge = screenFrame.maxY - mouseLocation.y
                let distanceToBottomEdge = mouseLocation.y - screenFrame.minY
                
                // 确定边缘阈值 - 使用圆环半径的一小部分
                let edgeThreshold = circleRadius * 0.3
                
                // 判断是否靠近屏幕边缘
                isNearScreenEdge = distanceToLeftEdge < edgeThreshold ||
                                  distanceToRightEdge < edgeThreshold ||
                                  distanceToTopEdge < edgeThreshold ||
                                  distanceToBottomEdge < edgeThreshold
                
                if isNearScreenEdge {
                    print("[CircleRingView] 检测到鼠标靠近屏幕边缘，放宽扇区选择标准")
                }
            }
        } else {
            // 如果找不到窗口，保守地假设不在屏幕边缘
            isNearScreenEdge = false
            print("[CircleRingView] 无法找到圆环窗口确定屏幕边缘")
        }
        
        // 确保鼠标在圆环区域内 - 根据是否在屏幕边缘调整检测范围
        let innerRadius = (settings.circleRingInnerDiameter / 2) * (isNearScreenEdge ? 0.1 : 0.3)
        let outerRadius = circleRadius * (isNearScreenEdge ? 1.5 : 1.1)
        
        print("[CircleRingView] 鼠标移动: 角度=\(angle * 180 / .pi)°, 距离=\(distance), 内径=\(innerRadius), 外径=\(outerRadius), 相对位置: (\(relativeX), \(relativeY)), 靠近屏幕边缘: \(isNearScreenEdge)")
        
        // 扇区角度
        let angleSlice = 2 * .pi / CGFloat(totalSectors)
        
        // 计算扇区索引 - 第一个扇区从正上方开始，顺时针旋转
        var sectorIndex: Int
        
        // 将角度转换为以正上方为0度的坐标系
        let normalizedAngle = (angle + .pi / 2).truncatingRemainder(dividingBy: 2 * .pi)
        
        // 计算扇区索引
        sectorIndex = Int(floor(normalizedAngle / angleSlice))
        
        // 确保索引在有效范围内
        sectorIndex = sectorIndex % totalSectors
        
        // 优化悬停检测逻辑
        var validIndex: Int? = nil
        
        if distance <= innerRadius {
            // 在内圈很近时，不选择任何扇区
            validIndex = nil
        } else if distance >= outerRadius && !isNearScreenEdge {
            // 在外圈很远时，不选择任何扇区 (除非在屏幕边缘)
            validIndex = nil
            // 确保清除选中状态
            selectedIndex = nil
            print("[CircleRingView] 鼠标移出圆环区域，清除选择")
        } else {
            // 在扇区范围内或在屏幕边缘
            validIndex = sectorIndex
            // 确保选择的索引有效，即使鼠标位置靠近边界
            selectedIndex = sectorIndex
        }
        
        // 如果扇区不同，更新悬停索引
        if validIndex != hoveredIndex {
            print("[CircleRingView] 鼠标移动到扇区: \(String(describing: validIndex)), 角度: \(angle * 180 / .pi)°, 归一化角度: \(normalizedAngle * 180 / .pi)°, 扇区角度: \(angleSlice * 180 / .pi)°, 索引: \(sectorIndex)")
            
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredIndex = validIndex
            }
            
            // 更新选中的应用索引
            selectedIndex = validIndex
            
            // 将当前选择的扇区索引同步到CircleRingController
            if let index = validIndex {
                circleController.selectedAppIndex = index
                print("[CircleRingView] 已更新CircleRingController的selectedAppIndex: \(index)")
                
                // 如果启用了音效，播放雷达扫描音效
                if settings.useSectorHoverSound {
                    soundPlayer.playRadarSound()
                }
            } else {
                // 如果移出区域，也更新控制器的选中索引为nil
                circleController.selectedAppIndex = nil
                print("[CircleRingView] 清除CircleRingController的selectedAppIndex")
            }
            
            // 如果图标变化了，则打印选择的应用信息
            if let idx = validIndex, idx < apps.count {
                print("[CircleRingView] 当前选中应用: \(apps[idx].name) (\(apps[idx].bundleId))")
            }
        }
    }
    
    // 加载应用列表
    func loadApps() {
        let configuredApps = settings.circleRingApps
        if !configuredApps.isEmpty {
            // 使用用户配置的应用
            print("[CircleRingView] 开始加载用户配置的应用，共 \(configuredApps.count) 个")
            
            var loadedApps: [AppInfo] = []
            for bundleId in configuredApps {
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                    let appName = url.deletingPathExtension().lastPathComponent
                    let icon = NSWorkspace.shared.icon(forFile: url.path)
                    loadedApps.append(AppInfo(bundleId: bundleId, name: appName, icon: icon, url: url))
                    print("[CircleRingView] 已加载应用: \(appName) (\(bundleId))")
                } else {
                    print("[CircleRingView] ⚠️ 无法加载应用，未找到 Bundle ID: \(bundleId)")
                }
            }
            
            if loadedApps.isEmpty {
                print("[CircleRingView] ⚠️ 未能加载任何用户配置的应用，将使用默认应用")
                loadDefaultApps()
            } else {
                apps = loadedApps
            }
        } else {
            // 使用默认的应用（常用系统应用）
            print("[CircleRingView] 用户未配置应用，将使用默认应用")
            loadDefaultApps()
        }
        
        print("[CircleRingView] 最终加载了 \(apps.count) 个应用")
    }
    
    private func loadDefaultApps() {
        let defaultBundleIds = [
            "com.apple.finder",
            "com.apple.Safari",
            "com.apple.mail",
            "com.apple.systempreferences",
            "com.apple.calculator"
        ]
        
        apps = defaultBundleIds.compactMap { bundleId in
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
                print("[CircleRingView] ⚠️ 无法加载默认应用: \(bundleId)")
                return nil
            }
            let appName = url.deletingPathExtension().lastPathComponent
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            print("[CircleRingView] 已加载默认应用: \(appName) (\(bundleId))")
            return AppInfo(bundleId: bundleId, name: appName, icon: icon, url: url)
        }
    }
    
    // 计算每个应用图标的位置
    private func positionForIndex(_ index: Int, totalCount: Int) -> CGPoint {
        // 计算每个扇区的角度
        let angleSlice = 2 * CGFloat.pi / CGFloat(totalCount)
        let innerRadius = settings.circleRingInnerDiameter / 2
        let outerRadius = circleRadius
        
        // 计算图标应该放置的半径位置 - 内圈和外圈之间的中点
        let iconRadius = (innerRadius + outerRadius) / 2
        
        // 扇区中心角度 - 第一个扇区(index=0)从正上方开始，顺时针旋转
        let angle = (.pi / 2) - angleSlice * CGFloat(index) - (angleSlice / 2)
        
        // 计算位置 (注意SwiftUI中Y轴是向下为正，所以y坐标需要取反)
        let x = iconRadius * cos(angle)
        let y = -iconRadius * sin(angle)
        
        return CGPoint(x: x, y: y)
    }
    
    // 创建单个应用图标视图
    private func appIconView(for index: Int) -> some View {
        let totalCount = min(settings.circleRingSectorCount, apps.count)
        let app = apps[index]
        let position = positionForIndex(index, totalCount: totalCount)
        let iconSize = settings.circleRingIconSize
        let isHovered = hoveredIndex == index
        
        return ZStack {
            // 应用图标
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .cornerRadius(settings.circleRingIconCornerRadius)
                .shadow(color: .black.opacity(0.3), radius: isHovered ? 4 : 2, x: 0, y: 2)
                .scaleEffect(settings.useIconAppearAnimation && settings.useCircleRingAnimation ? 
                            (index < iconScales.count ? (showIcons[index] ? 1.0 : iconScales[index]) : 1.0) : 
                            (isHovered ? 1.1 : 1.0))
                .animation(.spring(response: 0.2), value: isHovered)
            
            // 显示应用名称
            if isHovered {
                Text(app.name)
                    .font(.caption)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(textBackgroundColor)
                    .cornerRadius(4)
                    .offset(y: iconSize / 2 + 16)
                    .transition(.opacity)
            }
        }
        .position(x: position.x + circleRadius, y: position.y + circleRadius)
    }
    
    // 计算扇区交互区域
    private func calculateSectorArea(for index: Int, totalCount: Int) -> some Shape {
        return sectorHighlightShape(for: index)
    }
    
    // 创建扇区高亮形状
    private func sectorHighlightShape(for index: Int) -> some Shape {
        let totalCount = min(settings.circleRingSectorCount, apps.count)
        let angleSlice = 2 * .pi / CGFloat(totalCount)
        
        // 重要：使用与handleMouseMoved完全相同的角度计算逻辑
        // 注意 handleMouseMoved 中使用 normalizedAngle = (angle + .pi / 2).truncatingRemainder(dividingBy: 2 * .pi)
        // 计算扇区索引 sectorIndex = Int(floor(normalizedAngle / angleSlice))
        
        // 将扇区索引转换回角度范围
        // 计算扇区起始角度（扇区逆时针边缘）
        let sectorStartNormalizedAngle = angleSlice * CGFloat(index)
        // 计算扇区结束角度（扇区顺时针边缘）
        let sectorEndNormalizedAngle = angleSlice * CGFloat(index + 1)
        
        // 从规范化角度转换回原始atan2角度（减去π/2）
        let startAngle = sectorStartNormalizedAngle - (.pi / 2)
        let endAngle = sectorEndNormalizedAngle - (.pi / 2)
        
        print("[CircleRingView] 扇区高亮: 索引=\(index), 总数=\(totalCount), " +
              "扇区角度=\(angleSlice * 180 / .pi)°, " +
              "规范化起始角度=\(sectorStartNormalizedAngle * 180 / .pi)°, " +
              "规范化结束角度=\(sectorEndNormalizedAngle * 180 / .pi)°, " +
              "绘制起始角度=\(startAngle * 180 / .pi)°, " +
              "绘制结束角度=\(endAngle * 180 / .pi)°")
        
        return SectorShape(
            center: CGPoint(x: circleRadius, y: circleRadius),
            radius: circleRadius,
            innerRadius: settings.circleRingInnerDiameter / 2,  // 修改为与内圆完全相同的直径
            startAngle: startAngle,
            endAngle: endAngle,
            sectorIndex: index
        )
    }
    
    // 获取当前选中的应用信息
    func getSelectedApp() -> AppInfo? {
        guard let index = selectedIndex, index >= 0, index < apps.count else {
            print("[CircleRingView] getSelectedApp: 没有有效的选中索引, selectedIndex=\(String(describing: selectedIndex))")
            
            // 尝试使用悬停索引作为备用 - 但仅当悬停索引有效时
            if let hoverIndex = hoveredIndex, hoverIndex >= 0, hoverIndex < apps.count {
                print("[CircleRingView] getSelectedApp: 使用悬停索引作为备用, hoveredIndex=\(hoverIndex)")
                return apps[hoverIndex]
            }
            
            print("[CircleRingView] getSelectedApp: 没有选中任何扇区，返回nil")
            return nil
        }
        
        // 计算鼠标相对于圆心的位置，再次检查是否在有效范围内
        let mouseLocation = NSEvent.mouseLocation
        
        // 寻找圆环窗口 - 使用更可靠的窗口检测方法
        var circleRingWindow: NSWindow?
        
        // 1. 先尝试找没有标题的窗口（圆环窗口通常没有标题）
        for window in NSApp.windows where window.isVisible && window.title.isEmpty {
            // 检查窗口尺寸是否接近圆环尺寸，帮助识别圆环窗口
            if abs(window.frame.width - settings.circleRingDiameter) < 10 {
                circleRingWindow = window
                print("[CircleRingView] 找到圆环窗口：尺寸匹配")
                break
            }
        }
        
        // 2. 如果没找到，查找层级为popUpMenu+2的窗口
        if circleRingWindow == nil {
            for window in NSApp.windows where window.isVisible && window.level.rawValue >= NSWindow.Level.popUpMenu.rawValue {
                circleRingWindow = window
                print("[CircleRingView] 找到圆环窗口：层级匹配")
                break
            }
        }
        
        if let window = circleRingWindow {
            let windowOrigin = window.frame.origin
            let viewX = mouseLocation.x - windowOrigin.x
            let viewY = mouseLocation.y - windowOrigin.y
            
            // 计算相对于圆心的位置
            let relativeX = viewX - circleRadius
            let relativeY = circleRadius - viewY
            
            // 计算距离圆心的距离
            let distance = sqrt(relativeX * relativeX + relativeY * relativeY)
            
            // 检查是否在圆环有效范围内
            let innerRadius = (settings.circleRingInnerDiameter / 2) * 0.3
            let outerRadius = circleRadius * 1.1
            
            if distance <= innerRadius || distance >= outerRadius {
                print("[CircleRingView] getSelectedApp: 鼠标不在有效区域内，距离=\(distance), 返回nil")
                return nil
            }
        } else {
            print("[CircleRingView] getSelectedApp: 无法找到圆环窗口，使用备用逻辑")
            // 如果找不到窗口，直接返回当前索引的应用
        }
        
        print("[CircleRingView] getSelectedApp: 返回选中的应用 #\(index) - \(apps[index].name)")
        return apps[index]
    }
    
    // 启动应用
    func launchApp(_ app: AppInfo) {
        // 隐藏圆环
        circleController.hideCircleRing()
        
        // 打开应用
        if let url = app.url {
            print("[CircleRingView] 正在尝试打开应用: \(app.name) (\(app.bundleId)), 路径: \(url.path)")
            
            // 尝试直接使用bundleId启动，这通常更可靠
            if !NSWorkspace.shared.launchApplication(withBundleIdentifier: app.bundleId, 
                                                    options: [.default], 
                                                    additionalEventParamDescriptor: nil, 
                                                    launchIdentifier: nil) {
                // 如果使用bundleId启动失败，尝试使用URL直接打开
                print("[CircleRingView] 通过bundleId启动失败，尝试使用URL打开")
                NSWorkspace.shared.open(url)
            }
            
            print("[CircleRingView] 启动应用: \(app.name) 完成")
        } else {
            print("[CircleRingView] 无法启动应用，URL为nil: \(app.name) (\(app.bundleId))")
        }
        
        // 增加使用计数
        settings.incrementUsageCount()
    }
}

// 扇区高亮形状，与鼠标检测完全匹配
struct SectorShape: Shape {
    let center: CGPoint
    let radius: CGFloat
    let innerRadius: CGFloat
    let startAngle: CGFloat  // 原始角度（atan2计算得到的角度）
    let endAngle: CGFloat    // 原始角度（atan2计算得到的角度）
    let sectorIndex: Int
    let cornerRadius: CGFloat = 3
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 为圆角稍微调整角度
        let cornerAdjustment = cornerRadius / (radius * 1.5)
        
        // 直接用于SwiftUI的角度，SwiftUI中0度在右侧，顺时针为正
        let swiftUIStartAngle = startAngle + cornerAdjustment
        let swiftUIEndAngle = endAngle - cornerAdjustment
        
        // 外弧起点
        let startPointOuter = CGPoint(
            x: center.x + radius * cos(swiftUIStartAngle),
            y: center.y + radius * sin(swiftUIStartAngle)
        )
        
        // 内弧起点
        let startPointInner = CGPoint(
            x: center.x + innerRadius * cos(swiftUIStartAngle),
            y: center.y + innerRadius * sin(swiftUIStartAngle)
        )
        
        // 外弧终点
        let endPointOuter = CGPoint(
            x: center.x + radius * cos(swiftUIEndAngle),
            y: center.y + radius * sin(swiftUIEndAngle)
        )
        
        // 内弧终点
        let endPointInner = CGPoint(
            x: center.x + innerRadius * cos(swiftUIEndAngle),
            y: center.y + innerRadius * sin(swiftUIEndAngle)
        )
        
        // 绘制路径
        path.move(to: startPointOuter)
        
        // 外弧 - SwiftUI中clockwise参数为false表示顺时针，因为SwiftUI的坐标系中Y轴向下
        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(radians: Double(swiftUIStartAngle)),
            endAngle: Angle(radians: Double(swiftUIEndAngle)),
            clockwise: false // 顺时针
        )
        
        // 外弧终点到内弧终点的圆角过渡
        path.addQuadCurve(
            to: endPointInner,
            control: CGPoint(
                x: endPointOuter.x + cornerRadius * cos(swiftUIEndAngle + .pi/2),
                y: endPointOuter.y + cornerRadius * sin(swiftUIEndAngle + .pi/2)
            )
        )
        
        // 内弧 - 逆时针绘制
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: Angle(radians: Double(swiftUIEndAngle)),
            endAngle: Angle(radians: Double(swiftUIStartAngle)),
            clockwise: true // 逆时针
        )
        
        // 内弧起点到外弧起点的圆角过渡
        path.addQuadCurve(
            to: startPointOuter,
            control: CGPoint(
                x: startPointInner.x + cornerRadius * cos(swiftUIStartAngle - .pi/2),
                y: startPointInner.y + cornerRadius * sin(swiftUIStartAngle - .pi/2)
            )
        )
        
        return path
    }
}

// 毛玻璃效果视图
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

// 音效播放器单例
class SoundPlayer {
    static let shared = SoundPlayer()
    
    // 音效播放器
    private var audioPlayers: [SectorHoverSoundType: AVAudioPlayer] = [:]
    private var systemSounds: [SectorHoverSoundType: SystemSoundID] = [:]
    private var nsSounds: [SectorHoverSoundType: NSSound] = [:]
    
    // 常用系统音效ID
    private let systemSoundIDs: [SectorHoverSoundType: SystemSoundID] = [
        .ping: 1103,
        .tink: 1104,
        .submarine: 1008,
        .bottle: 1020,
        .pop: 1057,
        .frog: 1000,
        .basso: 1006,
        .funk: 1007,
        .glass: 1009,
        .morse: 1013,
        .purr: 1014,
        .sosumi: 1010, // 修改ID，避免与frog冲突
        // 轻快类音效
        .click: 1105
    ]
    
    private init() {
        // 初始化所有音效
        prepareAllSounds()
    }
    
    private func prepareAllSounds() {
        // 预加载所有类型的音效
        let soundTypes: [SectorHoverSoundType] = [
            .ping, .tink, .submarine, .bottle, .frog, .pop,
            .basso, .funk, .glass, .morse, .purr, .sosumi,
            .click
        ]
        
        for soundType in soundTypes {
            // 1. 尝试使用NSSound
            if let sound = NSSound(named: getSystemSoundName(for: soundType)) {
                nsSounds[soundType] = sound
                print("[SoundPlayer] 成功加载系统音效 \(soundType.rawValue) (NSSound)")
                continue
            }
            
            // 2. 尝试从应用包加载
            if let soundURL = Bundle.main.url(forResource: soundType.rawValue, withExtension: "aiff") {
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()
                    player.volume = 0.6
                    audioPlayers[soundType] = player
                    print("[SoundPlayer] 成功加载音效: \(soundType.rawValue) (AVAudioPlayer)")
                    continue
                } catch {
                    print("[SoundPlayer] 加载音效\(soundType.rawValue)失败: \(error)")
                }
            }
            
            // 3. 使用系统音效API
            if let soundID = systemSoundIDs[soundType] {
                var tempID: SystemSoundID = 0
                let soundPath = "/System/Library/Sounds/\(getSystemSoundName(for: soundType)).aiff"
                
                let result = AudioServicesCreateSystemSoundID(
                    URL(fileURLWithPath: soundPath) as CFURL,
                    &tempID
                )
                
                if result == kAudioServicesNoError && tempID != 0 {
                    systemSounds[soundType] = tempID
                    print("[SoundPlayer] 成功注册系统音效ID: \(tempID) 对应 \(soundType.rawValue)")
                } else {
                    // 使用预定义的ID
                    systemSounds[soundType] = soundID
                    print("[SoundPlayer] 使用预定义系统音效ID: \(soundID) 对应 \(soundType.rawValue)")
                }
            }
        }
        
        // 测试所有声音是否已加载
        print("[SoundPlayer] 已加载 \(nsSounds.count) 个NSSound音效, \(audioPlayers.count) 个AVAudioPlayer音效, \(systemSounds.count) 个系统音效ID")
    }
    
    // 将音效类型转换为系统声音文件名
    private func getSystemSoundName(for soundType: SectorHoverSoundType) -> String {
        switch soundType {
        case .ping: return "Ping"
        case .tink: return "Tink"
        case .submarine: return "Submarine"
        case .bottle: return "Bottle"
        case .frog: return "Frog"
        case .pop: return "Pop"
        case .basso: return "Basso"
        case .funk: return "Funk"
        case .glass: return "Glass"
        case .morse: return "Morse"
        case .purr: return "Purr"
        case .sosumi: return "Sosumi"
        // 轻快类音效
        case .click: return "Tink" // 使用Tink作为替代
        }
    }
    
    func playRadarSound() {
        // 获取当前设置的音效类型
        let soundType = AppSettings.shared.sectorHoverSoundType
        
        print("[SoundPlayer] 播放雷达扫描音效: \(soundType.rawValue)")
        
        // 1. 优先使用NSSound
        if let sound = nsSounds[soundType] {
            sound.stop()
            sound.volume = 0.7
            sound.play()
            print("[SoundPlayer] 使用NSSound播放: \(soundType.rawValue)")
            return
        }
        
        // 2. 其次使用AVAudioPlayer
        if let player = audioPlayers[soundType] {
            if player.isPlaying {
                player.stop()
                player.currentTime = 0
            }
            player.volume = 0.7
            player.play()
            print("[SoundPlayer] 使用AVAudioPlayer播放: \(soundType.rawValue)")
            return
        }
        
        // 3. 最后使用系统声音API
        if let soundID = systemSounds[soundType], soundID != 0 {
            print("[SoundPlayer] 使用AudioServices播放系统音效ID: \(soundID) 对应 \(soundType.rawValue)")
            AudioServicesPlaySystemSound(soundID)
            return
        }
        
        // 4. 所有方法都失败，使用默认音效
        print("[SoundPlayer] 没有可用的音效播放器，使用默认系统音效")
        AudioServicesPlaySystemSound(1104) // Tink音效
    }
    
    deinit {
        // 释放所有系统音效资源
        for (_, soundID) in systemSounds {
            if soundID != 0 {
                AudioServicesDisposeSystemSoundID(soundID)
            }
        }
        
        // 停止并释放所有NSSound
        for (_, sound) in nsSounds {
            sound.stop()
        }
        nsSounds.removeAll()
        
        // 释放所有AVAudioPlayer
        audioPlayers.removeAll()
    }
}

// 添加一个环形Shape，用于只绘制圆环部分
struct RingShape: Shape {
    var innerRadius: CGFloat
    var outerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 计算圆心
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // 创建外圆路径
        path.addArc(center: center, 
                   radius: outerRadius, 
                   startAngle: Angle(degrees: 0), 
                   endAngle: Angle(degrees: 360), 
                   clockwise: false)
        
        // 创建内圆路径(逆时针方向，这样可以挖空内部)
        path.addArc(center: center, 
                   radius: innerRadius, 
                   startAngle: Angle(degrees: 360), 
                   endAngle: Angle(degrees: 0), 
                   clockwise: true)
        
        // 闭合路径
        path.closeSubpath()
        
        return path
    }
} 