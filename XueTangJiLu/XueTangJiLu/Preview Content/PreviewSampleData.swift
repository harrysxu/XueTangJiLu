//
//  PreviewSampleData.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import SwiftData

/// SwiftUI Preview 用样本数据
enum PreviewSampleData {

    /// 创建预览用的血糖记录数组
    static var sampleRecords: [GlucoseRecord] {
        let calendar = Calendar.current
        let now = Date.now

        return [
            // 今日记录
            GlucoseRecord(
                value: 5.6,
                timestamp: calendar.date(byAdding: .minute, value: -20, to: now)!,
                mealContext: .beforeBreakfast
            ),
            GlucoseRecord(
                value: 6.5,
                timestamp: calendar.date(byAdding: .hour, value: -2, to: now)!,
                mealContext: .afterBreakfast
            ),
            GlucoseRecord(
                value: 5.8,
                timestamp: calendar.date(byAdding: .hour, value: -4, to: now)!,
                mealContext: .beforeLunch
            ),
            GlucoseRecord(
                value: 7.2,
                timestamp: calendar.date(byAdding: .hour, value: -6, to: now)!,
                mealContext: .afterLunch,
                note: "吃了火锅"
            ),

            // 昨日记录
            GlucoseRecord(
                value: 5.2,
                timestamp: calendar.date(byAdding: .day, value: -1, to: now)!,
                mealContext: .fasting
            ),
            GlucoseRecord(
                value: 6.8,
                timestamp: calendar.date(bySettingHour: 8, minute: 30, second: 0,
                                        of: calendar.date(byAdding: .day, value: -1, to: now)!)!,
                mealContext: .afterBreakfast
            ),
            GlucoseRecord(
                value: 8.1,
                timestamp: calendar.date(bySettingHour: 12, minute: 30, second: 0,
                                        of: calendar.date(byAdding: .day, value: -1, to: now)!)!,
                mealContext: .afterLunch
            ),
            GlucoseRecord(
                value: 5.5,
                timestamp: calendar.date(bySettingHour: 18, minute: 0, second: 0,
                                        of: calendar.date(byAdding: .day, value: -1, to: now)!)!,
                mealContext: .beforeDinner
            ),

            // 前几天的记录
            GlucoseRecord(
                value: 4.8,
                timestamp: calendar.date(byAdding: .day, value: -2, to: now)!,
                mealContext: .fasting
            ),
            GlucoseRecord(
                value: 7.5,
                timestamp: calendar.date(byAdding: .day, value: -2, to: now)!,
                mealContext: .afterLunch
            ),
            GlucoseRecord(
                value: 6.2,
                timestamp: calendar.date(byAdding: .day, value: -3, to: now)!,
                mealContext: .beforeBreakfast
            ),
            GlucoseRecord(
                value: 3.5,
                timestamp: calendar.date(byAdding: .day, value: -3, to: now)!,
                mealContext: .fasting
            ),
            GlucoseRecord(
                value: 9.8,
                timestamp: calendar.date(byAdding: .day, value: -4, to: now)!,
                mealContext: .afterDinner,
                note: "聚餐吃多了"
            ),
            GlucoseRecord(
                value: 5.9,
                timestamp: calendar.date(byAdding: .day, value: -5, to: now)!,
                mealContext: .beforeLunch
            ),
            GlucoseRecord(
                value: 6.7,
                timestamp: calendar.date(byAdding: .day, value: -6, to: now)!,
                mealContext: .afterBreakfast
            ),
        ]
    }

    /// 创建预览用的用户设置
    static var sampleSettings: UserSettings {
        let settings = UserSettings()
        settings.hasCompletedOnboarding = true
        settings.preferredUnit = .mmolL
        return settings
    }

    /// 创建包含样本数据的 ModelContainer（用于 Preview）
    @MainActor
    static var previewContainer: ModelContainer {
        let schema = Schema([
            GlucoseRecord.self,
            UserSettings.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = container.mainContext

            // 插入样本记录
            for record in sampleRecords {
                context.insert(record)
            }

            // 插入设置
            context.insert(sampleSettings)

            return container
        } catch {
            fatalError("无法创建预览 ModelContainer: \(error)")
        }
    }
}
