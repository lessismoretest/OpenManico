import Foundation

// 使用日期作为键的使用量记录结构
struct DailyUsage: Codable, Identifiable, Hashable {
    var id: String { date }
    var date: String // 格式 yyyy-MM-dd
    var count: Int
    
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
    
    // 记录今天的使用
    func recordUsage() {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        
        if let index = dailyUsage.firstIndex(where: { $0.date == todayString }) {
            // 更新今天的记录
            dailyUsage[index].count += 1
        } else {
            // 添加今天的新记录
            dailyUsage.append(DailyUsage(date: todayString, count: 1))
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
    
    // 清除所有使用记录
    func clearAllStats() {
        dailyUsage.removeAll()
        saveUsageStats()
    }
} 