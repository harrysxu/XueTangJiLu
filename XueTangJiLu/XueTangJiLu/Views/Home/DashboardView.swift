//
//  DashboardView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData

/// 首页 Dashboard - 仪表盘式概览
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKitManager
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var records: [GlucoseRecord]
    @Query(sort: \MedicationRecord.timestamp, order: .reverse) private var medications: [MedicationRecord]
    @Query(sort: \MealRecord.timestamp, order: .reverse) private var meals: [MealRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var showRecordInput = false
    @State private var showMedicationInput = false
    @State private var showMealInput = false
    @State private var glucoseViewModel = GlucoseViewModel()
    @State private var medicationViewModel = MedicationViewModel()
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    private var latestRecord: GlucoseRecord? {
        records.first
    }

    private var todayRecords: [GlucoseRecord] {
        records.filter { $0.timestamp.isToday }
    }

    private var todayMedications: [MedicationRecord] {
        medications.filter { $0.timestamp.isToday }
    }
    
    private var todayMeals: [MealRecord] {
        meals.filter { $0.timestamp.isToday }
    }
    
    /// 合并的时间轴项目（用于今日记录展示）
    private enum TimelineItem: Identifiable {
        case glucose(GlucoseRecord)
        case medication(MedicationRecord)
        case meal(MealRecord)
        
        var id: String {
            switch self {
            case .glucose(let record):
                return "glucose-\(record.id)"
            case .medication(let record):
                return "medication-\(record.id)"
            case .meal(let record):
                return "meal-\(record.id)"
            }
        }
        
        var timestamp: Date {
            switch self {
            case .glucose(let record):
                return record.timestamp
            case .medication(let record):
                return record.timestamp
            case .meal(let record):
                return record.timestamp
            }
        }
    }
    
    /// 今日所有记录的合并时间轴（按时间倒序）
    private var todayTimelineItems: [TimelineItem] {
        var items: [TimelineItem] = []
        items += todayRecords.map { .glucose($0) }
        items += todayMedications.map { .medication($0) }
        items += todayMeals.map { .meal($0) }
        
        return items.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    if records.isEmpty {
                        EmptyStateView(
                            icon: "drop",
                            title: String(localized: "empty.no_records"),
                            subtitle: String(localized: "empty.tap_add")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        // 核心血糖卡片
                        latestGlucoseCard

                        // 今日摘要卡片
                        todaySummaryGrid
                    }

                    // 快捷操作条
                    quickActionBar

                    // 今日摘要卡片
                    if !records.isEmpty {
                        insightCard
                    }

                    // 最近记录
                    if !records.isEmpty {
                        recentRecordsSection
                    }
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.lg)
            }
            .background(Color.pageBackground)
            .navigationTitle(greetingText)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showRecordInput) {
                RecordInputView(viewModel: glucoseViewModel)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMedicationInput) {
                MedicationInputView(viewModel: medicationViewModel)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMealInput) {
                MealPhotoView()
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 问候语

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return String(localized: "greeting.morning")
        case 12..<18: return String(localized: "greeting.afternoon")
        default:      return String(localized: "greeting.evening")
        }
    }

    // MARK: - 核心血糖卡片

    private var latestGlucoseCard: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            if let latest = latestRecord {
                let level = latest.glucoseLevel(with: settings)
                HStack {
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                        Text(String(localized: "latest.glucose"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(latest.displayValue(in: unit))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Color.forGlucoseLevel(level))

                            Text(unit.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: AppConstants.Spacing.xs) {
                            Image(systemName: level.accessoryIconName)
                                .font(.caption)
                            Text(level.localizedDescription)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color.forGlucoseLevel(level))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: AppConstants.Spacing.xs) {
                        HStack(spacing: AppConstants.Spacing.xs) {
                            Image(systemName: settings.iconName(for: latest.sceneTagId))
                                .font(.caption2)
                            Text(settings.displayName(for: latest.sceneTagId))
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)

                        Text(latest.timestamp.relativeDescription)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        // 迷你 sparkline
                        miniSparkline
                    }
                }
            }
        }
        .padding(AppConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.fullCard)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        )
    }

    // MARK: - 迷你 Sparkline

    private var miniSparkline: some View {
        let recent = Array(todayRecords.prefix(8).reversed())
        return HStack(spacing: 2) {
            ForEach(Array(recent.enumerated()), id: \.offset) { _, record in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.forGlucoseLevel(record.glucoseLevel(with: settings)))
                    .frame(width: 4, height: max(8, CGFloat(record.value / 15.0 * 30)))
            }
        }
        .frame(height: 30)
    }

    // MARK: - 今日摘要

    private var todaySummaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Spacing.md) {
            StatCardView(
                title: String(localized: "today.records"),
                value: "\(todayRecords.count)",
                subtitle: String(localized: "statistics.count")
            )

            StatCardView(
                title: String(localized: "today.average"),
                value: todayAverage,
                tintColor: todayAverageColor,
                metricType: .averageGlucose
            )

            StatCardView(
                title: String(localized: "today.tir"),
                value: todayTIR,
                tintColor: todayTIRColor,
                metricType: .timeInRange
            )

            StatCardView(
                title: String(localized: "today.medication"),
                value: "\(todayMedications.count)",
                subtitle: String(localized: "statistics.count")
            )
        }
    }

    private var todayAverage: String {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: todayRecords) else {
            return "--"
        }
        return GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)
    }

    private var todayAverageColor: Color? {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: todayRecords) else {
            return nil
        }
        return Color.forGlucoseValue(avg)
    }

    private var todayTIR: String {
        guard !todayRecords.isEmpty else { return "--" }
        let tir = GlucoseCalculator.contextualTimeInRange(
            records: todayRecords,
            settings: settings
        )
        return "\(Int(tir))%"
    }

    private var todayTIRColor: Color? {
        guard !todayRecords.isEmpty else { return nil }
        let tir = GlucoseCalculator.contextualTimeInRange(
            records: todayRecords,
            settings: settings
        )
        return tir >= AppConstants.tirGoodThreshold ? Color("GlucoseNormal") : Color("GlucoseHigh")
    }

    // MARK: - 快捷操作条

    private var quickActionBar: some View {
        HStack(spacing: AppConstants.Spacing.xl) {
            quickActionButton(
                icon: "drop.fill",
                label: String(localized: "quick.glucose"),
                color: Color.brandPrimary
            ) {
                glucoseViewModel.resetInput()
                showRecordInput = true
            }

            quickActionButton(
                icon: "syringe.fill",
                label: String(localized: "quick.medication"),
                color: Color("GlucoseHigh")
            ) {
                medicationViewModel.resetInput()
                showMedicationInput = true
            }

            quickActionButton(
                icon: "fork.knife",
                label: String(localized: "quick.meal"),
                color: Color("GlucoseNormal")
            ) {
                showMealInput = true
            }
        }
        .padding(.vertical, AppConstants.Spacing.md)
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            VStack(spacing: AppConstants.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(color)
                    .clipShape(Circle())
                    .shadow(color: color.opacity(0.3), radius: 6, y: 3)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 今日摘要卡片

    private var insightCard: some View {
        let summary = generateTodaySummary()
        return HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.title3)
                .foregroundStyle(Color.brandPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "today.summary.card"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer()
            
            // 分享按钮
            Button(action: shareTodaySummary) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundStyle(Color.brandPrimary)
            }
        }
        .padding(AppConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }

    private func generateTodaySummary() -> String {
        let count = todayRecords.count
        if count == 0 {
            return String(localized: "dashboard.no_records_today")
        }
        if let avg = GlucoseCalculator.estimatedAverageGlucose(records: todayRecords) {
            let avgStr = GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)
            let tir = GlucoseCalculator.contextualTimeInRange(records: todayRecords, settings: settings)
            return String(localized: "dashboard.today_summary", defaultValue: "今日 \(count) 次记录，均值 \(avgStr) \(unit.rawValue)，达标率 \(Int(tir))%")
        }
        return String(localized: "dashboard.recorded_count", defaultValue: "今日已记录 \(count) 次")
    }

    // MARK: - 最近记录

    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack {
                Text(String(localized: "today.records"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            
            if todayTimelineItems.isEmpty {
                Text(String(localized: "dashboard.no_records_today"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppConstants.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                            .fill(Color.cardBackground)
                    )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(todayTimelineItems.enumerated()), id: \.element.id) { index, item in
                        Group {
                            switch item {
                            case .glucose(let record):
                                NavigationLink(destination: GlucoseRecordDetailView(record: record)) {
                                    TimelineRowView(record: record, unit: unit, settings: settings)
                                }
                                .buttonStyle(.plain)
                            case .medication(let medication):
                                MedicationRowView(record: medication)
                            case .meal(let meal):
                                MealRowView(record: meal)
                            }
                        }
                        
                        if index < todayTimelineItems.count - 1 {
                            Divider()
                                .padding(.horizontal, AppConstants.Spacing.lg)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.cardBackground)
                )
            }
        }
    }
    
    // MARK: - 分享今日摘要
    
    private func shareTodaySummary() {
        // 生成今日摘要卡片图片
        guard let image = generateTodaySummaryImage() else {
            return
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("今日血糖摘要_\(Date.now.shortDateString).png")
        
        if let pngData = image.pngData() {
            try? pngData.write(to: tempURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
    
    /// 生成今日摘要图片
    private func generateTodaySummaryImage() -> UIImage? {
        let cardWidth: CGFloat = 375
        let cardHeight: CGFloat = 500
        
        let renderer = ImageRenderer(content: todaySummaryCardView)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = ProposedViewSize(width: cardWidth, height: cardHeight)
        
        return renderer.uiImage
    }
    
    /// 今日摘要卡片视图（用于生成图片）
    private var todaySummaryCardView: some View {
        VStack(spacing: 24) {
            // 品牌标题
            HStack {
                Text(String(localized: "app.name"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            // 日期
            Text(String(localized: "share.today_summary", defaultValue: "今日血糖摘要 · \(Date.now.mediumDateString)"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
            
            // 主要指标
            VStack(spacing: 20) {
                // 记录次数和均值
                HStack(spacing: 32) {
                    metricItem(
                        title: String(localized: "statistics.count"),
                        value: "\(todayRecords.count)",
                        unit: String(localized: "dashboard.times")
                    )
                    
                    if let avg = GlucoseCalculator.estimatedAverageGlucose(records: todayRecords) {
                        metricItem(
                            title: String(localized: "statistics.average"),
                            value: GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit),
                            unit: unit.rawValue
                        )
                    }
                }
                
                // 达标率和用药
                HStack(spacing: 32) {
                    if !todayRecords.isEmpty {
                        let tir = GlucoseCalculator.contextualTimeInRange(records: todayRecords, settings: settings)
                        metricItem(
                            title: String(localized: "statistics.tir"),
                            value: String(format: "%.0f", tir),
                            unit: "%"
                        )
                    }
                    
                    metricItem(
                        title: String(localized: "dashboard.medication_count"),
                        value: "\(todayMedications.count)",
                        unit: String(localized: "dashboard.times")
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
            )
            
            Spacer()
            
            // 底部提示
            VStack(spacing: 8) {
                Text("share.keep_good_habit", tableName: "Localizable")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                
                Text("share.disclaimer", tableName: "Localizable")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(32)
        .frame(width: 375, height: 500)
        .background(
            LinearGradient(
                colors: [
                    Color.brandPrimary,
                    Color.brandPrimary.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func metricItem(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self, MealRecord.self], inMemory: true)
        .environment(HealthKitManager())
}
