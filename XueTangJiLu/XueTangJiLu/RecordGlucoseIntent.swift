//
//  RecordGlucoseIntent.swift
//  XueTangJiLuIntents
//
//  Created by XueTangJiLu on 2026/2/14.
//

import AppIntents
import SwiftData
import WidgetKit

/// Siri 语音录入 Intent - "用血糖记录记录血糖"
struct RecordGlucoseIntent: AppIntent {
    static var title: LocalizedStringResource = "quick.glucose"
    static var description = IntentDescription("intent.glucose.description")
    static var openAppWhenRun = false

    @Parameter(title: "intent.glucose.param.value", description: "intent.glucose.description")
    var glucoseValue: Double

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 从 App Groups 共享容器读取设置
        let schema = Schema([GlucoseRecord.self, UserSettings.self])
        let appGroupID = AppConstants.appGroupID // 先获取
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupID),
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

        // 自动推断场景标签
        let sceneTagId = TagEngine.suggestTagId()
        
        // 获取显示名称（避免在非隔离上下文中访问计算属性）
        let tagDisplayName: String
        if let settings {
            tagDisplayName = settings.displayName(for: sceneTagId)
        } else {
            // 使用本地化映射
            if let context = MealContext(rawValue: sceneTagId) {
                tagDisplayName = context.localizedDisplayName
            } else {
                tagDisplayName = String(localized: "meal.other")
            }
        }

        // 创建记录
        let record = GlucoseRecord(
            value: mmolLValue,
            timestamp: .now,
            sceneTagId: sceneTagId,
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
            dialog: IntentDialog(stringLiteral: String(localized: "intent.glucose.success", 
                                                       defaultValue: "已记录血糖 \(displayValue) \(preferredUnit.rawValue)（\(tagDisplayName)）"))
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
                "\(.applicationName)记录血糖",
                "在\(.applicationName)中记录血糖",
            ],
            shortTitle: LocalizedStringResource("quick.glucose"),
            systemImageName: "drop.fill"
        )
    }
}
