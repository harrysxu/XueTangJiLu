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
}
