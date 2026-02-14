//
//  LargeGlucoseWidget.swift
//  XueTangJiLuWidget
//
//  Created by XueTangJiLu on 2026/2/14.
//

import WidgetKit
import SwiftUI
import Charts

/// 大号 Widget 视图：最新读数 + 7 日趋势折线图 + 最近记录列表
struct LargeGlucoseWidgetView: View {
    let entry: GlucoseWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - 顶部：最新读数 + 统计概览
            HStack(alignment: .top) {
                // 左侧：最新血糖
                VStack(alignment: .leading, spacing: 2) {
                    Text("最新血糖")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(entry.formattedValue)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(valueColor)
                        .minimumScaleFactor(0.6)

                    Text(entry.unit.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 右侧：统计卡片
                VStack(alignment: .trailing, spacing: 4) {
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

                    // TIR 达标率
                    HStack(spacing: 4) {
                        Text("TIR")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(entry.tirValue))%")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(tirColor)
                    }
                }
            }

            // MARK: - 中部：7 日趋势图
            if entry.weekTrend.count >= 2 {
                trendChartSection
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                        Text("暂无足够的趋势数据")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .frame(height: 80)
            }

            Divider()

            // MARK: - 底部：最近记录列表
            recentRecordsSection
        }
        .padding(4)
    }

    // MARK: - 趋势图
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("7 日趋势")
                .font(.caption2)
                .foregroundStyle(.secondary)

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
                    .lineStyle(StrokeStyle(lineWidth: 1.5))

                    PointMark(
                        x: .value("日期", dataPoint.0),
                        y: .value("血糖", dataPoint.1)
                    )
                    .symbolSize(12)
                    .foregroundStyle(Color.accentColor)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 8))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    AxisValueLabel()
                        .font(.system(size: 8))
                }
            }
            .chartYScale(domain: yDomain)
            .frame(height: 80)
        }
    }

    // MARK: - 最近记录列表
    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("最近记录")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if entry.recentRecords.isEmpty {
                Text("暂无记录")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(entry.recentRecords) { record in
                    HStack(spacing: 6) {
                        // 血糖值
                        Text(record.formattedValue(in: entry.unit))
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color(record.glucoseLevel.colorName))
                            .frame(width: 40, alignment: .leading)

                        // 状态指示
                        Image(systemName: record.glucoseLevel.accessoryIconName)
                            .font(.system(size: 8))
                            .foregroundStyle(Color(record.glucoseLevel.colorName))

                        // 用餐场景
                        if let meal = record.mealContext {
                            HStack(spacing: 1) {
                                Image(systemName: meal.iconName)
                                    .font(.system(size: 8))
                                Text(meal.displayName)
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // 时间
                        Text(record.timestamp, style: .relative)
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

