//
//  ChartViewModel.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import Observation

/// 图表数据点
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let level: GlucoseLevel
}

/// 时间范围选项
enum TimeRange: String, CaseIterable {
    case week = "7天"
    case twoWeeks = "14天"
    case month = "30天"
    case threeMonths = "90天"

    var days: Int {
        switch self {
        case .week:        return 7
        case .twoWeeks:    return 14
        case .month:       return 30
        case .threeMonths: return 90
        }
    }
}

/// 图表数据聚合 ViewModel
@Observable
final class ChartViewModel {

    /// 选择的时间范围
    var selectedRange: TimeRange = .week

    /// 长按选中的数据点
    var selectedPoint: ChartDataPoint?

    /// 从记录列表生成图表数据点
    func dataPoints(from records: [GlucoseRecord]) -> [ChartDataPoint] {
        let startDate = Date.daysAgo(selectedRange.days)
        let filtered = records.filter { $0.timestamp >= startDate }

        // 7 / 14 天使用原始数据点，30 / 90 天使用按天聚合
        if selectedRange == .month || selectedRange == .threeMonths {
            return aggregateByDay(records: filtered)
        }

        return filtered
            .sorted { $0.timestamp < $1.timestamp }
            .map { record in
                ChartDataPoint(
                    date: record.timestamp,
                    value: record.value,
                    level: record.glucoseLevel
                )
            }
    }

    /// 将原始数据按天聚合为平均值
    private func aggregateByDay(records: [GlucoseRecord]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.timestamp)
        }

        return grouped.map { (date, dayRecords) in
            let avg = dayRecords.reduce(0.0) { $0 + $1.value } / Double(dayRecords.count)
            return ChartDataPoint(
                date: date,
                value: avg,
                level: GlucoseLevel.from(value: avg)
            )
        }
        .sorted { $0.date < $1.date }
    }

    /// 筛选指定范围内的记录
    func filteredRecords(from records: [GlucoseRecord]) -> [GlucoseRecord] {
        let startDate = Date.daysAgo(selectedRange.days)
        return records.filter { $0.timestamp >= startDate }
    }
}
