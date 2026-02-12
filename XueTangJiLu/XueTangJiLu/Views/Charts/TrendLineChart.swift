//
//  TrendLineChart.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import Charts

/// 血糖趋势折线图
struct TrendLineChart: View {
    let dataPoints: [ChartDataPoint]
    let targetLow: Double
    let targetHigh: Double
    let unit: GlucoseUnit
    @Binding var selectedPoint: ChartDataPoint?

    /// Y 轴范围
    private var yDomain: ClosedRange<Double> {
        let values = dataPoints.map(\.value)
        let minVal = min(values.min() ?? 2.0, targetLow) - 1.0
        let maxVal = max(values.max() ?? 12.0, targetHigh) + 1.0
        return max(minVal, 0)...maxVal
    }

    var body: some View {
        Chart {
            // 目标范围背景带
            RectangleMark(
                yStart: .value("Low", targetLow),
                yEnd: .value("High", targetHigh)
            )
            .foregroundStyle(Color.glucoseNormal.opacity(0.1))

            // 数据折线
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("时间", point.date),
                    y: .value("血糖", displayValue(point.value))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.brandPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("时间", point.date),
                    y: .value("血糖", displayValue(point.value))
                )
                .foregroundStyle(Color.forGlucoseLevel(point.level))
                .symbolSize(30)
            }

            // 选中指示线
            if let selected = selectedPoint {
                RuleMark(x: .value("选中", selected.date))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("选中", selected.date),
                    y: .value("血糖", displayValue(selected.value))
                )
                .foregroundStyle(Color.forGlucoseLevel(selected.level))
                .symbolSize(80)
                .annotation(position: .top, spacing: 8) {
                    selectedAnnotation(for: selected)
                }
            }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x
                                guard let date: Date = proxy.value(atX: xPosition) else { return }
                                // 找到最近的数据点
                                if let closest = findClosestPoint(to: date) {
                                    if selectedPoint?.id != closest.id {
                                        HapticManager.medium()
                                    }
                                    selectedPoint = closest
                                }
                            }
                            .onEnded { _ in
                                selectedPoint = nil
                            }
                    )
            }
        }
        .frame(height: 200)
        .accessibilityLabel(chartAccessibilityLabel)
    }

    // MARK: - 辅助方法

    private func displayValue(_ mmolL: Double) -> Double {
        switch unit {
        case .mmolL: return mmolL
        case .mgdL:  return GlucoseUnitConverter.toMgDL(mmolL)
        }
    }

    private func findClosestPoint(to date: Date) -> ChartDataPoint? {
        dataPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private func selectedAnnotation(for point: ChartDataPoint) -> some View {
        VStack(spacing: 2) {
            Text(GlucoseUnitConverter.displayString(mmolLValue: point.value, in: unit))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.forGlucoseLevel(point.level))
            Text(point.date.timeString)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var chartAccessibilityLabel: String {
        guard !dataPoints.isEmpty else { return "暂无趋势数据" }
        let values = dataPoints.map(\.value)
        let maxVal = values.max() ?? 0
        let minVal = values.min() ?? 0
        let avgVal = values.reduce(0, +) / Double(values.count)
        return "血糖趋势图，共\(dataPoints.count)个数据点，最高\(String(format: "%.1f", maxVal))，最低\(String(format: "%.1f", minVal))，平均\(String(format: "%.1f", avgVal))"
    }
}

#Preview {
    TrendLineChart(
        dataPoints: [
            ChartDataPoint(date: Date.daysAgo(6), value: 5.5, level: .normal),
            ChartDataPoint(date: Date.daysAgo(5), value: 6.8, level: .normal),
            ChartDataPoint(date: Date.daysAgo(4), value: 7.5, level: .high),
            ChartDataPoint(date: Date.daysAgo(3), value: 5.2, level: .normal),
            ChartDataPoint(date: Date.daysAgo(2), value: 8.1, level: .high),
            ChartDataPoint(date: Date.daysAgo(1), value: 6.0, level: .normal),
            ChartDataPoint(date: .now, value: 5.8, level: .normal),
        ],
        targetLow: 3.9,
        targetHigh: 10.0,
        unit: .mmolL,
        selectedPoint: .constant(nil)
    )
    .padding()
}
