import SwiftUI
import Charts

/**
 * 数据统计视图
 * 显示应用的各种使用统计数据，包括按类型和时间的使用频率
 */
struct UsageStatsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var usageData: [DailyUsage] = []
    @State private var typeStats: [UsageTypeStats] = []
    @State private var optionUsageStats: [UsageTypeStats] = [] // 添加Option键使用统计
    @State private var selectedTimeRange: Int = 7
    @State private var selectedUsageType: UsageType? = nil
    @State private var totalUsage: Int = 0
    
    // 时间范围选项
    private let timeRanges = [7, 30, 365]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 总使用次数
                totalUsageView
                
                // Option键使用统计
                optionUsageView
                
                Divider()
                
                // 使用类型分布
                usageTypeDistributionView
                
                Divider()
                
                // 使用趋势
                usageTrendView
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 650)
        .onAppear {
            loadData()
        }
    }
    
    // 总使用次数视图
    private var totalUsageView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("总计使用次数")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                Text("\(totalUsage)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("自应用安装以来的总使用次数")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    // 清除按钮
                    Button(action: {
                        confirmClearStats()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除统计数据")
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.windowBackgroundColor).opacity(0.3))
        .cornerRadius(10)
    }
    
    // Option键使用统计视图
    private var optionUsageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Option键使用方式")
                .font(.title2)
                .fontWeight(.bold)
            
            if #available(macOS 13.0, *) {
                // 饼图
                HStack {
                    if #available(macOS 14.0, *) {
                        OptionDonutChartView()
                            .frame(height: 220)
                    } else {
                        // macOS 13使用标准饼图
                        OptionPieChartView()
                            .frame(height: 220)
                    }
                    
                    // 图例
                    VStack(alignment: .leading, spacing: 8) {
                        let filteredStats = optionUsageStats.filter { 
                            $0.type == .optionClick || $0.type == .optionDoubleClick || $0.type == .optionLongPress 
                        }
                        
                        if filteredStats.isEmpty {
                            Text("暂无Option键使用数据")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(filteredStats) { stat in
                                HStack {
                                    Rectangle()
                                        .fill(getColorForType(stat.type))
                                        .frame(width: 16, height: 16)
                                        .cornerRadius(3)
                                    
                                    Text("\(stat.type.rawValue)")
                                        .font(.title3)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(stat.count) 次")
                                            .font(.headline)
                                        
                                        Text("(\(Int(stat.percentage))%)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.leading, 16)
                    .frame(minWidth: 200)
                }
                .padding()
                .background(Color(.windowBackgroundColor).opacity(0.3))
                .cornerRadius(10)
            } else {
                // 旧系统版本的替代视图
                legacyOptionStatsView
                    .padding()
                    .background(Color(.windowBackgroundColor).opacity(0.3))
                    .cornerRadius(10)
            }
        }
    }
    
    // 使用类型分布视图
    private var usageTypeDistributionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用方式分布")
                .font(.title2)
                .fontWeight(.bold)
            
            if #available(macOS 13.0, *) {
                // 饼图
                HStack {
                    if #available(macOS 14.0, *) {
                        DonutChartView()
                            .frame(height: 240)
                    } else {
                        // macOS 13使用标准饼图
                        SimplePieChartView()
                            .frame(height: 240)
                    }
                    
                    // 图例
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(typeStats.filter { 
                            $0.type != .unknown && 
                            $0.type != .optionClick && 
                            $0.type != .optionDoubleClick && 
                            $0.type != .optionLongPress 
                        }) { stat in
                            HStack {
                                Rectangle()
                                    .fill(getColorForType(stat.type))
                                    .frame(width: 16, height: 16)
                                    .cornerRadius(3)
                                
                                Text("\(stat.type.rawValue)")
                                    .font(.title3)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("\(stat.count) 次")
                                        .font(.headline)
                                    
                                    Text("(\(Int(stat.percentage))%)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.leading, 16)
                    .frame(minWidth: 200)
                }
                .padding()
                .background(Color(.windowBackgroundColor).opacity(0.3))
                .cornerRadius(10)
            } else {
                // 旧系统版本的替代视图
                legacyTypeStatsView
                    .padding()
                    .background(Color(.windowBackgroundColor).opacity(0.3))
                    .cornerRadius(10)
            }
        }
    }
    
    // 适配macOS 14的环形图视图
    @available(macOS 14.0, *)
    private func DonutChartView() -> some View {
        Chart {
            ForEach(typeStats.filter { 
                $0.type != .unknown && 
                $0.type != .optionClick && 
                $0.type != .optionDoubleClick && 
                $0.type != .optionLongPress 
            }) { stat in
                SectorMark(
                    angle: .value("使用次数", stat.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("类型", stat.type.rawValue))
                .cornerRadius(4)
            }
        }
        .chartForegroundStyleScale([
            "悬浮窗": Color.blue,
            "圆环": Color.pink,
            "快捷键": Color.green
        ])
    }
    
    // Option键使用方式的环形图 - macOS 14
    @available(macOS 14.0, *)
    private func OptionDonutChartView() -> some View {
        let filteredStats = optionUsageStats.filter { 
            $0.type == .optionClick || $0.type == .optionDoubleClick || $0.type == .optionLongPress 
        }
        
        if filteredStats.isEmpty {
            return AnyView(
                Text("暂无Option键使用数据")
                    .foregroundColor(.secondary)
                    .frame(height: 220)
            )
        }
        
        return AnyView(
            Chart {
                ForEach(filteredStats) { stat in
                    SectorMark(
                        angle: .value("使用次数", stat.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("类型", stat.type.rawValue))
                    .cornerRadius(4)
                }
            }
            .chartForegroundStyleScale([
                "Option单击": Color.orange,
                "Option双击": Color.purple,
                "Option长按": Color.cyan
            ])
        )
    }
    
    // 适配macOS 13的简单饼图视图
    @available(macOS 13.0, *)
    private func SimplePieChartView() -> some View {
        Chart {
            ForEach(typeStats.filter {
                $0.type != .unknown && 
                $0.type != .optionClick && 
                $0.type != .optionDoubleClick && 
                $0.type != .optionLongPress 
            }) { stat in
                // 在macOS 13中使用BarMark创建简单的饼图效果
                BarMark(
                    x: .value("类型", stat.type.rawValue),
                    y: .value("使用次数", stat.count)
                )
                .foregroundStyle(by: .value("类型", stat.type.rawValue))
            }
        }
        .chartForegroundStyleScale([
            "悬浮窗": Color.blue,
            "圆环": Color.pink,
            "快捷键": Color.green
        ])
    }
    
    // Option键使用方式的饼图 - macOS 13
    @available(macOS 13.0, *)
    private func OptionPieChartView() -> some View {
        let filteredStats = optionUsageStats.filter { 
            $0.type == .optionClick || $0.type == .optionDoubleClick || $0.type == .optionLongPress 
        }
        
        if filteredStats.isEmpty {
            return AnyView(
                Text("暂无Option键使用数据")
                    .foregroundColor(.secondary)
                    .frame(height: 220)
            )
        }
        
        return AnyView(
            Chart {
                ForEach(filteredStats) { stat in
                    BarMark(
                        x: .value("类型", stat.type.rawValue),
                        y: .value("使用次数", stat.count)
                    )
                    .foregroundStyle(by: .value("类型", stat.type.rawValue))
                }
            }
            .chartForegroundStyleScale([
                "Option单击": Color.orange,
                "Option双击": Color.purple,
                "Option长按": Color.cyan
            ])
        )
    }
    
    // 旧版macOS的Option键统计替代视图
    private var legacyOptionStatsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("统计数据需要 macOS 13 或更高版本查看图表")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            let filteredStats = optionUsageStats.filter { 
                $0.type == .optionClick || $0.type == .optionDoubleClick || $0.type == .optionLongPress 
            }
            
            if filteredStats.isEmpty {
                Text("暂无Option键使用数据")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(filteredStats) { stat in
                    HStack {
                        Rectangle()
                            .fill(getColorForType(stat.type))
                            .frame(width: 16, height: 16)
                            .cornerRadius(3)
                        
                        Text("\(stat.type.rawValue)")
                            .font(.title3)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(stat.count) 次")
                                .font(.headline)
                            
                            Text("(\(Int(stat.percentage))%)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
    
    // 旧版macOS的类型统计替代视图
    private var legacyTypeStatsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("统计数据需要 macOS 13 或更高版本查看图表")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            ForEach(typeStats.filter { $0.type != .unknown }) { stat in
                HStack {
                    Rectangle()
                        .fill(getColorForType(stat.type))
                        .frame(width: 16, height: 16)
                        .cornerRadius(3)
                    
                    Text("\(stat.type.rawValue)")
                        .font(.title3)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(stat.count) 次")
                            .font(.headline)
                        
                        Text("(\(Int(stat.percentage))%)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }
    
    // 使用趋势视图
    private var usageTrendView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("使用趋势")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 时间范围选择器
                Picker("时间范围", selection: $selectedTimeRange) {
                    Text("7天").tag(7)
                    Text("30天").tag(30)
                    Text("全部").tag(365)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .onChange(of: selectedTimeRange) { _ in
                    loadData()
                }
            }
            
            if #available(macOS 13.0, *) {
                // 类型选择器
                HStack {
                    Picker("显示类型", selection: $selectedUsageType) {
                        Text("总使用量").tag(nil as UsageType?)
                        Divider()
                        ForEach(UsageType.allCases.filter { $0 != .unknown }, id: \.self) { type in
                            HStack {
                                Rectangle()
                                    .fill(getColorForType(type))
                                    .frame(width: 10, height: 10)
                                    .cornerRadius(2)
                                
                                Text(type.rawValue)
                            }
                            .tag(type as UsageType?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                .padding(.top, 4)
                
                // 单一柱状图
                UnifiedTrendChartView(selectedType: selectedUsageType)
                    .frame(height: 250)
                    .padding()
                    .background(Color(.windowBackgroundColor).opacity(0.3))
                    .cornerRadius(10)
            } else {
                // 旧系统版本的替代视图
                legacyTrendView
                    .padding()
                    .background(Color(.windowBackgroundColor).opacity(0.3))
                    .cornerRadius(10)
            }
        }
    }
    
    // 统一的趋势图表 - 根据选择显示不同类型
    @available(macOS 13.0, *)
    private func UnifiedTrendChartView(selectedType: UsageType?) -> some View {
        Chart {
            ForEach(usageData) { item in
                if let type = selectedType {
                    // 显示特定类型的使用次数
                    BarMark(
                        x: .value("日期", formatDateForChart(item.date)),
                        y: .value("使用次数", item.countForType(type))
                    )
                    .foregroundStyle(getColorForType(type))
                    .cornerRadius(4)
                } else {
                    // 显示总使用次数
                    BarMark(
                        x: .value("日期", formatDateForChart(item.date)),
                        y: .value("使用次数", item.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            if selectedTimeRange > 30 {
                // 当选择"全部"时，减少显示的标签数量
                AxisMarks(values: .stride(by: .day, count: usageData.count > 60 ? 30 : 7)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatDateFromDate(date))
                        }
                    }
                }
            } else {
                // 常规日期显示
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let stringValue = value.as(String.self) {
                            Text(stringValue)
                                .font(.caption)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
            }
        }
    }
    
    // 旧版macOS的趋势图替代视图
    private var legacyTrendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("统计数据需要 macOS 13 或更高版本查看图表")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            List(usageData) { item in
                HStack {
                    Text(formatDate(item.date))
                        .font(.headline)
                    Spacer()
                    Text("\(item.count) 次")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .padding(.vertical, 2)
            }
            .frame(height: 180)
        }
    }
    
    // 获取类型对应的颜色
    private func getColorForType(_ type: UsageType) -> Color {
        switch type {
        case .floatingWindow: return .blue
        case .circleRing: return .pink
        case .shortcut: return .green
        case .optionClick: return .orange
        case .optionDoubleClick: return .purple
        case .optionLongPress: return .cyan
        case .unknown: return .gray
        }
    }
    
    // 加载数据
    private func loadData() {
        // 加载使用记录
        usageData = UsageStatsManager.shared.getRecentUsage(days: selectedTimeRange)
        
        // 获取按类型分组的统计
        typeStats = UsageStatsManager.shared.getUsageByType(days: selectedTimeRange)
        
        // 获取Option键使用统计（需要手动过滤）
        optionUsageStats = typeStats.filter { 
            $0.type == .optionClick || $0.type == .optionDoubleClick || $0.type == .optionLongPress 
        }
        
        // 更新总使用次数
        totalUsage = UsageStatsManager.shared.getTotalUsageCount()
    }
    
    // 格式化日期
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MM月dd日"
            return formatter.string(from: date)
        }
        return dateString
    }
    
    // 格式化短日期
    private func formatDateShort(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
        return dateString
    }
    
    // 格式化日期，专门用于图表
    private func formatDateForChart(_ dateString: String) -> String {
        if selectedTimeRange > 30 {
            // 对于大量数据，使用年月格式
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            if let date = formatter.date(from: dateString) {
                formatter.dateFormat = "yyyy/MM"
                return formatter.string(from: date)
            }
            return dateString
        } else {
            // 对于较少数据，使用月/日格式
            return formatDateShort(dateString)
        }
    }
    
    // 从Date对象格式化日期
    private func formatDateFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if selectedTimeRange > 30 {
            formatter.dateFormat = "yyyy/MM"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }
    
    // 确认清除统计数据
    private func confirmClearStats() {
        let alert = NSAlert()
        alert.messageText = "确认清除"
        alert.informativeText = "确定要清除所有使用统计数据吗？此操作不可恢复。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "取消")
        alert.addButton(withTitle: "清除")
        
        if alert.runModal() == .alertSecondButtonReturn {
            UsageStatsManager.shared.clearAllStats()
            loadData()
        }
    }
}

struct UsageStatsView_Previews: PreviewProvider {
    static var previews: some View {
        UsageStatsView()
            .frame(width: 500, height: 600)
    }
} 