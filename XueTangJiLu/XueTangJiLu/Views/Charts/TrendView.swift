//
//  TrendView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData

/// 趋势页 - 数据可视化
struct TrendView: View {
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var allRecords: [GlucoseRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var chartViewModel = ChartViewModel()

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    /// 当前范围内的记录
    private var rangeRecords: [GlucoseRecord] {
        chartViewModel.filteredRecords(from: allRecords)
    }

    /// 图表数据点
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
                            subtitle: "开始记录血糖后，这里将展示您的趋势图表"
                        )
                        .padding(.top, 60)
                    } else {
                        // 时间范围选择器
                        timeRangePicker
                            .padding(.horizontal, AppConstants.Spacing.lg)

                        // 趋势折线图
                        TrendLineChart(
                            dataPoints: dataPoints,
                            targetLow: settings.targetLow,
                            targetHigh: settings.targetHigh,
                            unit: unit,
                            selectedPoint: $chartViewModel.selectedPoint
                        )
                        .padding(.horizontal, AppConstants.Spacing.lg)

                        // 关键指标卡片
                        metricsSection

                        // 波动系数
                        cvSection
                    }
                }
                .padding(.vertical, AppConstants.Spacing.lg)
            }
            .navigationTitle("趋势")
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

    // MARK: - 关键指标

    private var metricsSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            HStack(spacing: AppConstants.Spacing.md) {
                // 平均血糖 (eAG)
                StatCardView(
                    title: "平均血糖",
                    value: averageGlucose,
                    subtitle: unit.rawValue,
                    tintColor: averageColor
                )

                // 预估 A1C
                StatCardView(
                    title: "预估 A1C",
                    value: estimatedA1C,
                    subtitle: nil
                )
            }

            HStack(spacing: AppConstants.Spacing.md) {
                // TIR 达标率
                StatCardView(
                    title: "达标率",
                    value: tirValue,
                    subtitle: "目标 > 70%",
                    tintColor: tirColor
                )

                // 记录次数
                StatCardView(
                    title: "记录次数",
                    value: "\(rangeRecords.count)",
                    subtitle: "近\(chartViewModel.selectedRange.rawValue)"
                )
            }
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
    }

    // MARK: - 波动系数

    private var cvSection: some View {
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
                                        ? Color.glucoseNormal.opacity(0.15)
                                        : Color.glucoseHigh.opacity(0.15)
                                )
                                .foregroundStyle(
                                    cv < AppConstants.cvStableThreshold
                                        ? Color.glucoseNormal
                                        : Color.glucoseHigh
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
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                .padding(.horizontal, AppConstants.Spacing.lg)
            }
        }
    }

    // MARK: - 计算属性

    private var averageGlucose: String {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) else {
            return "--"
        }
        return GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)
    }

    private var averageColor: Color? {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) else {
            return nil
        }
        return Color.forGlucoseValue(avg)
    }

    private var estimatedA1C: String {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) else {
            return "--"
        }
        let a1c = GlucoseCalculator.estimatedA1C(averageGlucoseMmolL: avg)
        return String(format: "%.1f%%", a1c)
    }

    private var tirValue: String {
        guard !rangeRecords.isEmpty else { return "--" }
        let tir = GlucoseCalculator.timeInRange(
            records: rangeRecords,
            low: settings.targetLow,
            high: settings.targetHigh
        )
        return "\(Int(tir))%"
    }

    private var tirColor: Color? {
        guard !rangeRecords.isEmpty else { return nil }
        let tir = GlucoseCalculator.timeInRange(
            records: rangeRecords,
            low: settings.targetLow,
            high: settings.targetHigh
        )
        return tir >= AppConstants.tirGoodThreshold ? .glucoseNormal : .glucoseHigh
    }
}

#Preview {
    TrendView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
}
