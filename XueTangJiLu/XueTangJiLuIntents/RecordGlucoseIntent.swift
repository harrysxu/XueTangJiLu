//
//  RecordGlucoseIntent.swift
//  XueTangJiLuIntents
//
//  Created by XueTangJiLu on 2026/2/14.
//

import AppIntents
import SwiftData
import WidgetKit

/// Siri 语音录入 Intent - "用学糖记录记录血糖"
struct RecordGlucoseIntent: AppIntent {
    static var title: LocalizedStringResource = "记录血糖"
    static var description = IntentDescription("快速记录一次血糖数值")
    static var openAppWhenRun = false

    @Parameter(title: "血糖值", description: "血糖数值（mmol/L 或 mg/dL）")
    var glucoseValue: Double

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 从 App Groups 共享容器读取设置
        let schema = Schema([GlucoseRecord.self, UserSettings.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppConstants.appGroupID),
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // 读取用户偏好单位
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        let settings = try context.fetch(settingsDescriptor).first
        let preferredUnit = settings?.preferredUnit ?? .mmolL

        // 将输入值标准化为 mmol/L
        let mmolLValue = GlucoseUnitConverter.normalize(
            value: glucoseValue,
            preferredUnit: preferredUnit
        )

        // 自动推断用餐场景
        let mealContext = TagEngine.suggestContext()

        // 创建记录
        let record = GlucoseRecord(
            value: mmolLValue,
            timestamp: .now,
            mealContext: mealContext,
            note: nil,
            source: "siri"
        )

        context.insert(record)
        try context.save()

        // 刷新 Widget
        WidgetCenter.shared.reloadAllTimelines()

        // 返回确认对话
        let displayValue = GlucoseUnitConverter.displayString(
            mmolLValue: mmolLValue,
            in: preferredUnit
        )

        return .result(
            dialog: "已记录血糖 \(displayValue) \(preferredUnit.rawValue)（\(mealContext.displayName)）"
        )
    }
}

/// Siri 快捷短语定义
struct RecordGlucoseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordGlucoseIntent(),
            phrases: [
                "用\(.applicationName)记录血糖",
                "记录血糖 \(\.$glucoseValue)",
                "\(.applicationName)记录 \(\.$glucoseValue)",
            ],
            shortTitle: "记录血糖",
            systemImageName: "drop.fill"
        )
    }
}
