//
//  MealContext.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import HealthKit

/// 用餐场景
enum MealContext: String, Codable, CaseIterable {
    case beforeBreakfast = "breakfast_before"  // 早餐前
    case afterBreakfast  = "breakfast_after"   // 早餐后
    case beforeLunch     = "lunch_before"      // 午餐前
    case afterLunch      = "lunch_after"       // 午餐后
    case beforeDinner    = "dinner_before"     // 晚餐前
    case afterDinner     = "dinner_after"      // 晚餐后
    case fasting         = "fasting"           // 空腹
    case bedtime         = "bedtime"           // 睡前
    case other           = "other"             // 其他

    /// 本地化显示名称
    var displayName: String {
        switch self {
        case .beforeBreakfast: return "早餐前"
        case .afterBreakfast:  return "早餐后"
        case .beforeLunch:     return "午餐前"
        case .afterLunch:      return "午餐后"
        case .beforeDinner:    return "晚餐前"
        case .afterDinner:     return "晚餐后"
        case .fasting:         return "空腹"
        case .bedtime:         return "睡前"
        case .other:           return "其他"
        }
    }

    /// SF Symbol 图标名
    var iconName: String {
        switch self {
        case .beforeBreakfast, .afterBreakfast: return "sunrise"
        case .beforeLunch, .afterLunch:         return "sun.max"
        case .beforeDinner, .afterDinner:       return "sunset"
        case .fasting:                          return "moon.zzz"
        case .bedtime:                          return "bed.double"
        case .other:                            return "clock"
        }
    }

    /// 映射到 HealthKit 的 HKBloodGlucoseMealTime
    var healthKitMealTime: Int? {
        switch self {
        case .beforeBreakfast, .beforeLunch, .beforeDinner, .fasting:
            return HKBloodGlucoseMealTime.preprandial.rawValue  // 餐前
        case .afterBreakfast, .afterLunch, .afterDinner:
            return HKBloodGlucoseMealTime.postprandial.rawValue // 餐后
        case .bedtime, .other:
            return nil  // HealthKit 无对应类型，不设置
        }
    }
}
