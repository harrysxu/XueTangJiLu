//
//  UserSettings.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import SwiftData

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

    // MARK: - 计算属性

    var preferredUnit: GlucoseUnit {
        get { GlucoseUnit(rawValue: preferredUnitRawValue) ?? .mmolL }
        set { preferredUnitRawValue = newValue.rawValue }
    }

    init() {}
}
