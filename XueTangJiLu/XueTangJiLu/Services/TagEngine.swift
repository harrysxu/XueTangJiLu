//
//  TagEngine.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation

/// 场景标签自动匹配引擎
/// 根据当前时间自动推断最可能的用餐场景标签，减少用户点击
struct TagEngine {

    /// 时间段定义
    struct TimeSlot {
        let start: Int  // 24小时制起始小时
        let end: Int    // 24小时制结束小时
        let context: MealContext
    }

    /// 默认时间段配置
    static let defaultSlots: [TimeSlot] = [
        TimeSlot(start: 5,  end: 8,  context: .beforeBreakfast),  // 05:00 - 07:59
        TimeSlot(start: 8,  end: 10, context: .afterBreakfast),   // 08:00 - 09:59
        TimeSlot(start: 10, end: 12, context: .beforeLunch),      // 10:00 - 11:59
        TimeSlot(start: 12, end: 14, context: .afterLunch),       // 12:00 - 13:59
        TimeSlot(start: 14, end: 17, context: .beforeDinner),     // 14:00 - 16:59
        TimeSlot(start: 17, end: 20, context: .afterDinner),      // 17:00 - 19:59
        TimeSlot(start: 20, end: 22, context: .bedtime),          // 20:00 - 21:59
        TimeSlot(start: 22, end: 5,  context: .fasting),          // 22:00 - 04:59
    ]

    /// 根据当前时间推断场景标签
    static func suggestContext(for date: Date = .now) -> MealContext {
        let hour = Calendar.current.component(.hour, from: date)

        for slot in defaultSlots {
            if slot.start <= slot.end {
                // 正常范围（如 5-8）
                if hour >= slot.start && hour < slot.end {
                    return slot.context
                }
            } else {
                // 跨午夜范围（如 22-5）
                if hour >= slot.start || hour < slot.end {
                    return slot.context
                }
            }
        }
        return .other
    }
}
