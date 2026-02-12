//
//  GlucoseRecord.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import SwiftData

/// 血糖记录数据模型
/// 遵循 CloudKit 同步规则：所有属性均为 Optional 或提供默认值，无 unique 约束
@Model
final class GlucoseRecord {

    // MARK: - 核心数据

    /// 血糖数值（以 mmol/L 为内部统一存储单位）
    var value: Double = 0.0

    /// 记录时间戳
    var timestamp: Date = Date.now

    // MARK: - 元数据

    /// 用餐场景（餐前/餐后/空腹/睡前/其他）
    /// 使用 rawValue 字符串存储以兼容 CloudKit
    var mealContextRawValue: String = MealContext.other.rawValue

    /// 用户备注（如"吃了火锅"、"运动后"）
    var note: String?

    /// 数据来源标识（区分手动录入 vs HealthKit 导入）
    var source: String = "manual"

    /// 是否已同步到 HealthKit
    var syncedToHealthKit: Bool = false

    /// 创建时间（用于 CloudKit 冲突解决）
    var createdAt: Date = Date.now

    // MARK: - 计算属性

    /// 用餐场景枚举转换
    var mealContext: MealContext {
        get { MealContext(rawValue: mealContextRawValue) ?? .other }
        set { mealContextRawValue = newValue.rawValue }
    }

    /// 将内部 mmol/L 值转换为 mg/dL
    var valueInMgDL: Double {
        value * 18.0182
    }

    /// 血糖状态判定（基于通用范围）
    var glucoseLevel: GlucoseLevel {
        GlucoseLevel.from(value: value)
    }

    /// 格式化显示值
    func displayValue(in unit: GlucoseUnit) -> String {
        switch unit {
        case .mmolL:
            return String(format: "%.1f", value)
        case .mgdL:
            return String(format: "%.0f", valueInMgDL)
        }
    }

    // MARK: - 初始化

    init(value: Double,
         timestamp: Date = .now,
         mealContext: MealContext = .other,
         note: String? = nil,
         source: String = "manual") {
        self.value = value
        self.timestamp = timestamp
        self.mealContextRawValue = mealContext.rawValue
        self.note = note
        self.source = source
        self.createdAt = .now
    }
}
