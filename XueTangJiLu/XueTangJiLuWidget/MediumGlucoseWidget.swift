//
//  MediumGlucoseWidget.swift
//  XueTangJiLuWidget
//
//  Created by XueTangJiLu on 2026/2/14.
//

import WidgetKit
import SwiftUI
import Charts

/// 中号 Widget 视图：显示最新读数 + 7 日迷你趋势折线图
struct MediumGlucoseWidgetView: View {
    let entry: GlucoseWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            // 左侧：最新读数
            VStack(alignment: .leading, spacing: 4) {
                Text("最新血糖")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(entry.formattedValue)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(valueColor)
                    .minimumScaleFactor(0.6)

                Text(entry.unit.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

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
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右侧：迷你趋势图
            if entry.weekTrend.count >= 2 {
                miniTrendChart
                    .frame(maxWidth: .infinity)
            } else {
                VStack {
                    Text("7日趋势")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("数据不足")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
    }

    private var miniTrendChart: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("7日趋势")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(entry.weekTrend, id: \.0) { dataPoint in
                    LineMark(
                        x: .value("日期", dataPoint.0),
                        y: .value("血糖", dataPoint.1)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: yDomain)
        }
    }

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
}

