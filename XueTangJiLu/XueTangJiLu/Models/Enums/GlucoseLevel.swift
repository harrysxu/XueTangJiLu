//
//  GlucoseLevel.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation

/// 血糖水平状态
enum GlucoseLevel {
    case low       // < 3.9 mmol/L
    case normal    // 3.9 - 6.9 mmol/L
    case high      // 7.0 - 9.9 mmol/L
    case veryHigh  // >= 10.0 mmol/L

    /// 对应的 Asset 颜色名称
    var colorName: String {
        switch self {
        case .low:      return "GlucoseLow"        // 天蓝
        case .normal:   return "GlucoseNormal"      // 翠绿
        case .high:     return "GlucoseHigh"        // 琥珀
        case .veryHigh: return "GlucoseVeryHigh"    // 柔和红
        }
    }

    /// 状态文字描述
    var description: String {
        switch self {
        case .low:      return "偏低"
        case .normal:   return "正常"
        case .high:     return "偏高"
        case .veryHigh: return "注意"
        }
    }

    /// 辅助图标（用于色觉障碍适配）
    var accessoryIconName: String {
        switch self {
        case .normal:            return "checkmark.circle"
        case .high:              return "exclamationmark.triangle"
        case .low, .veryHigh:    return "exclamationmark.circle"
        }
    }

    /// 根据 mmol/L 值判定血糖水平
    static func from(value: Double) -> GlucoseLevel {
        switch value {
        case ..<3.9:     return .low
        case 3.9..<7.0:  return .normal
        case 7.0..<10.0: return .high
        default:         return .veryHigh
        }
    }
}
