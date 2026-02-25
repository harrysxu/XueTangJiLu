//
//  GlucoseCalculator.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation

/// 血糖关键指标计算器
struct GlucoseCalculator {

    /// 计算预估平均血糖 (eAG)
    /// 公式：eAG (mmol/L) = 所有记录的算术平均值
    static func estimatedAverageGlucose(records: [GlucoseRecord]) -> Double? {
        guard !records.isEmpty else { return nil }
        let sum = records.reduce(0.0) { $0 + $1.value }
        return sum / Double(records.count)
    }

    /// 计算预估糖化血红蛋白 (eA1C)
    /// 公式：eA1C (%) = (eAG(mg/dL) + 46.7) / 28.7
    /// 即：eA1C (%) = (eAG(mmol/L) x 18.0182 + 46.7) / 28.7
    static func estimatedA1C(averageGlucoseMmolL: Double) -> Double {
        let eAGmgdL = averageGlucoseMmolL * AppConstants.glucoseConversionFactor
        return (eAGmgdL + 46.7) / 28.7
    }

    /// 计算达标时间比率 (Time in Range, TIR)
    /// 达标范围默认 3.9 - 10.0 mmol/L（可自定义）
    static func timeInRange(
        records: [GlucoseRecord],
        low: Double = 3.9,
        high: Double = 10.0
    ) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let inRange = records.filter { $0.value >= low && $0.value <= high }
        return Double(inRange.count) / Double(records.count) * 100.0
    }

    /// 计算血糖标准差（反映波动程度）
    static func standardDeviation(records: [GlucoseRecord]) -> Double? {
        guard records.count > 1,
              let avg = estimatedAverageGlucose(records: records) else {
            return nil
        }
        let variance = records.reduce(0.0) { $0 + pow($1.value - avg, 2) }
            / Double(records.count - 1)
        return sqrt(variance)
    }

    /// 计算变异系数 (CV%)
    /// CV < 36% 认为血糖波动稳定
    static func coefficientOfVariation(records: [GlucoseRecord]) -> Double? {
        guard let avg = estimatedAverageGlucose(records: records),
              let sd = standardDeviation(records: records),
              avg > 0 else {
            return nil
        }
        return (sd / avg) * 100.0
    }

    // MARK: - TAR / TBR（Time Above/Below Range）

    /// 计算高于目标范围的时间占比 (TAR%)
    static func timeAboveRange(
        records: [GlucoseRecord],
        high: Double = 10.0
    ) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let above = records.filter { $0.value > high }
        return Double(above.count) / Double(records.count) * 100.0
    }

    /// 计算低于目标范围的时间占比 (TBR%)
    static func timeBelowRange(
        records: [GlucoseRecord],
        low: Double = 3.9
    ) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let below = records.filter { $0.value < low }
        return Double(below.count) / Double(records.count) * 100.0
    }

    // MARK: - 上下文感知达标率（逐条按场景阈值评判）

    /// 逐条按场景阈值计算达标率 (Contextual TIR)
    /// 每条记录根据其 sceneTagId 查找对应的阈值范围独立判断
    static func contextualTimeInRange(
        records: [GlucoseRecord],
        settings: UserSettings
    ) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let inRange = records.filter { record in
            let range = settings.thresholdRange(for: record.sceneTagId)
            return record.value >= range.low && record.value <= range.high
        }
        return Double(inRange.count) / Double(records.count) * 100.0
    }

    /// 逐条按场景阈值计算高于目标占比 (Contextual TAR)
    static func contextualTimeAboveRange(
        records: [GlucoseRecord],
        settings: UserSettings
    ) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let above = records.filter { record in
            let range = settings.thresholdRange(for: record.sceneTagId)
            return record.value > range.high
        }
        return Double(above.count) / Double(records.count) * 100.0
    }

    /// 逐条按场景阈值计算低于目标占比 (Contextual TBR)
    static func contextualTimeBelowRange(
        records: [GlucoseRecord],
        settings: UserSettings
    ) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let below = records.filter { record in
            let range = settings.thresholdRange(for: record.sceneTagId)
            return record.value < range.low
        }
        return Double(below.count) / Double(records.count) * 100.0
    }
    
    // MARK: - 连续记录天数计算
    
    /// 计算连续记录天数（用于激励功能）
    /// 从今天开始往前计算连续有记录的天数
    /// - Parameter records: 所有血糖记录
    /// - Returns: 连续记录天数，0 表示今天还没有记录
    static func consecutiveDays(records: [GlucoseRecord]) -> Int {
        guard !records.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        
        // 获取所有有记录的日期（去重）
        let recordDates = records
            .map { calendar.startOfDay(for: $0.timestamp) }
            .reduce(into: Set<Date>()) { $0.insert($1) }
        
        // 从今天开始往前检查
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        while recordDates.contains(checkDate) {
            streak += 1
            // 检查前一天
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }
        
        return streak
    }
    
    /// 获取连续天数的激励文字
    /// - Parameter days: 连续天数
    /// - Returns: 激励文字，nil 表示无需显示
    static func streakEncouragement(for days: Int) -> String? {
        switch days {
        case 0:
            return nil
        case 1...6:
            return nil
        case 7:
            return String(localized: "encouragement.week_1")
        case 8...13:
            return nil
        case 14:
            return String(localized: "encouragement.week_2")
        case 15...29:
            return nil
        case 30:
            return String(localized: "encouragement.month_1")
        case 31...49:
            return nil
        case 50:
            return String(localized: "encouragement.day_50")
        case 51...99:
            return nil
        case 100:
            return String(localized: "encouragement.day_100")
        case 101...364:
            return nil
        case 365...:
            return String(localized: "encouragement.year_1")
        default:
            return nil
        }
    }
}
