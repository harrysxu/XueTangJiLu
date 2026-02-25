//
//  GlucoseRecord.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

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

    /// 场景标签 ID（内置标签存 MealContext.rawValue，自定义标签存 UUID）
    var sceneTagId: String = MealContext.other.rawValue

    /// 用户备注（如"吃了火锅"、"运动后"）
    var note: String?

    /// 数据来源标识（区分手动录入 vs HealthKit 导入）
    var source: String = "manual"

    /// 是否已同步到 HealthKit
    var syncedToHealthKit: Bool = false

    /// 创建时间（用于 CloudKit 冲突解决）
    var createdAt: Date = Date.now
    
    /// 设备标识符（用于多设备冲突检测，可选）
    var deviceIdentifier: String?

    // MARK: - 计算属性

    /// 获取完整的 SceneTag 信息
    func sceneTag(from settings: UserSettings) -> SceneTag? {
        settings.sceneTag(for: sceneTagId)
    }

    /// 获取所属 ThresholdGroup（用于分组分析）
    func thresholdGroup(from settings: UserSettings) -> ThresholdGroup {
        settings.thresholdGroup(for: sceneTagId)
    }

    /// 对应的内置 MealContext（仅用于 HealthKit 映射，自定义标签返回 nil）
    var builtInMealContext: MealContext? {
        MealContext(rawValue: sceneTagId)
    }

    /// 将内部 mmol/L 值转换为 mg/dL
    var valueInMgDL: Double {
        value * 18.0182
    }

    /// 血糖状态判定（基于通用固定范围，用于无 settings 的场景如 Widget）
    var glucoseLevel: GlucoseLevel {
        GlucoseLevel.from(value: value)
    }

    /// 血糖状态判定（场景感知，使用用户的分场景阈值设置）
    func glucoseLevel(with settings: UserSettings) -> GlucoseLevel {
        GlucoseLevel.from(value: value, tagId: sceneTagId, settings: settings)
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
         sceneTagId: String = MealContext.other.rawValue,
         note: String? = nil,
         source: String = "manual") {
        self.value = value
        self.timestamp = timestamp
        self.sceneTagId = sceneTagId
        self.note = note
        self.source = source
        self.createdAt = .now
        #if canImport(UIKit)
        self.deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString
        #endif
    }
}

// MARK: - Conflict Resolution

extension GlucoseRecord {
    
    /// 生成用于去重的唯一键
    var deduplicationKey: String {
        "\(timestamp.timeIntervalSince1970)_\(value)_\(sceneTagId)"
    }
    
    /// 判断是否与另一条记录重复
    func isDuplicate(of other: GlucoseRecord) -> Bool {
        // 时间相同、数值相同、场景相同，则视为重复
        return abs(timestamp.timeIntervalSince(other.timestamp)) < 1.0 &&
               abs(value - other.value) < 0.01 &&
               sceneTagId == other.sceneTagId
    }
    
    /// 在冲突时选择应该保留的记录
    static func resolveConflict(between record1: GlucoseRecord, and record2: GlucoseRecord) -> GlucoseRecord {
        // 优先保留创建时间更早的记录
        return record1.createdAt < record2.createdAt ? record1 : record2
    }
}
