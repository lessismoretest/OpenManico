import SwiftUI
import Charts

struct UsageChartView: View {
    @State private var usageData: [DailyUsage] = []
    @State private var selectedDays: Int = 7
    private let availableDays = [7, 14, 30]
    
    var body: some View {
        VStack {
            Picker("显示天数", selection: $selectedDays) {
                ForEach(availableDays, id: \.self) { days in
                    Text("\(days)天").tag(days)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedDays) { _ in
                loadData()
            }
            
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(usageData) { item in
                        BarMark(
                            x: .value("日期", formatDateShort(item.date)),
                            y: .value("使用次数", item.count)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
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
                .frame(height: 200)
                .padding()
            } else {
                // 对于不支持 Charts 框架的旧版 macOS
                fallbackChartView()
            }
            
            HStack {
                Text("总计使用次数: \(getTotalUsage())")
                    .font(.caption)
                
                Spacer()
                
                Button("清除统计数据") {
                    confirmClearStats()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            loadData()
        }
    }
    
    // 为旧版 macOS 提供的简单替代视图
    private func fallbackChartView() -> some View {
        VStack(alignment: .leading) {
            Text("请升级到 macOS 13 或更高版本以查看图表")
                .foregroundColor(.secondary)
                .padding()
            
            // 提供一个简单的列表视图作为替代
            List(usageData) { item in
                HStack {
                    Text(formatDate(item.date))
                    Spacer()
                    Text("\(item.count) 次")
                        .foregroundColor(.blue)
                }
            }
            .frame(height: 200)
        }
    }
    
    private func loadData() {
        usageData = UsageStatsManager.shared.getRecentUsage(days: selectedDays)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MM月dd日"
            return formatter.string(from: date)
        }
        return dateString
    }
    
    private func formatDateShort(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
        return dateString
    }
    
    private func getTotalUsage() -> Int {
        return usageData.reduce(0) { $0 + $1.count }
    }
    
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

struct UsageChartView_Previews: PreviewProvider {
    static var previews: some View {
        UsageChartView()
            .frame(width: 500, height: 300)
    }
} 