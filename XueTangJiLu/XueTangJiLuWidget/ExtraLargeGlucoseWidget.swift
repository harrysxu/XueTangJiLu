//
//  ExtraLargeGlucoseWidget.swift
//  XueTangJiLuWidget
//
//  Created by XueTangJiLu on 2026/2/14.
//

import WidgetKit
import SwiftUI
import Charts

/// 超大号 Widget 视图 (iPad)：综合仪表盘 — 最新读数 + TIR + 统计 + 趋势图 + 最近记录
struct ExtraLargeGlucoseWidgetView: View {
    let entry: GlucoseWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // MARK: - 左侧：读数 + TIR + 统计
            VStack(alignment: .leading, spacing: 12) {
                // 最新读数
                latestReadingSection

                Divider()

                // TIR 达标率
                tirSection

                Divider()

                // 7 日统计
                weekStatsSection

                Spacer()
            }
            .frame(maxWidth: .infinity)

            Divider()

            // MARK: - 右侧：趋势图 + 最近记录
            VStack(alignment: .leading, spacing: 12) {
                // 趋势图
                trendChartSection

                Divider()

                // 最近记录
                recentRecordsSection
            }
            .frame(maxWidth: .infinity)
        }
        .padding(4)
    }

    // MARK: - 最新读数

    private var latestReadingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("最新血糖")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(entry.formattedValue)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(valueColor)
                    .minimumScaleFactor(0.6)

                Text(entry.unit.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if let mealContext = entry.mealContext {
                    HStack(spacing: 2) {
                        Image(systemName: mealContext.iconName)
                            .font(.caption2)
                        Text(mealContext.displayName)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }

                if let latestTime = entry.latestTime {
                    Text(latestTime, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - TIR 达标率

    private var tirSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("达标率 (TIR)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                // 圆形进度
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: entry.tirValue / 100.0)
                        .stroke(tirColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(entry.tirValue))%")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 2) {
                    Text("3.9 ~ 10.0 mmol/L")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("7 日内 \(entry.weekCount) 次测量")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - 7 日统计

    private var weekStatsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("7 日统计")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                statItem(label: "平均", value: entry.weekAverage, icon: "divide.circle")
                statItem(label: "最低", value: entry.weekMin, icon: "arrow.down.circle")
                statItem(label: "最高", value: entry.weekMax, icon: "arrow.up.circle")
            }
        }
    }

    private func statItem(label: String, value: Double?, icon: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            if let val = value {
                Text(GlucoseUnitConverter.displayString(mmolLValue: val, in: entry.unit))
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .monospacedDigit()
            } else {
                Text("--")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - 趋势图

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("7 日趋势")
                .font(.caption)
                .foregroundStyle(.secondary)

            if entry.weekTrend.count >= 2 {
                Chart {
                    // 正常范围区域
                    RectangleMark(
                        yStart: .value("低", 3.9),
                        yEnd: .value("高", 10.0)
                    )
                    .foregroundStyle(Color.green.opacity(0.08))

                    ForEach(entry.weekTrend, id: \.0) { dataPoint in
                        LineMark(
                            x: .value("日期", dataPoint.0),
                            y: .value("血糖", dataPoint.1)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("日期", dataPoint.0),
                            y: .value("血糖", dataPoint.1)
                        )
                        .symbolSize(16)
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        AxisValueLabel(format: .dateTime.day())
                            .font(.system(size: 9))
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        AxisValueLabel()
                            .font(.system(size: 9))
                    }
                }
                .chartYScale(domain: yDomain)
                .frame(height: 120)
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("暂无足够的趋势数据")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .frame(height: 120)
            }
        }
    }

    // MARK: - 最近记录

    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("最近记录")
                .font(.caption)
                .foregroundStyle(.secondary)

            if entry.recentRecords.isEmpty {
                HStack {
                    Spacer()
                    Text("暂无记录")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            } else {
                ForEach(entry.recentRecords) { record in
                    HStack(spacing: 8) {
                        // 状态图标
                        Image(systemName: record.glucoseLevel.accessoryIconName)
                            .font(.system(size: 10))
                            .foregroundStyle(Color(record.glucoseLevel.colorName))
                            .frame(width: 14)

                        // 血糖值
                        Text(record.formattedValue(in: entry.unit))
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color(record.glucoseLevel.colorName))
                            .frame(width: 40, alignment: .leading)

                        // 用餐场景
                        if let meal = record.mealContext {
                            HStack(spacing: 2) {
                                Image(systemName: meal.iconName)
                                    .font(.system(size: 9))
                                Text(meal.displayName)
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // 时间
                        Text(record.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - 辅助计算

    private var yDomain: ClosedRange<Double> {
        let values = entry.weekTrend.map(\.1)
        let minVal = max((values.min() ?? 2.0) - 1.0, 0)
        let maxVal = (values.max() ?? 14.0) + 1.0
        return minVal...maxVal
    }

    private var valueColor: Color {
        guard let level = entry.glucoseLevel else { return .secondary }
        return Color(level.colorName)
    }

    private var tirColor: Color {
        if entry.tirValue >= 70 {
            return Color("GlucoseNormal")
        } else if entry.tirValue >= 50 {
            return Color("GlucoseHigh")
        } else {
            return Color("GlucoseLow")
        }
    }
}

