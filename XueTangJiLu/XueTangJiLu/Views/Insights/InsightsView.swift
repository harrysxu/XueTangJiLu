//
//  InsightsView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData

/// 洞察 Tab - 趋势图表 + 智能分析 + 目标进度
struct InsightsView: View {
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var allRecords: [GlucoseRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var chartViewModel = ChartViewModel()

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    private var rangeRecords: [GlucoseRecord] {
        chartViewModel.filteredRecords(from: allRecords)
    }

    private var dataPoints: [ChartDataPoint] {
        chartViewModel.dataPoints(from: allRecords)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    if allRecords.isEmpty {
                        EmptyStateView(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "暂无趋势数据",
                            subtitle: "开始记录血糖后，这里将展示您的趋势图表和洞察"
                        )
                        .padding(.top, 60)
                    } else {
                        // 时间范围选择器
                        timeRangePicker

                        // 趋势折线图
                        TrendLineChart(
                            dataPoints: dataPoints,
                            targetLow: settings.targetLow,
                            targetHigh: settings.targetHigh,
                            unit: unit,
                            selectedPoint: $chartViewModel.selectedPoint
                        )

                        // 指标卡片 2x2
                        metricsGrid

                        // 波动系数卡片
                        cvCard

                        // 周对比
                        weeklyComparison

                        // A1C 目标进度
                        a1cGoalCard

                        // 智能洞察
                        insightsSection
                    }
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.lg)
            }
            .background(Color.pageBackground.ignoresSafeArea())
            .navigationTitle("洞察")
        }
    }

    // MARK: - 时间范围选择器

    private var timeRangePicker: some View {
        Picker("时间范围", selection: $chartViewModel.selectedRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 指标 2x2 网格

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Spacing.md) {
            StatCardView(
                title: "平均血糖",
                value: averageGlucose,
                subtitle: unit.rawValue,
                tintColor: averageColor
            )

            StatCardView(
                title: "预估 A1C",
                value: estimatedA1C,
                subtitle: "目标 < \(String(format: "%.1f%%", settings.targetA1C))"
            )

            StatCardView(
                title: "达标率",
                value: tirValue,
                subtitle: "目标 > 70%",
                tintColor: tirColor
            )

            StatCardView(
                title: "记录次数",
                value: "\(rangeRecords.count)",
                subtitle: "近\(chartViewModel.selectedRange.rawValue)"
            )
        }
    }

    // MARK: - CV% 卡片

    private var cvCard: some View {
        Group {
            if let cv = GlucoseCalculator.coefficientOfVariation(records: rangeRecords) {
                HStack {
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                        Text("波动系数 (CV%)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        HStack(spacing: AppConstants.Spacing.sm) {
                            Text(String(format: "%.1f%%", cv))
                                .font(.glucoseMetric)

                            Text(cv < AppConstants.cvStableThreshold ? "稳定" : "波动较大")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    cv < AppConstants.cvStableThreshold
                                        ? Color("GlucoseNormal").opacity(0.15)
                                        : Color("GlucoseHigh").opacity(0.15)
                                )
                                .foregroundStyle(
                                    cv < AppConstants.cvStableThreshold
                                        ? Color("GlucoseNormal")
                                        : Color("GlucoseHigh")
                                )
                                .clipShape(Capsule())
                        }

                        Text("目标 < 36%")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding(AppConstants.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.cardBackground)
                )
            }
        }
    }

    // MARK: - 周对比

    private var weeklyComparison: some View {
        let thisWeek = allRecords.filter { $0.timestamp >= Date.daysAgo(7) }
        let lastWeek = allRecords.filter { $0.timestamp >= Date.daysAgo(14) && $0.timestamp < Date.daysAgo(7) }

        let thisAvg = GlucoseCalculator.estimatedAverageGlucose(records: thisWeek)
        let lastAvg = GlucoseCalculator.estimatedAverageGlucose(records: lastWeek)

        return Group {
            if let tAvg = thisAvg, let lAvg = lastAvg {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    Text("周对比")
                        .font(.subheadline.weight(.semibold))

                    HStack(spacing: AppConstants.Spacing.xl) {
                        comparisonItem(
                            label: "本周均值",
                            value: GlucoseUnitConverter.displayString(mmolLValue: tAvg, in: unit),
                            trend: tAvg < lAvg ? .down : (tAvg > lAvg ? .up : .same)
                        )

                        comparisonItem(
                            label: "上周均值",
                            value: GlucoseUnitConverter.displayString(mmolLValue: lAvg, in: unit),
                            trend: .same
                        )

                        let thisTIR = GlucoseCalculator.timeInRange(records: thisWeek, low: settings.targetLow, high: settings.targetHigh)
                        let lastTIR = GlucoseCalculator.timeInRange(records: lastWeek, low: settings.targetLow, high: settings.targetHigh)
                        comparisonItem(
                            label: "本周TIR",
                            value: "\(Int(thisTIR))%",
                            trend: thisTIR > lastTIR ? .up : (thisTIR < lastTIR ? .down : .same)
                        )
                    }
                }
                .padding(AppConstants.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.cardBackground)
                )
            }
        }
    }

    private enum TrendDirection {
        case up, down, same
    }

    private func comparisonItem(label: String, value: String, trend: TrendDirection) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 2) {
                Text(value)
                    .font(.glucoseCallout)
                if trend != .same {
                    Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                        .foregroundStyle(trend == .down ? Color("GlucoseNormal") : Color("GlucoseHigh"))
                }
            }
        }
    }

    // MARK: - A1C 目标

    private var a1cGoalCard: some View {
        Group {
            if let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) {
                let a1c = GlucoseCalculator.estimatedA1C(averageGlucoseMmolL: avg)
                let progress = min(1.0, max(0, (12.0 - a1c) / (12.0 - settings.targetA1C)))

                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    HStack {
                        Text("A1C 目标追踪")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(String(format: "%.1f%%", a1c))
                            .font(.glucoseMetric)
                            .foregroundStyle(a1c <= settings.targetA1C ? Color("GlucoseNormal") : Color("GlucoseHigh"))
                    }

                    // 进度条
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    a1c <= settings.targetA1C
                                        ? Color("GlucoseNormal")
                                        : Color("GlucoseHigh")
                                )
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("当前 \(String(format: "%.1f%%", a1c))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("目标 \(String(format: "%.1f%%", settings.targetA1C))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(AppConstants.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.cardBackground)
                )
            }
        }
    }

    // MARK: - 智能洞察

    private var insightsSection: some View {
        let insights = InsightEngine.generateInsights(
            records: allRecords,
            targetLow: settings.targetLow,
            targetHigh: settings.targetHigh
        )

        return Group {
            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    Text("智能洞察")
                        .font(.subheadline.weight(.semibold))

                    ForEach(insights) { insight in
                        InsightCardView(insight: insight)
                    }
                }
            }
        }
    }

    // MARK: - 计算属性

    private var averageGlucose: String {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) else { return "--" }
        return GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)
    }

    private var averageColor: Color? {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) else { return nil }
        return Color.forGlucoseValue(avg)
    }

    private var estimatedA1C: String {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) else { return "--" }
        let a1c = GlucoseCalculator.estimatedA1C(averageGlucoseMmolL: avg)
        return String(format: "%.1f%%", a1c)
    }

    private var tirValue: String {
        guard !rangeRecords.isEmpty else { return "--" }
        let tir = GlucoseCalculator.timeInRange(records: rangeRecords, low: settings.targetLow, high: settings.targetHigh)
        return "\(Int(tir))%"
    }

    private var tirColor: Color? {
        guard !rangeRecords.isEmpty else { return nil }
        let tir = GlucoseCalculator.timeInRange(records: rangeRecords, low: settings.targetLow, high: settings.targetHigh)
        return tir >= AppConstants.tirGoodThreshold ? Color("GlucoseNormal") : Color("GlucoseHigh")
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
}
