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
    @Query private var settingsArray: [UserSettings]
    @State private var showRecordInput = false
    @State private var showMedicationInput = false
    @State private var showMealInput = false
    @State private var glucoseViewModel = GlucoseViewModel()
    @State private var medicationViewModel = MedicationViewModel()

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    if records.isEmpty {
                        EmptyStateView(
                            icon: "drop",
                            title: "还没有任何记录",
                            subtitle: "点击下方快捷按钮开始记录"
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

                    // 智能洞察卡片
                    if !records.isEmpty {
                        insightCard
                    }

                    // 活动数据
                    if settings.healthKitSyncEnabled {
                        activitySection
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
                RecordInputView(viewModel: $glucoseViewModel)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMedicationInput) {
                MedicationInputView(viewModel: $medicationViewModel)
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
        case 5..<12:  return "早上好"
        case 12..<18: return "下午好"
        default:      return "晚上好"
        }
    }

    // MARK: - 核心血糖卡片

    private var latestGlucoseCard: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            if let latest = latestRecord {
                HStack {
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                        Text("最新血糖")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(latest.displayValue(in: unit))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Color.forGlucoseLevel(latest.glucoseLevel))

                            Text(unit.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: AppConstants.Spacing.xs) {
                            Image(systemName: latest.glucoseLevel.accessoryIconName)
                                .font(.caption)
                            Text(latest.glucoseLevel.description)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color.forGlucoseLevel(latest.glucoseLevel))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: AppConstants.Spacing.xs) {
                        HStack(spacing: AppConstants.Spacing.xs) {
                            Image(systemName: latest.mealContext.iconName)
                                .font(.caption2)
                            Text(latest.mealContext.displayName)
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
                    .fill(Color.forGlucoseLevel(record.glucoseLevel))
                    .frame(width: 4, height: max(8, CGFloat(record.value / 15.0 * 30)))
            }
        }
        .frame(height: 30)
    }

    // MARK: - 今日摘要

    private var todaySummaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Spacing.md) {
            StatCardView(
                title: "今日记录",
                value: "\(todayRecords.count)",
                subtitle: "目标 \(settings.dailyRecordGoal) 次"
            )

            StatCardView(
                title: "今日均值",
                value: todayAverage,
                subtitle: unit.rawValue,
                tintColor: todayAverageColor
            )

            StatCardView(
                title: "达标率",
                value: todayTIR,
                subtitle: "TIR",
                tintColor: todayTIRColor
            )

            StatCardView(
                title: "今日用药",
                value: "\(todayMedications.count)",
                subtitle: "次"
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
        let tir = GlucoseCalculator.timeInRange(
            records: todayRecords,
            low: settings.targetLow,
            high: settings.targetHigh
        )
        return "\(Int(tir))%"
    }

    private var todayTIRColor: Color? {
        guard !todayRecords.isEmpty else { return nil }
        let tir = GlucoseCalculator.timeInRange(
            records: todayRecords,
            low: settings.targetLow,
            high: settings.targetHigh
        )
        return tir >= AppConstants.tirGoodThreshold ? Color("GlucoseNormal") : Color("GlucoseHigh")
    }

    // MARK: - 快捷操作条

    private var quickActionBar: some View {
        HStack(spacing: AppConstants.Spacing.xl) {
            quickActionButton(
                icon: "drop.fill",
                label: "记录血糖",
                color: Color.brandPrimary
            ) {
                glucoseViewModel.resetInput()
                showRecordInput = true
            }

            quickActionButton(
                icon: "syringe.fill",
                label: "记录用药",
                color: Color("GlucoseHigh")
            ) {
                medicationViewModel.resetInput()
                showMedicationInput = true
            }

            quickActionButton(
                icon: "camera.fill",
                label: "拍照饮食",
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

    // MARK: - 智能洞察卡片

    private var insightCard: some View {
        let insight = generateSimpleInsight()
        return HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("今日洞察")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(insight)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(AppConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }

    private func generateSimpleInsight() -> String {
        let count = todayRecords.count
        if count == 0 {
            return "今天还没有记录，记得按时测血糖"
        }
        if let avg = GlucoseCalculator.estimatedAverageGlucose(records: todayRecords) {
            let level = GlucoseLevel.from(value: avg)
            switch level {
            case .normal:
                return "今日平均血糖在正常范围内，继续保持！"
            case .high, .veryHigh:
                return "今日血糖整体偏高，注意饮食控制和适量运动"
            case .low:
                return "今日有低血糖趋势，注意及时补充能量"
            }
        }
        return "已记录 \(count) 次，保持规律监测的好习惯"
    }

    // MARK: - 活动数据

    private var activitySection: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            StatCardView(
                title: "今日步数",
                value: "\(healthKitManager.todaySteps)",
                subtitle: "步"
            )

            StatCardView(
                title: "运动时间",
                value: "\(healthKitManager.todayExerciseMinutes)",
                subtitle: "分钟"
            )
        }
        .task {
            await healthKitManager.refreshActivityData()
        }
    }

    // MARK: - 最近记录

    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack {
                Text("最近记录")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(records.prefix(5))) { record in
                    TimelineRowView(record: record, unit: unit)
                    if record.id != records.prefix(5).last?.id {
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

#Preview {
    DashboardView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self], inMemory: true)
        .environment(HealthKitManager())
}
