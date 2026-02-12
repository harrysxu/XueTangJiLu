//
//  GlucoseUnit.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation

/// 血糖单位
enum GlucoseUnit: String, Codable, CaseIterable {
    case mmolL = "mmol/L"
    case mgdL  = "mg/dL"

    /// 根据系统地区自动推断默认单位
    /// 美国、日本等使用 mg/dL，中国、欧洲等使用 mmol/L
    static var systemDefault: GlucoseUnit {
        let regionCode = Locale.current.region?.identifier ?? "CN"
        let mgdLRegions = ["US", "JP", "IN", "CO", "IL"]
        return mgdLRegions.contains(regionCode) ? .mgdL : .mmolL
    }

    /// 显示名称
    var displayName: String {
        rawValue
    }

    /// 输入小数位数限制
    var maxDecimalPlaces: Int {
        switch self {
        case .mmolL: return 1
        case .mgdL:  return 0
        }
    }

    /// 有效输入范围最小值
    var minValue: Double {
        switch self {
        case .mmolL: return 1.0
        case .mgdL:  return 18.0
        }
    }

    /// 有效输入范围最大值
    var maxValue: Double {
        switch self {
        case .mmolL: return 33.3
        case .mgdL:  return 600.0
        }
    }
}
