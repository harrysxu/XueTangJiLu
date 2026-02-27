//
//  MigrationPlan.swift
//  XueTangJiLu
//
//  SwiftData 迁移计划 - 处理 Schema 版本升级
//

import Foundation
import SwiftData

enum XueTangJiLuMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaVersions.self, SchemaVersionsV2.self, SchemaVersionsV3.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }
    
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaVersionsV2.self,
        toVersion: SchemaVersionsV3.self
    )
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaVersions.self,
        toVersion: SchemaVersionsV2.self,
        willMigrate: { context in
            // 迁移前处理（如果需要）
            print("📦 开始迁移 UserSettings: V1 -> V2")
        },
        didMigrate: { context in
            // 迁移后处理
            print("✅ UserSettings 迁移完成")
            
            // 执行旧版提醒配置迁移（从 LegacyReminderConfig 迁移到 ReminderConfig）
            let settingsDescriptor = FetchDescriptor<UserSettings>()
            if let settings = try? context.fetch(settingsDescriptor).first {
                // 调用迁移方法（如果 remindersData 是旧格式）
                if let data = settings.remindersData,
                   let oldReminders = try? JSONDecoder().decode([LegacyReminderConfig].self, from: data) {
                    
                    let mapping: [String: String] = [
                        "morning": MealContext.beforeBreakfast.rawValue,
                        "after_breakfast": MealContext.afterBreakfast.rawValue,
                        "before_lunch": MealContext.beforeLunch.rawValue,
                        "after_lunch": MealContext.afterLunch.rawValue,
                        "before_dinner": MealContext.beforeDinner.rawValue,
                        "after_dinner": MealContext.afterDinner.rawValue,
                        "bedtime": MealContext.bedtime.rawValue
                    ]
                    
                    let newReminders = oldReminders.compactMap { old -> ReminderConfig? in
                        guard let sceneTagId = mapping[old.id] else { return nil }
                        return ReminderConfig(
                            id: UUID().uuidString,
                            sceneTagId: sceneTagId,
                            hour: old.hour,
                            minute: old.minute,
                            isEnabled: old.isEnabled
                        )
                    }
                    
                    if let encoded = try? JSONEncoder().encode(newReminders) {
                        settings.remindersData = encoded
                        print("✅ 已迁移旧版提醒配置")
                    }
                }
                
                // 初始化本地化默认标签
                settings.initializeLocalizedDefaultTagsIfNeeded()
            }
        }
    )
}

/// 旧版提醒配置（用于迁移）
struct LegacyReminderConfig: Codable {
    let id: String
    var label: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool
}
