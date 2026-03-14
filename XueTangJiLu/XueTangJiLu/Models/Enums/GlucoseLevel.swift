//
//  GlucoseLevel.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation

/// 血糖水平状态
enum GlucoseLevel {
    case low       // < 低阈值
    case normal    // 低阈值 - 高阈值
    case high      // 高阈值 - (高阈值+3)
    case veryHigh  // >= (高阈值+3)

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
    
    /// 本地化的状态文字描述
    var localizedDescription: String {
        switch self {
        case .low:      return String(localized: "level.low")
        case .normal:   return String(localized: "level.normal")
        case .high:     return String(localized: "level.high")
        case .veryHigh: return String(localized: "level.veryHigh")
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

    /// 根据 mmol/L 值判定血糖水平（通用固定阈值，用于无场景上下文时的兜底）
    static func from(value: Double) -> GlucoseLevel {
        switch value {
        case ..<3.9:     return .low
        case 3.9..<7.0:  return .normal
        case 7.0..<10.0: return .high
        default:         return .veryHigh
        }
    }

    /// 根据 mmol/L 值 + 标签 ID + 用户设置判定血糖水平（支持自定义标签）
    ///
    /// +3.0 mmol/L 偏移量为 App 的 UX 分级设计，用于在「偏高」和「注意」之间
    /// 提供渐进式提醒。此分级仅用于界面颜色提示，不用于 TIR/TAR/TBR 等统计指标计算。
    static func from(value: Double, tagId: String, settings: UserSettings) -> GlucoseLevel {
        let range = settings.thresholdRange(for: tagId)
        switch value {
        case ..<range.low:                     return .low
        case range.low..<range.high:           return .normal
        case range.high..<(range.high + 3.0):  return .high
        default:                               return .veryHigh
        }
    }

    /// 根据 mmol/L 值 + 自定义阈值判定血糖水平
    ///
    /// +3.0 mmol/L 偏移量说明同上，为 UX 渐进式分级设计，非医学诊断标准。
    static func from(value: Double, low: Double, high: Double) -> GlucoseLevel {
        switch value {
        case ..<low:                 return .low
        case low..<high:             return .normal
        case high..<(high + 3.0):    return .high
        default:                     return .veryHigh
        }
    }
}
