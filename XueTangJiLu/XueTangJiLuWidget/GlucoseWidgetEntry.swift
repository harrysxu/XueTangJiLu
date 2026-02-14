//
//  GlucoseWidgetEntry.swift
//  XueTangJiLuWidget
//
//  Created by XueTangJiLu on 2026/2/14.
//

import WidgetKit
import Foundation

/// Widget 中展示的简化记录数据
struct WidgetRecordData: Identifiable {
    let id = UUID()
    let value: Double
    let timestamp: Date
    let mealContextRawValue: String?
    let note: String?

    var mealContext: MealContext? {
        guard let raw = mealContextRawValue else { return nil }
        return MealContext(rawValue: raw)
    }

    var glucoseLevel: GlucoseLevel {
        GlucoseLevel.from(value: value)
    }

    func formattedValue(in unit: GlucoseUnit) -> String {
        GlucoseUnitConverter.displayString(mmolLValue: value, in: unit)
    }
}

/// Widget 数据条目
struct GlucoseWidgetEntry: TimelineEntry {
    let date: Date

    /// 最新血糖值 (mmol/L)
    let latestValue: Double?

    /// 最新记录时间
    let latestTime: Date?

    /// 用餐场景原始值
    let mealContextRawValue: String?

    /// 用户首选单位原始值
    let unitRawValue: String

    /// 达标率 (0-100)
    let tirValue: Double

    /// 7 日趋势数据点 [(timestamp, mmol/L)]
    let weekTrend: [(Date, Double)]

    /// 最近记录列表（用于大号 Widget）
    let recentRecords: [WidgetRecordData]

    /// 7 日统计数据
    let weekAverage: Double?
    let weekMin: Double?
    let weekMax: Double?
    let weekCount: Int

    // MARK: - 便利属性

    var unit: GlucoseUnit {
        GlucoseUnit(rawValue: unitRawValue) ?? .mmolL
    }

    var mealContext: MealContext? {
        guard let raw = mealContextRawValue else { return nil }
        return MealContext(rawValue: raw)
    }

    var glucoseLevel: GlucoseLevel? {
        guard let value = latestValue else { return nil }
        return GlucoseLevel.from(value: value)
    }

    var formattedValue: String {
        guard let value = latestValue else { return "--" }
        return GlucoseUnitConverter.displayString(mmolLValue: value, in: unit)
    }

    // MARK: - 占位数据

    static var placeholder: GlucoseWidgetEntry {
        GlucoseWidgetEntry(
            date: .now,
            latestValue: 5.6,
            latestTime: .now,
            mealContextRawValue: MealContext.beforeBreakfast.rawValue,
            unitRawValue: GlucoseUnit.mmolL.rawValue,
            tirValue: 78.0,
            weekTrend: [],
            recentRecords: [],
            weekAverage: 6.2,
            weekMin: 4.1,
            weekMax: 9.8,
            weekCount: 21
        )
    }

    static var empty: GlucoseWidgetEntry {
        GlucoseWidgetEntry(
            date: .now,
            latestValue: nil,
            latestTime: nil,
            mealContextRawValue: nil,
            unitRawValue: GlucoseUnit.systemDefault.rawValue,
            tirValue: 0,
            weekTrend: [],
            recentRecords: [],
            weekAverage: nil,
            weekMin: nil,
            weekMax: nil,
            weekCount: 0
        )
    }
}
