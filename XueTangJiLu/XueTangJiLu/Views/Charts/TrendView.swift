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
    @State private var showCustomDatePicker = false

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
                            title: String(localized: "chart.no_trend_data"),
                            subtitle: String(localized: "trend.empty.hint")
                        )
                        .padding(.top, 60)
                    } else {
                        // 时间范围选择器
                        timeRangePicker
                            .padding(.horizontal, AppConstants.Spacing.lg)

                        // 趋势折线图（使用包络范围作为目标带）
                        TrendLineChart(
                            dataPoints: dataPoints,
                            targetLow: settings.thresholdEnvelope.low,
                            targetHigh: settings.thresholdEnvelope.high,
                            unit: unit,
                            selectedPoint: $chartViewModel.selectedPoint
                        )
                        .padding(.horizontal, AppConstants.Spacing.lg)

                        // 关键指标卡片
                        metricsSection
                    }
                }
                .padding(.vertical, AppConstants.Spacing.lg)
            }
            .navigationTitle(String(localized: "trend.title"))
        }
    }

    // MARK: - 时间范围选择器

    private var timeRangePicker: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            Picker(String(localized: "statistics.time_range"), selection: $chartViewModel.selectedRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: chartViewModel.selectedRange) { _, newValue in
                if newValue == .custom {
                    showCustomDatePicker = true
                }
            }
            
            // 自定义日期范围显示
            if chartViewModel.selectedRange == .custom {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.brandPrimary)
                    
                    Text("\(chartViewModel.customStartDate.shortDateString) - \(chartViewModel.customEndDate.shortDateString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button {
                        showCustomDatePicker = true
                    } label: {
                        Text("record.modify", tableName: "Localizable")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brandPrimary.opacity(0.08))
                )
            }
        }
        .sheet(isPresented: $showCustomDatePicker) {
            CustomDateRangePickerView(
                startDate: $chartViewModel.customStartDate,
                endDate: $chartViewModel.customEndDate
            )
        }
    }

    // MARK: - 关键指标

    private var metricsSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            HStack(spacing: AppConstants.Spacing.md) {
                // 平均血糖 (eAG)
                StatCardView(
                    title: String(localized: "statistics.average"),
                    value: averageGlucose,
                    subtitle: unit.rawValue,
                    tintColor: averageColor
                )

                // TIR 达标率
                StatCardView(
                    title: String(localized: "statistics.tir"),
                    value: tirValue,
                    subtitle: String(localized: "trend.tir.target"),
                    tintColor: tirColor
                )
            }

            HStack(spacing: AppConstants.Spacing.md) {
                // 波动系数
                StatCardView(
                    title: String(localized: "statistics.cv.label"),
                    value: cvValue,
                    subtitle: String(localized: "trend.cv.target"),
                    tintColor: cvColor
                )

                // 记录次数
                StatCardView(
                    title: String(localized: "statistics.records"),
                    value: "\(rangeRecords.count)",
                    subtitle: String(format: String(localized: "statistics.records_near"), chartViewModel.selectedRange.rawValue)
                )
            }
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
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

    private var cvValue: String {
        guard let cv = GlucoseCalculator.coefficientOfVariation(records: rangeRecords) else {
            return "--"
        }
        return String(format: "%.1f%%", cv)
    }

    private var cvColor: Color? {
        guard let cv = GlucoseCalculator.coefficientOfVariation(records: rangeRecords) else {
            return nil
        }
        return cv < AppConstants.cvStableThreshold ? .glucoseNormal : .glucoseHigh
    }

    private var tirValue: String {
        guard !rangeRecords.isEmpty else { return "--" }
        let tir = GlucoseCalculator.contextualTimeInRange(
            records: rangeRecords,
            settings: settings
        )
        return "\(Int(tir))%"
    }

    private var tirColor: Color? {
        guard !rangeRecords.isEmpty else { return nil }
        let tir = GlucoseCalculator.contextualTimeInRange(
            records: rangeRecords,
            settings: settings
        )
        return tir >= AppConstants.tirGoodThreshold ? .glucoseNormal : .glucoseHigh
    }
}

#Preview {
    TrendView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
}
