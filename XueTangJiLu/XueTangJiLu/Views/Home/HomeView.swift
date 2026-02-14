//
//  HomeView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData

/// 首页 - 记录流
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKitManager
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var records: [GlucoseRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var showRecordInput = false
    @State private var glucoseViewModel = GlucoseViewModel()

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    /// 最新一条记录
    private var latestRecord: GlucoseRecord? {
        records.first
    }

    /// 今日记录
    private var todayRecords: [GlucoseRecord] {
        records.filter { $0.timestamp.isToday }
    }

    /// 按日期分组的记录
    private var groupedRecords: [(String, [GlucoseRecord])] {
        let grouped = Dictionary(grouping: records) { record in
            record.timestamp.startOfDay
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date, records) in
                (date.sectionTitle, records.sorted { $0.timestamp > $1.timestamp })
            }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if records.isEmpty {
                            // 空状态
                            EmptyStateView(
                                icon: "drop",
                                title: "还没有任何记录",
                                subtitle: "点击下方 \"+\" 开始记录"
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else {
                            // 最新血糖 Hero 区域
                            latestGlucoseSection

                            // 今日概要
                            todaySummarySection

                            // 时间轴列表
                            timelineSection
                        }
                    }
                    // 底部留白，避免 FAB 遮挡
                    .padding(.bottom, 100)
                }

                // 浮动录入按钮 (FAB)
                fabButton
            }
            .navigationTitle("记录")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showRecordInput) {
                RecordInputView(viewModel: $glucoseViewModel)
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 最新血糖区域

    private var latestGlucoseSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            if let latest = latestRecord {
                Text("最新血糖")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                GlucoseValueBadge(
                    value: latest.value,
                    unit: unit,
                    level: latest.glucoseLevel,
                    style: .hero
                )
                .accessibilityIdentifier("latestGlucoseValue")

                HStack(spacing: AppConstants.Spacing.xs) {
                    Image(systemName: latest.mealContext.iconName)
                        .font(.caption2)
                    Text(latest.mealContext.displayName)
                        .font(.footnote)
                    Text("·")
                        .font(.footnote)
                    Text(latest.timestamp.relativeDescription)
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(latestAccessibilityLabel)
    }

    private var latestAccessibilityLabel: String {
        guard let latest = latestRecord else { return "暂无记录" }
        return "最新血糖 \(latest.displayValue(in: unit)) \(unit.rawValue)，\(latest.glucoseLevel.description)，\(latest.mealContext.displayName)"
    }

    // MARK: - 今日概要

    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("今日概要")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppConstants.Spacing.lg)

            HStack(spacing: AppConstants.Spacing.sm) {
                StatCardView(
                    title: "次数",
                    value: "\(todayRecords.count)",
                    subtitle: "今日"
                )

                StatCardView(
                    title: "均值",
                    value: todayAverage,
                    subtitle: unit.rawValue,
                    tintColor: todayAverageColor
                )

                StatCardView(
                    title: "达标率",
                    value: todayTIR,
                    subtitle: "TIR"
                )
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
        }
        .padding(.bottom, AppConstants.Spacing.xl)
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

    // MARK: - 时间轴

    private var timelineSection: some View {
        ForEach(groupedRecords, id: \.0) { sectionTitle, sectionRecords in
            Section {
                ForEach(sectionRecords) { record in
                    TimelineRowView(record: record, unit: unit)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                glucoseViewModel.deleteRecord(record, modelContext: modelContext)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            } header: {
                Text(sectionTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.top, AppConstants.Spacing.lg)
                    .padding(.bottom, AppConstants.Spacing.xs)
            }
        }
    }

    // MARK: - 浮动录入按钮

    private var fabButton: some View {
        Button(action: {
            HapticManager.light()
            glucoseViewModel.resetInput()
            showRecordInput = true
        }) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: AppConstants.Size.fabSize, height: AppConstants.Size.fabSize)
                .background(Color.brandPrimary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .padding(.bottom, AppConstants.Spacing.lg)
        .accessibilityIdentifier("addRecord")
        .accessibilityLabel("添加血糖记录")
        .accessibilityHint("双击打开血糖录入键盘")
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
        .environment(HealthKitManager())
}
