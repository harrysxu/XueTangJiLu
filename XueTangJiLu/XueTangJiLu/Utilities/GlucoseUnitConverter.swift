//
//  GlucoseUnitConverter.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation

/// 血糖单位转换工具
struct GlucoseUnitConverter {

    /// mmol/L 转 mg/dL
    static func toMgDL(_ mmolL: Double) -> Double {
        mmolL * AppConstants.glucoseConversionFactor
    }

    /// mg/dL 转 mmol/L
    static func toMmolL(_ mgdL: Double) -> Double {
        mgdL / AppConstants.glucoseConversionFactor
    }

    /// 智能识别输入值的单位
    /// 规则：mmol/L 通常范围 1.0 - 33.3，mg/dL 通常范围 18 - 600
    /// 如果值 > 35，大概率是 mg/dL
    static func detectUnit(for value: Double) -> GlucoseUnit {
        if value > 35.0 {
            return .mgdL
        } else {
            return .mmolL
        }
    }

    /// 将任意输入标准化为 mmol/L（内部统一存储单位）
    static func normalize(value: Double, preferredUnit: GlucoseUnit) -> Double {
        switch preferredUnit {
        case .mmolL: return value
        case .mgdL:  return toMmolL(value)
        }
    }

    /// 格式化显示值
    static func displayString(mmolLValue: Double, in unit: GlucoseUnit) -> String {
        switch unit {
        case .mmolL:
            return String(format: "%.1f", mmolLValue)
        case .mgdL:
            return String(format: "%.0f", toMgDL(mmolLValue))
        }
    }
}
