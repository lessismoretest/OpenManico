import Foundation

// 使用类型枚举
enum UsageType: String, Codable, CaseIterable {
    case floatingWindow = "悬浮窗"
    case circleRing = "圆环"
    case shortcut = "快捷键"
    case optionClick = "Option单击"
    case optionDoubleClick = "Option双击"
    case optionLongPress = "Option长按"
    case unknown = "未知"
    
    var color: String {
        switch self {
        case .floatingWindow: return "blue"
        case .circleRing: return "pink"
        case .shortcut: return "green"
        case .optionClick: return "orange"
        case .optionDoubleClick: return "purple"
        case .optionLongPress: return "cyan"
        case .unknown: return "gray"
        }
    }
}

// 使用日期作为键的使用量记录结构
struct DailyUsage: Codable, Identifiable, Hashable {
    var id: String { date }
    var date: String // 格式 yyyy-MM-dd
    var count: Int
    var typeData: [String: Int] = [:] // 按类型统计的使用次数
    
    static func from(date: Date, count: Int) -> DailyUsage {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return DailyUsage(date: formatter.string(from: date), count: count)
    }
    
    func dateValue() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
    
    // 获取指定类型的使用次数
    func countForType(_ type: UsageType) -> Int {
        return typeData[type.rawValue] ?? 0
    }
}

// 使用类型统计结构
struct UsageTypeStats: Identifiable {
    var id: String { type.rawValue }
    var type: UsageType
    var count: Int
    var percentage: Double
}

// 使用统计管理类
class UsageStatsManager {
    static let shared = UsageStatsManager()
    
    private let dailyUsageKey = "DailyUsageStats"
    private var dailyUsage: [DailyUsage] = []
    
    private init() {
        loadUsageStats()
    }
    
    // 加载使用统计数据
    private func loadUsageStats() {
        if let data = UserDefaults.standard.data(forKey: dailyUsageKey),
           let loadedStats = try? JSONDecoder().decode([DailyUsage].self, from: data) {
            self.dailyUsage = loadedStats
            print("[UsageStatsManager] 已加载 \(loadedStats.count) 条使用记录")
        } else {
            self.dailyUsage = []
            print("[UsageStatsManager] 没有找到使用记录，初始化为空数组")
        }
    }
    
    // 保存使用统计数据
    private func saveUsageStats() {
        if let data = try? JSONEncoder().encode(dailyUsage) {
            UserDefaults.standard.set(data, forKey: dailyUsageKey)
            print("[UsageStatsManager] 已保存 \(dailyUsage.count) 条使用记录")
        }
    }
    
    // 记录今天的使用，带类型
    func recordUsage(type: UsageType = .unknown) {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        
        if let index = dailyUsage.firstIndex(where: { $0.date == todayString }) {
            // 更新今天的记录
            dailyUsage[index].count += 1
            
            // 更新类型计数
            let typeKey = type.rawValue
            var typeData = dailyUsage[index].typeData
            typeData[typeKey] = (typeData[typeKey] ?? 0) + 1
            dailyUsage[index].typeData = typeData
        } else {
            // 添加今天的新记录
            var newUsage = DailyUsage(date: todayString, count: 1)
            newUsage.typeData[type.rawValue] = 1
            dailyUsage.append(newUsage)
        }
        
        // 保存更新后的记录
        saveUsageStats()
    }
    
    // 获取最近n天的使用记录
    func getRecentUsage(days: Int) -> [DailyUsage] {
        // 确保有足够的记录
        ensureRecentDaysExist(days: days)
        
        // 获取排序后的最近记录
        return getSortedUsage().prefix(days).reversed().map { $0 }
    }
    
    // 确保最近n天的记录都存在（如果不存在则创建空记录）
    private func ensureRecentDaysExist(days: Int) {
        let calendar = Calendar.current
        let today = Date()
        
        // 为每一天创建一个日期字符串
        var existingDates = Set(dailyUsage.map { $0.date })
        
        for day in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateString = formatter.string(from: date)
                
                if !existingDates.contains(dateString) {
                    // 为不存在的日期创建记录（使用量为0）
                    dailyUsage.append(DailyUsage(date: dateString, count: 0))
                    existingDates.insert(dateString)
                }
            }
        }
        
        // 不需要保存，因为这些是临时的零记录
    }
    
    // 获取按日期排序的使用记录
    private func getSortedUsage() -> [DailyUsage] {
        return dailyUsage.sorted { (a, b) -> Bool in
            guard let dateA = a.dateValue(), let dateB = b.dateValue() else {
                return false
            }
            return dateA > dateB
        }
    }
    
    // 获取按类型分组的使用统计
    func getUsageByType(days: Int = 0) -> [UsageTypeStats] {
        var filteredUsage = dailyUsage
        
        if days > 0 {
            // 选择最近n天的数据
            filteredUsage = getRecentUsage(days: days)
        }
        
        // 按类型统计使用次数
        var typeCount: [UsageType: Int] = [:]
        var totalCount = 0
        
        for usage in filteredUsage {
            for (typeStr, count) in usage.typeData {
                if let type = UsageType(rawValue: typeStr) {
                    typeCount[type, default: 0] += count
                    totalCount += count
                }
            }
        }
        
        // 如果所有类型数据为0，但总使用次数不为0
        // 说明是旧数据，将所有使用次数归为未知类型
        if typeCount.values.reduce(0, +) == 0 && totalCount == 0 {
            let oldTotalCount = filteredUsage.reduce(0) { $0 + $1.count }
            if oldTotalCount > 0 {
                typeCount[.unknown] = oldTotalCount
                totalCount = oldTotalCount
            }
        }
        
        // 计算每种类型的百分比
        return UsageType.allCases.map { type in
            let count = typeCount[type] ?? 0
            let percentage = totalCount > 0 ? Double(count) / Double(totalCount) * 100.0 : 0.0
            return UsageTypeStats(type: type, count: count, percentage: percentage)
        }.filter { $0.count > 0 }  // 只返回有数据的类型
    }
    
    // 获取总使用次数
    func getTotalUsageCount() -> Int {
        return dailyUsage.reduce(0) { $0 + $1.count }
    }
    
    // 清除所有使用记录
    func clearAllStats() {
        dailyUsage.removeAll()
        saveUsageStats()
    }
} 