//
//  TestDataGeneratorView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/17.
//

#if DEBUG

import SwiftUI
import SwiftData

// MARK: - 配置类型

/// 数据条数预设选项
enum TestDataCount: Int, CaseIterable, Identifiable {
    case ten = 10
    case fifty = 50
    case hundred = 100
    case threeHundred = 300
    case fiveHundred = 500
    case thousand = 1000

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue) 条"
    }
}

/// 时间跨度预设选项
enum TestDataTimeSpan: Int, CaseIterable, Identifiable {
    case oneWeek = 7
    case oneMonth = 30
    case threeMonths = 90
    case sixMonths = 180
    case oneYear = 365
    case twoYears = 730

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .oneWeek:      return "最近 1 周"
        case .oneMonth:     return "最近 1 个月"
        case .threeMonths:  return "最近 3 个月"
        case .sixMonths:    return "最近 6 个月"
        case .oneYear:      return "最近 1 年"
        case .twoYears:     return "最近 2 年"
        }
    }
}

// MARK: - 测试数据生成页面

/// 测试数据生成器（仅 DEBUG 可用）
struct TestDataGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(filter: #Predicate<GlucoseRecord> { $0.source == "test_data" })
    private var existingTestGlucoseRecords: [GlucoseRecord]
    @Query(filter: #Predicate<MedicationRecord> { $0.note == "test_data" })
    private var existingTestMedicationRecords: [MedicationRecord]
    @Query(filter: #Predicate<MealRecord> { $0.note == "test_data" })
    private var existingTestMealRecords: [MealRecord]

    @State private var selectedCount: TestDataCount = .hundred
    @State private var selectedTimeSpan: TestDataTimeSpan = .threeMonths
    @State private var isGenerating = false
    @State private var generationComplete = false
    @State private var generatedGlucoseCount = 0
    @State private var generatedMedicationCount = 0
    @State private var generatedMealCount = 0
    @State private var showDeleteConfirm = false
    
    private var totalExistingTestRecords: Int {
        existingTestGlucoseRecords.count + existingTestMedicationRecords.count + existingTestMealRecords.count
    }

    /// 平均每日记录数
    private var averagePerDay: Double {
        Double(selectedCount.rawValue) / Double(selectedTimeSpan.rawValue)
    }

    /// 时间范围描述
    private var timeRangeDescription: String {
        let calendar = Calendar.current
        let endDate = Date.now
        guard let startDate = calendar.date(byAdding: .day, value: -selectedTimeSpan.rawValue, to: endDate) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return "\(formatter.string(from: startDate)) — \(formatter.string(from: endDate))"
    }

    var body: some View {
        NavigationStack {
            Form {
                warningSection
                parametersSection
                previewSection
                generateButtonSection
                deleteSection
                subscriptionSimulationSection
            }
            .navigationTitle("测试数据生成器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .confirmationDialog(
                "确认清除测试数据？",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("清除 \(totalExistingTestRecords) 条测试数据", role: .destructive) {
                    deleteTestData()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("此操作将删除所有通过测试工具生成的数据（血糖、用药、饮食记录），不可恢复。")
            }
        }
    }
    
    // MARK: - View Components
    
    private var warningSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("开发者测试工具")
                        .font(.subheadline.weight(.semibold))
                    Text("生成的数据仅用于开发调试，可随时清除")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var parametersSection: some View {
        Section("生成参数") {
            Picker("数据条数", selection: $selectedCount) {
                ForEach(TestDataCount.allCases) { count in
                    Text(count.displayName).tag(count)
                }
            }

            Picker("时间跨度", selection: $selectedTimeSpan) {
                ForEach(TestDataTimeSpan.allCases) { span in
                    Text(span.displayName).tag(span)
                }
            }
        }
    }
    
    private var previewSection: some View {
        Section {
            HStack {
                Text("血糖记录")
                Spacer()
                Text("\(selectedCount.rawValue) 条")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("用药记录")
                Spacer()
                Text("约 \(medicationCount) 条")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("饮食记录")
                Spacer()
                Text("约 \(mealCount) 条")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("时间范围")
                Spacer()
                Text(timeRangeDescription)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            HStack {
                Text("数据来源标记")
                Spacer()
                Text("test_data")
                    .font(.caption.monospaced())
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
            }
        } header: {
            Text("数据预览")
        } footer: {
            Text("最近30天保证每天包含所有场景标签，超过30天随机分布")
                .font(.caption2)
        }
    }
    
    private var medicationCount: Int {
        Int(Double(selectedCount.rawValue) * 0.6)
    }
    
    private var mealCount: Int {
        Int(Double(selectedCount.rawValue) * 0.4)
    }
    
    private var totalGeneratedCount: Int {
        generatedGlucoseCount + generatedMedicationCount + generatedMealCount
    }
    
    private var generateButtonSection: some View {
        Section {
            Button {
                generateTestData()
            } label: {
                HStack {
                    Spacer()
                    if isGenerating {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("正在生成...")
                    } else if generationComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("已生成 \(totalGeneratedCount) 条记录")
                    } else {
                        Image(systemName: "wand.and.stars")
                        Text("生成测试数据")
                    }
                    Spacer()
                }
                .font(.headline)
                .foregroundColor(isGenerating ? .secondary : .white)
                .padding(.vertical, 8)
            }
            .listRowBackground(buttonBackgroundColor)
            .disabled(isGenerating)
        }
    }
    
    private var buttonBackgroundColor: Color {
        if isGenerating {
            return Color(.systemGray4)
        } else if generationComplete {
            return Color.green
        } else {
            return Color.brandPrimary
        }
    }
    
    @ViewBuilder
    private var deleteSection: some View {
        if totalExistingTestRecords > 0 || deleteComplete {
            Section {
                if deleteComplete {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("已清除 \(deletedCount) 条测试数据")
                        Spacer()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
                    .padding(.vertical, 4)
                } else {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            if isDeleting {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("正在清除...")
                            } else {
                                Image(systemName: "trash")
                                Text("清除测试数据（\(totalExistingTestRecords) 条）")
                            }
                            Spacer()
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(.vertical, 4)
                    }
                    .disabled(isDeleting)
                }
            } footer: {
                if !deleteComplete {
                    Text("将删除所有测试数据：\(existingTestGlucoseRecords.count)条血糖、\(existingTestMedicationRecords.count)条用药、\(existingTestMealRecords.count)条饮食记录。删除后将自动同步到 iCloud。")
                        .font(.caption2)
                } else {
                    Text("删除操作已保存，iCloud 将自动同步删除。")
                        .font(.caption2)
                }
            }
        }
    }

    // MARK: - 订阅模拟
    
    private var subscriptionSimulationSection: some View {
        Section {
            HStack {
                Text("当前订阅")
                Spacer()
                if subscriptionManager.isPremiumUser {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(subscriptionManager.subscriptionType?.localizedName ?? "未知")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                } else {
                    Text("免费用户")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let expiry = subscriptionManager.expiryDate {
                HStack {
                    Text("到期时间")
                    Spacer()
                    Text(expiry.formatted(.dateTime.year().month().day()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                simulateSubscription(.monthly)
            } label: {
                Label("开通月度订阅", systemImage: "calendar")
            }
            
            Button {
                simulateSubscription(.quarterly)
            } label: {
                Label("开通季度订阅", systemImage: "calendar.badge.clock")
            }
            
            Button {
                simulateSubscription(.yearly)
            } label: {
                Label("开通年度订阅", systemImage: "star.fill")
            }
            
            Button {
                simulateSubscription(.lifetime)
            } label: {
                Label("开通终身买断", systemImage: "crown.fill")
            }
            
            Button {
                simulateExpiredSubscription()
            } label: {
                Label("模拟订阅过期", systemImage: "clock.badge.xmark")
                    .foregroundStyle(.orange)
            }
            
            Button(role: .destructive) {
                subscriptionManager.clearSubscriptionStatus()
            } label: {
                Label("重置为免费用户", systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text("订阅模拟")
        } footer: {
            Text("模拟不同订阅状态，用于测试付费墙、功能锁和订阅卡片的展示效果")
                .font(.caption2)
        }
    }
    
    private func simulateSubscription(_ type: SubscriptionType) {
        subscriptionManager.isPremiumUser = true
        subscriptionManager.subscriptionType = type
        
        switch type {
        case .monthly:
            subscriptionManager.setExpiryDate(Calendar.current.date(byAdding: .month, value: 1, to: .now))
        case .quarterly:
            subscriptionManager.setExpiryDate(Calendar.current.date(byAdding: .month, value: 3, to: .now))
        case .yearly:
            subscriptionManager.setExpiryDate(Calendar.current.date(byAdding: .year, value: 1, to: .now))
        case .lifetime:
            subscriptionManager.setExpiryDate(nil)
        }
        
        subscriptionManager.recordFirstPurchase()
    }
    
    private func simulateExpiredSubscription() {
        subscriptionManager.isPremiumUser = false
        subscriptionManager.subscriptionType = .monthly
        subscriptionManager.setExpiryDate(Calendar.current.date(byAdding: .day, value: -1, to: .now))
    }

    // MARK: - 数据生成

    private func generateTestData() {
        isGenerating = true
        generationComplete = false

        let count = selectedCount.rawValue
        let days = selectedTimeSpan.rawValue
        
        let result = TestDataGenerator.generateAll(glucoseCount: count, days: days)

        for record in result.glucoseRecords {
            modelContext.insert(record)
        }
        for record in result.medicationRecords {
            modelContext.insert(record)
        }
        for record in result.mealRecords {
            modelContext.insert(record)
        }

        generatedGlucoseCount = result.glucoseRecords.count
        generatedMedicationCount = result.medicationRecords.count
        generatedMealCount = result.mealRecords.count
        isGenerating = false
        generationComplete = true
    }

    // MARK: - 数据清除

    @State private var isDeleting = false
    @State private var deleteComplete = false
    @State private var deletedCount = 0

    private func deleteTestData() {
        isDeleting = true
        deleteComplete = false
        
        do {
            let glucoseDescriptor = FetchDescriptor<GlucoseRecord>(
                predicate: #Predicate { $0.source == "test_data" }
            )
            let glucoseRecords = try modelContext.fetch(glucoseDescriptor)
            
            let medicationDescriptor = FetchDescriptor<MedicationRecord>(
                predicate: #Predicate { $0.note == "test_data" }
            )
            let medicationRecords = try modelContext.fetch(medicationDescriptor)
            
            let mealDescriptor = FetchDescriptor<MealRecord>(
                predicate: #Predicate { $0.note == "test_data" }
            )
            let mealRecords = try modelContext.fetch(mealDescriptor)
            
            let total = glucoseRecords.count + medicationRecords.count + mealRecords.count
            
            for record in glucoseRecords {
                modelContext.delete(record)
            }
            for record in medicationRecords {
                modelContext.delete(record)
            }
            for record in mealRecords {
                modelContext.delete(record)
            }
            
            try modelContext.save()
            deletedCount = total
            deleteComplete = true
            
            #if DEBUG
            print("✅ 已删除 \(total) 条测试数据（血糖:\(glucoseRecords.count) 用药:\(medicationRecords.count) 饮食:\(mealRecords.count)），等待 iCloud 自动同步删除")
            #endif
        } catch {
            #if DEBUG
            print("❌ 删除测试数据失败: \(error)")
            #endif
        }
        
        isDeleting = false
        generationComplete = false
        generatedGlucoseCount = 0
        generatedMedicationCount = 0
        generatedMealCount = 0
    }
}

// MARK: - 测试数据生成引擎

enum TestDataGenerator {
    
    // MARK: - 返回结果结构
    
    struct GeneratedData {
        let glucoseRecords: [GlucoseRecord]
        let medicationRecords: [MedicationRecord]
        let mealRecords: [MealRecord]
    }

    // MARK: - 每日时间段与场景标签映射
    
    /// 所有内置场景标签（确保覆盖所有9个）
    private static let allMealContexts: [MealContext] = [
        .beforeBreakfast,
        .afterBreakfast,
        .beforeLunch,
        .afterLunch,
        .beforeDinner,
        .afterDinner,
        .fasting,
        .bedtime,
        .other
    ]

    /// 一天中的测试时间段定义
    private struct DaySlot {
        let hourRange: ClosedRange<Int>
        let minuteRange: ClosedRange<Int>
        let sceneTagId: String
        let weight: Double
    }

    /// 模拟真实作息的时间段（用于超过30天的随机分布）
    private static let daySlots: [DaySlot] = [
        DaySlot(hourRange: 6...7,   minuteRange: 0...59,  sceneTagId: MealContext.fasting.rawValue,         weight: 1.5),
        DaySlot(hourRange: 7...8,   minuteRange: 0...59,  sceneTagId: MealContext.beforeBreakfast.rawValue,  weight: 2.0),
        DaySlot(hourRange: 9...10,  minuteRange: 0...59,  sceneTagId: MealContext.afterBreakfast.rawValue,   weight: 2.0),
        DaySlot(hourRange: 11...12, minuteRange: 0...30,  sceneTagId: MealContext.beforeLunch.rawValue,      weight: 1.5),
        DaySlot(hourRange: 13...14, minuteRange: 0...59,  sceneTagId: MealContext.afterLunch.rawValue,       weight: 2.0),
        DaySlot(hourRange: 17...18, minuteRange: 0...59,  sceneTagId: MealContext.beforeDinner.rawValue,     weight: 1.5),
        DaySlot(hourRange: 19...20, minuteRange: 0...59,  sceneTagId: MealContext.afterDinner.rawValue,      weight: 2.0),
        DaySlot(hourRange: 21...22, minuteRange: 0...30,  sceneTagId: MealContext.bedtime.rawValue,          weight: 1.0),
    ]
    
    /// 场景标签到时间段的映射
    private static func timeSlot(for context: MealContext) -> (hour: ClosedRange<Int>, minute: ClosedRange<Int>) {
        switch context {
        case .fasting:          return (6...7, 0...59)
        case .beforeBreakfast:  return (7...8, 0...59)
        case .afterBreakfast:   return (9...10, 0...59)
        case .beforeLunch:      return (11...12, 0...30)
        case .afterLunch:       return (13...14, 0...59)
        case .beforeDinner:     return (17...18, 0...59)
        case .afterDinner:      return (19...20, 0...59)
        case .bedtime:          return (21...22, 0...30)
        case .other:            return (14...17, 0...59)
        }
    }

    // MARK: - 血糖值参数（mmol/L）

    private struct GlucoseParams {
        let mean: Double
        let stdDev: Double
        let min: Double
        let max: Double
    }

    /// 不同场景的血糖参数
    private static func glucoseParams(for sceneTagId: String) -> GlucoseParams {
        guard let context = MealContext(rawValue: sceneTagId) else {
            return GlucoseParams(mean: 6.0, stdDev: 1.0, min: 2.8, max: 20.0)
        }
        switch context.thresholdGroup {
        case .fasting:
            return GlucoseParams(mean: 5.5, stdDev: 0.8, min: 2.8, max: 15.0)
        case .postprandial:
            return GlucoseParams(mean: 7.5, stdDev: 1.5, min: 3.5, max: 20.0)
        case .bedtime:
            return GlucoseParams(mean: 6.2, stdDev: 1.0, min: 3.0, max: 14.0)
        }
    }

    // MARK: - 备注标签（来自 UserSettings）

    private static let annotationNotes: [String] = [
        "运动后", "压力大", "生病", "旅行", "加餐", "饮酒"
    ]
    
    // MARK: - 用药相关配置
    
    private struct MedicationConfig {
        let type: MedicationType
        let weight: Double
        let names: [String]
        let dosageRange: ClosedRange<Double>
        let timeOffsets: [Int] // 相对于餐时的分钟偏移
    }
    
    private static let medicationConfigs: [MedicationConfig] = [
        MedicationConfig(
            type: .rapidInsulin,
            weight: 0.4,
            names: ["诺和锐", "优泌乐", "门冬胰岛素"],
            dosageRange: 4...12,
            timeOffsets: [-30, -20, -15] // 餐前注射
        ),
        MedicationConfig(
            type: .longInsulin,
            weight: 0.3,
            names: ["来得时", "诺和达", "地特胰岛素"],
            dosageRange: 10...24,
            timeOffsets: [0] // 晚餐时或睡前
        ),
        MedicationConfig(
            type: .oralMedicine,
            weight: 0.25,
            names: ["二甲双胍", "格列美脲", "阿卡波糖"],
            dosageRange: 500...2000,
            timeOffsets: [-5, 0, 5] // 餐时服用
        ),
        MedicationConfig(
            type: .other,
            weight: 0.05,
            names: ["其他药物"],
            dosageRange: 1...10,
            timeOffsets: [0]
        )
    ]
    
    // MARK: - 饮食相关配置
    
    private static let mealDescriptions: [String] = [
        "全麦面包 + 鸡蛋 + 牛奶",
        "鸡胸肉沙拉 + 橄榄油",
        "米饭 + 青菜炒肉",
        "糙米饭 + 蒸鱼 + 蔬菜",
        "红烧肉 + 米饭",
        "水煮鸡胸肉 + 西兰花",
        "全麦三明治 + 生菜",
        "燕麦粥 + 水果",
        "炒青菜 + 豆腐",
        "牛排 + 土豆泥",
        "蔬菜沙拉 + 鸡蛋",
        "鱼肉 + 米饭",
        "火锅（清汤）",
        "麻辣烫（少油）",
        "日式便当",
        "意大利面",
        "煎饼果子",
        "水果拼盘",
        "坚果 + 酸奶",
        "紫薯 + 鸡蛋",
        "玉米 + 鸡胸肉",
        "素炒三鲜",
        "番茄炒蛋 + 米饭",
        "手抓饼 + 豆浆"
    ]
    
    private static let carbLevelWeights: [(CarbLevel, Double)] = [
        (.low, 0.3),
        (.medium, 0.5),
        (.high, 0.2)
    ]

    // MARK: - 公开生成接口

    /// 生成所有类型的测试数据
    /// - Parameters:
    ///   - glucoseCount: 血糖记录总条数
    ///   - days: 时间跨度（天）
    /// - Returns: 包含所有记录的结构
    static func generateAll(glucoseCount: Int, days: Int) -> GeneratedData {
        let glucoseRecords = generateGlucoseRecords(count: glucoseCount, days: days)
        let medicationRecords = generateMedicationRecords(days: days, basedOnGlucoseCount: glucoseCount)
        let mealRecords = generateMealRecords(days: days, basedOnGlucoseCount: glucoseCount)
        
        return GeneratedData(
            glucoseRecords: glucoseRecords,
            medicationRecords: medicationRecords,
            mealRecords: mealRecords
        )
    }
    
    // MARK: - 血糖记录生成
    
    private static func generateGlucoseRecords(count: Int, days: Int) -> [GlucoseRecord] {
        let calendar = Calendar.current
        let now = Date.now
        var records: [GlucoseRecord] = []
        
        // 拆分：最近30天 vs 超过30天
        let recentDays = min(days, 30)
        let olderDays = max(0, days - 30)
        
        // 1. 最近30天：保证每天所有标签
        if recentDays > 0 {
            let recentRecords = generateRecentMonthRecords(days: recentDays, now: now, calendar: calendar)
            records.append(contentsOf: recentRecords)
        }
        
        // 2. 超过30天：稀疏随机分布
        if olderDays > 0 {
            let remainingCount = max(0, count - records.count)
            let olderRecords = generateOlderRecords(
                count: remainingCount,
                days: olderDays,
                startDayOffset: recentDays,
                now: now,
                calendar: calendar
            )
            records.append(contentsOf: olderRecords)
        }
        
        return records
    }
    
    /// 生成最近30天的记录（每天保证所有标签）
    private static func generateRecentMonthRecords(days: Int, now: Date, calendar: Calendar) -> [GlucoseRecord] {
        var records: [GlucoseRecord] = []
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            // 为每个场景标签生成一条记录
            for context in allMealContexts {
                let timeSlot = timeSlot(for: context)
                let hour = Int.random(in: timeSlot.hour)
                let minute = Int.random(in: timeSlot.minute)
                
                guard let timestamp = calendar.date(
                    bySettingHour: hour, minute: minute, second: Int.random(in: 0...59),
                    of: date
                ) else { continue }
                
                guard timestamp <= now else { continue }
                
                let params = glucoseParams(for: context.rawValue)
                let value = clampedGaussian(mean: params.mean, stdDev: params.stdDev, min: params.min, max: params.max)
                
                // 20%概率添加备注标签
                let note: String? = Double.random(in: 0...1) < 0.2 ? annotationNotes.randomElement() : nil
                
                let record = GlucoseRecord(
                    value: round(value * 10) / 10,
                    timestamp: timestamp,
                    sceneTagId: context.rawValue,
                    note: note,
                    source: "test_data"
                )
                records.append(record)
            }
        }
        
        return records
    }
    
    /// 生成超过30天的记录（稀疏随机分布）
    private static func generateOlderRecords(
        count: Int,
        days: Int,
        startDayOffset: Int,
        now: Date,
        calendar: Calendar
    ) -> [GlucoseRecord] {
        var records: [GlucoseRecord] = []
        
        let dailyCounts = distributeCounts(total: count, days: days)
        
        for dayIndex in 0..<days {
            let dayOffset = startDayOffset + dayIndex
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dailyCount = dailyCounts[dayIndex]
            if dailyCount == 0 { continue }
            
            let selectedSlots = pickSlots(count: dailyCount)
            
            for slot in selectedSlots {
                let hour = Int.random(in: slot.hourRange)
                let minute = Int.random(in: slot.minuteRange)
                
                guard let timestamp = calendar.date(
                    bySettingHour: hour, minute: minute, second: Int.random(in: 0...59),
                    of: date
                ) else { continue }
                
                guard timestamp <= now else { continue }
                
                let params = glucoseParams(for: slot.sceneTagId)
                let value = clampedGaussian(mean: params.mean, stdDev: params.stdDev, min: params.min, max: params.max)
                
                // 20%概率添加备注标签
                let note: String? = Double.random(in: 0...1) < 0.2 ? annotationNotes.randomElement() : nil
                
                let record = GlucoseRecord(
                    value: round(value * 10) / 10,
                    timestamp: timestamp,
                    sceneTagId: slot.sceneTagId,
                    note: note,
                    source: "test_data"
                )
                records.append(record)
            }
        }
        
        return records
    }
    
    // MARK: - 用药记录生成
    
    private static func generateMedicationRecords(days: Int, basedOnGlucoseCount: Int) -> [MedicationRecord] {
        let calendar = Calendar.current
        let now = Date.now
        var records: [MedicationRecord] = []
        
        // 用药记录约为血糖记录的60%
        let targetCount = Int(Double(basedOnGlucoseCount) * 0.6)
        let perDay = max(1, targetCount / days)
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            // 每天1-3次用药
            let dailyCount = min(perDay, Int.random(in: 1...3))
            
            for _ in 0..<dailyCount {
                let config = pickMedicationConfig()
                let name = config.names.randomElement() ?? config.names[0]
                let dosage = Double.random(in: config.dosageRange)
                
                // 根据类型选择合适的时间
                let hour: Int
                let minute: Int
                if config.type == .longInsulin {
                    // 长效：晚上固定时间
                    hour = Int.random(in: 20...22)
                    minute = Int.random(in: 0...59)
                } else {
                    // 其他：三餐时间±偏移
                    let mealHours = [7, 12, 18] // 早中晚
                    let mealHour = mealHours.randomElement() ?? 12
                    let offset = config.timeOffsets.randomElement() ?? 0
                    hour = mealHour
                    minute = max(0, min(59, 30 + offset))
                }
                
                guard let timestamp = calendar.date(
                    bySettingHour: hour, minute: minute, second: Int.random(in: 0...59),
                    of: date
                ) else { continue }
                
                guard timestamp <= now else { continue }
                
                let record = MedicationRecord(
                    medicationType: config.type,
                    name: name,
                    dosage: round(dosage * 10) / 10,
                    timestamp: timestamp,
                    note: "test_data" // 使用note字段标记测试数据
                )
                records.append(record)
            }
        }
        
        return records
    }
    
    private static func pickMedicationConfig() -> MedicationConfig {
        let totalWeight = medicationConfigs.reduce(0.0) { $0 + $1.weight }
        var random = Double.random(in: 0..<totalWeight)
        
        for config in medicationConfigs {
            random -= config.weight
            if random <= 0 {
                return config
            }
        }
        
        return medicationConfigs[0]
    }
    
    // MARK: - 饮食记录生成
    
    private static func generateMealRecords(days: Int, basedOnGlucoseCount: Int) -> [MealRecord] {
        let calendar = Calendar.current
        let now = Date.now
        var records: [MealRecord] = []
        
        // 饮食记录约为血糖记录的40%
        let targetCount = Int(Double(basedOnGlucoseCount) * 0.4)
        let perDay = max(1, targetCount / days)
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            // 每天1-2次饮食记录
            let dailyCount = min(perDay, Int.random(in: 1...2))
            
            for _ in 0..<dailyCount {
                // 三餐时间±1小时
                let mealHours = [7, 12, 18]
                let baseHour = mealHours.randomElement() ?? 12
                let hour = max(0, min(23, baseHour + Int.random(in: -1...1)))
                let minute = Int.random(in: 0...59)
                
                guard let timestamp = calendar.date(
                    bySettingHour: hour, minute: minute, second: Int.random(in: 0...59),
                    of: date
                ) else { continue }
                
                guard timestamp <= now else { continue }
                
                let carbLevel = pickCarbLevel()
                let description = mealDescriptions.randomElement() ?? "饮食"
                
                let record = MealRecord(
                    carbLevel: carbLevel,
                    mealDescription: description,
                    timestamp: timestamp,
                    note: "test_data"
                )
                records.append(record)
            }
        }
        
        return records
    }
    
    private static func pickCarbLevel() -> CarbLevel {
        let totalWeight = carbLevelWeights.reduce(0.0) { $0 + $1.1 }
        var random = Double.random(in: 0..<totalWeight)
        
        for (level, weight) in carbLevelWeights {
            random -= weight
            if random <= 0 {
                return level
            }
        }
        
        return .medium
    }

    // MARK: - 辅助方法

    /// 将总条数按天分配（模拟真实的每日记录波动）
    private static func distributeCounts(total: Int, days: Int) -> [Int] {
        guard days > 0, total > 0 else { return Array(repeating: 0, count: max(days, 0)) }

        var counts = Array(repeating: 0, count: days)
        var remaining = total

        let basePerDay = max(1, total / days)

        for i in 0..<days {
            if remaining <= 0 { break }

            // 10% 概率跳过某天
            if Double.random(in: 0...1) < 0.1 && remaining > basePerDay * 2 {
                counts[i] = 0
                continue
            }

            let variation = Int.random(in: -1...2)
            let dayCount = min(remaining, max(1, basePerDay + variation))
            counts[i] = dayCount
            remaining -= dayCount
        }

        // 剩余的均匀补到各天
        var idx = 0
        while remaining > 0 {
            counts[idx % days] += 1
            remaining -= 1
            idx += 1
        }

        return counts
    }

    /// 从时间段中按权重随机选取指定数量
    private static func pickSlots(count: Int) -> [DaySlot] {
        let totalWeight = daySlots.reduce(0) { $0 + $1.weight }
        var selected: [DaySlot] = []

        for _ in 0..<count {
            var random = Double.random(in: 0..<totalWeight)
            var picked = daySlots[0]
            for slot in daySlots {
                random -= slot.weight
                if random <= 0 {
                    picked = slot
                    break
                }
            }
            selected.append(picked)
        }

        return selected
    }

    /// Box-Muller 正态分布随机数，限定范围
    private static func clampedGaussian(mean: Double, stdDev: Double, min: Double, max: Double) -> Double {
        let u1 = Double.random(in: 0.0001...1)
        let u2 = Double.random(in: 0.0001...1)
        let z = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        let value = mean + z * stdDev
        return Swift.min(max, Swift.max(min, value))
    }
}

// MARK: - Preview

#Preview {
    TestDataGeneratorView()
        .modelContainer(for: [GlucoseRecord.self, MedicationRecord.self, MealRecord.self, UserSettings.self], inMemory: true)
        .environment(SubscriptionManager())
}

#endif
