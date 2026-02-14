//
//  UserSettings.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import SwiftData

// MARK: - 提醒配置模型（需要对 Widget 可见，因此定义在此）

/// 单条提醒配置
struct ReminderConfig: Identifiable, Codable, Equatable {
    let id: String
    var label: String       // 如"早餐前"、"午餐后"
    var hour: Int           // 0-23
    var minute: Int         // 0-59
    var isEnabled: Bool

    /// 格式化的时间显示
    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// 默认提醒配置列表
    static let defaults: [ReminderConfig] = [
        ReminderConfig(id: "morning", label: "早餐前", hour: 7, minute: 0, isEnabled: false),
        ReminderConfig(id: "after_breakfast", label: "早餐后", hour: 9, minute: 30, isEnabled: false),
        ReminderConfig(id: "before_lunch", label: "午餐前", hour: 11, minute: 30, isEnabled: false),
        ReminderConfig(id: "after_lunch", label: "午餐后", hour: 14, minute: 0, isEnabled: false),
        ReminderConfig(id: "before_dinner", label: "晚餐前", hour: 17, minute: 30, isEnabled: false),
        ReminderConfig(id: "after_dinner", label: "晚餐后", hour: 20, minute: 0, isEnabled: false),
        ReminderConfig(id: "bedtime", label: "睡前", hour: 22, minute: 0, isEnabled: false),
    ]
}

/// 用户设置模型
@Model
final class UserSettings {

    /// 首选血糖单位
    var preferredUnitRawValue: String = GlucoseUnit.systemDefault.rawValue

    /// 目标血糖下限 (mmol/L)
    var targetLow: Double = 3.9

    /// 目标血糖上限 (mmol/L)
    var targetHigh: Double = 10.0

    /// 是否已完成引导
    var hasCompletedOnboarding: Bool = false

    /// 是否启用 HealthKit 同步
    var healthKitSyncEnabled: Bool = false

    /// 是否启用智能标签
    var autoTagEnabled: Bool = true

    // MARK: - 提醒设置

    /// 提醒配置 JSON 数据
    var remindersData: Data?

    /// 久未记录提醒间隔（小时），0 表示关闭
    var inactivityReminderHours: Int = 0

    // MARK: - 目标设置

    /// A1C 目标值 (%)
    var targetA1C: Double = 7.0

    /// 每日记录目标次数
    var dailyRecordGoal: Int = 4

    // MARK: - 计算属性

    var preferredUnit: GlucoseUnit {
        get { GlucoseUnit(rawValue: preferredUnitRawValue) ?? .mmolL }
        set { preferredUnitRawValue = newValue.rawValue }
    }

    /// 获取提醒配置列表
    var reminderConfigs: [ReminderConfig] {
        guard let data = remindersData,
              let decoded = try? JSONDecoder().decode([ReminderConfig].self, from: data) else {
            return ReminderConfig.defaults
        }
        return decoded
    }

    init() {}
}
