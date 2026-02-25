//
//  MealContext.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import HealthKit

// MARK: - 阈值分组

/// 血糖阈值分组（不同场景使用不同的正常范围）
enum ThresholdGroup: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case fasting       // 空腹/餐前
    case postprandial  // 餐后
    case bedtime       // 睡前

    var displayName: String {
        switch self {
        case .fasting:       return "空腹/餐前"
        case .postprandial:  return "餐后"
        case .bedtime:       return "睡前"
        }
    }
    
    /// 本地化的显示名称
    var localizedDisplayName: String {
        switch self {
        case .fasting:       return String(localized: "threshold.fasting_premeal")
        case .postprandial:  return String(localized: "threshold.postmeal")
        case .bedtime:       return String(localized: "threshold.bedtime")
        }
    }

    /// ADA 推荐范围描述
    var adaRecommendation: String {
        switch self {
        case .fasting:       return "ADA 推荐：4.4 - 7.2 mmol/L (80-130 mg/dL)"
        case .postprandial:  return "ADA 推荐：餐后 2h < 10.0 mmol/L (180 mg/dL)"
        case .bedtime:       return "建议：5.0 - 7.8 mmol/L (90-140 mg/dL)"
        }
    }
    
    /// 本地化的ADA推荐范围描述
    var localizedAdaRecommendation: String {
        switch self {
        case .fasting:       return String(localized: "threshold.ada_fasting")
        case .postprandial:  return String(localized: "threshold.ada_postmeal")
        case .bedtime:       return String(localized: "threshold.ada_bedtime")
        }
    }
}

/// 用餐场景
enum MealContext: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case beforeBreakfast = "breakfast_before"  // 早餐前
    case afterBreakfast  = "breakfast_after"   // 早餐后
    case beforeLunch     = "lunch_before"      // 午餐前
    case afterLunch      = "lunch_after"       // 午餐后
    case beforeDinner    = "dinner_before"     // 晚餐前
    case afterDinner     = "dinner_after"      // 晚餐后
    case fasting         = "fasting"           // 空腹
    case bedtime         = "bedtime"           // 睡前
    case other           = "other"             // 其他

    /// 默认显示名称（内置，不可修改）
    var defaultDisplayName: String {
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
    
    /// 本地化的显示名称
    var localizedDisplayName: String {
        switch self {
        case .beforeBreakfast: return String(localized: "meal.before_breakfast")
        case .afterBreakfast:  return String(localized: "meal.after_breakfast")
        case .beforeLunch:     return String(localized: "meal.before_lunch")
        case .afterLunch:      return String(localized: "meal.after_lunch")
        case .beforeDinner:    return String(localized: "meal.before_dinner")
        case .afterDinner:     return String(localized: "meal.after_dinner")
        case .fasting:         return String(localized: "meal.fasting")
        case .bedtime:         return String(localized: "meal.bedtime")
        case .other:           return String(localized: "meal.other")
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

    /// 所属阈值分组（决定使用哪组正常范围）
    var thresholdGroup: ThresholdGroup {
        switch self {
        case .fasting, .beforeBreakfast, .beforeLunch, .beforeDinner:
            return .fasting
        case .afterBreakfast, .afterLunch, .afterDinner:
            return .postprandial
        case .bedtime:
            return .bedtime
        case .other:
            return .fasting  // 默认使用空腹/餐前标准
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
