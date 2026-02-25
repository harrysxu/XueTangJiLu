//
//  TagEngine.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation

/// 场景标签自动匹配引擎
/// 根据当前时间自动推断最可能的用餐场景标签，减少用户点击
struct TagEngine: Sendable {

    /// 时间段定义
    struct TimeSlot: Sendable {
        let start: Int  // 24小时制起始小时
        let end: Int    // 24小时制结束小时
        let tagId: String
    }

    /// 默认时间段配置（tagId 使用 MealContext.rawValue）
    nonisolated static let defaultSlots: [TimeSlot] = [
        TimeSlot(start: 5,  end: 8,  tagId: MealContext.beforeBreakfast.rawValue),
        TimeSlot(start: 8,  end: 10, tagId: MealContext.afterBreakfast.rawValue),
        TimeSlot(start: 10, end: 12, tagId: MealContext.beforeLunch.rawValue),
        TimeSlot(start: 12, end: 14, tagId: MealContext.afterLunch.rawValue),
        TimeSlot(start: 14, end: 17, tagId: MealContext.beforeDinner.rawValue),
        TimeSlot(start: 17, end: 20, tagId: MealContext.afterDinner.rawValue),
        TimeSlot(start: 20, end: 22, tagId: MealContext.bedtime.rawValue),
        TimeSlot(start: 22, end: 5,  tagId: MealContext.fasting.rawValue),
    ]

    /// 根据当前时间推断场景标签 ID
    nonisolated static func suggestTagId(for date: Date = .now) -> String {
        let hour = Calendar.current.component(.hour, from: date)

        for slot in defaultSlots {
            if slot.start <= slot.end {
                if hour >= slot.start && hour < slot.end {
                    return slot.tagId
                }
            } else {
                if hour >= slot.start || hour < slot.end {
                    return slot.tagId
                }
            }
        }
        return MealContext.other.rawValue
    }
}
