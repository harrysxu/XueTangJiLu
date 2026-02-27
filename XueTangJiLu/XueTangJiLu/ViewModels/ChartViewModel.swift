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
enum TimeRange: String, CaseIterable, Identifiable {
    case week = "7天"
    case twoWeeks = "14天"
    case month = "30天"
    case threeMonths = "90天"
    case custom = "自定义"
    
    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week:        return 7
        case .twoWeeks:    return 14
        case .month:       return 30
        case .threeMonths: return 90
        case .custom:      return 0  // 自定义时由 startDate/endDate 决定
        }
    }
    
    var localizedDisplayName: String {
        switch self {
        case .week:        return String(localized: "time_range.7d")
        case .twoWeeks:    return String(localized: "time_range.14d")
        case .month:       return String(localized: "time_range.30d")
        case .threeMonths: return String(localized: "time_range.90d")
        case .custom:      return String(localized: "log.time.custom")
        }
    }
}

/// 场景标签筛选选项
enum TagFilter: Equatable, Hashable {
    case all                        // 全部
    case group(ThresholdGroup)      // 按阈值分组筛选
    case tag(String)                // 按具体标签 ID 筛选

    var displayName: String {
        switch self {
        case .all:              return "全部"
        case .group(let g):     return g.displayName
        case .tag:              return ""   // 需要从 settings 获取
        }
    }
    
    func localizedDisplayName(settings: UserSettings? = nil) -> String {
        switch self {
        case .all:              return String(localized: "statistics.filter_all")
        case .group(let g):     return g.displayName  // ThresholdGroup may need localization
        case .tag(let id):      return settings?.displayName(for: id) ?? id
        }
    }
}

/// 图表数据聚合 ViewModel
@Observable
final class ChartViewModel {

    /// 选择的时间范围
    var selectedRange: TimeRange = .week
    
    /// 自定义日期范围 - 开始日期
    var customStartDate: Date = Date.daysAgo(7)
    
    /// 自定义日期范围 - 结束日期
    var customEndDate: Date = Date.now

    /// 场景标签筛选
    var selectedTagFilter: TagFilter = .all

    /// 长按选中的数据点
    var selectedPoint: ChartDataPoint?

    /// 从记录列表生成图表数据点（支持标签筛选和场景感知着色）
    func dataPoints(from records: [GlucoseRecord], settings: UserSettings? = nil) -> [ChartDataPoint] {
        let filtered = applyFilters(to: records, settings: settings)

        if selectedRange == .month || selectedRange == .threeMonths {
            return aggregateByDay(records: filtered, settings: settings)
        }

        return filtered
            .sorted { $0.timestamp < $1.timestamp }
            .map { record in
                let level: GlucoseLevel
                if let settings {
                    level = record.glucoseLevel(with: settings)
                } else {
                    level = record.glucoseLevel
                }
                return ChartDataPoint(
                    date: record.timestamp,
                    value: record.value,
                    level: level
                )
            }
    }

    /// 将原始数据按天聚合为平均值
    private func aggregateByDay(records: [GlucoseRecord], settings: UserSettings? = nil) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.timestamp)
        }

        return grouped.map { (date, dayRecords) in
            let avg = dayRecords.reduce(0.0) { $0 + $1.value } / Double(dayRecords.count)
            
            // 使用场景感知的血糖水平判定
            let level: GlucoseLevel
            if let settings {
                // 如果有多个场景的记录，使用包络范围
                let range = effectiveThresholdRange(settings: settings)
                level = GlucoseLevel.from(value: avg, low: range.low, high: range.high)
            } else {
                level = GlucoseLevel.from(value: avg)
            }
            
            return ChartDataPoint(
                date: date,
                value: avg,
                level: level
            )
        }
        .sorted { $0.date < $1.date }
    }

    /// 筛选指定范围 + 标签筛选后的记录
    func filteredRecords(from records: [GlucoseRecord], settings: UserSettings? = nil) -> [GlucoseRecord] {
        applyFilters(to: records, settings: settings)
    }

    /// 获取当前筛选条件下的阈值范围
    /// "全部"时使用所有分组阈值的包络范围，按组/标签时使用对应阈值
    func effectiveThresholdRange(settings: UserSettings) -> (low: Double, high: Double) {
        switch selectedTagFilter {
        case .all:
            return settings.thresholdEnvelope
        case .group(let group):
            let tags = settings.sceneTags.filter { $0.thresholdGroup == group }
            let ranges = tags.map { settings.thresholdRange(for: $0.id) }
            let low = ranges.map(\.low).min() ?? 4.4
            let high = ranges.map(\.high).max() ?? 10.0
            return (low, high)
        case .tag(let tagId):
            return settings.thresholdRange(for: tagId)
        }
    }

    /// 应用时间范围 + 标签筛选
    private func applyFilters(to records: [GlucoseRecord], settings: UserSettings?) -> [GlucoseRecord] {
        let startDate: Date
        let endDate: Date
        
        if selectedRange == .custom {
            startDate = customStartDate
            endDate = customEndDate
        } else {
            startDate = Date.daysAgo(selectedRange.days)
            endDate = Date.now
        }
        
        var result = records.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }

        switch selectedTagFilter {
        case .all:
            break
        case .group(let group):
            if let settings {
                result = result.filter { $0.thresholdGroup(from: settings) == group }
            }
        case .tag(let tagId):
            result = result.filter { $0.sceneTagId == tagId }
        }

        return result
    }
}
