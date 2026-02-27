//
//  SchemaVersions.swift
//  XueTangJiLu
//
//  Schema 版本管理 - 用于 SwiftData 迁移
//

import Foundation
import SwiftData

enum SchemaVersions: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            UserSettingsV1.self,
            GlucoseRecord.self,
            MedicationRecord.self,
            MealRecord.self
        ]
    }
    
    /// V1 版本的 UserSettings（包含废弃属性）
    @Model
    final class UserSettingsV1 {
        var preferredUnitRawValue: String = GlucoseUnit.systemDefault.rawValue
        var targetLow: Double = 3.9
        var targetHigh: Double = 10.0
        var hasCompletedOnboarding: Bool = false
        var healthKitSyncEnabled: Bool = false
        var autoTagEnabled: Bool = true
        var remindersData: Data?
        var inactivityReminderHours: Int = 0
        var dailyRecordGoal: Int = 4
        var annotationTagsData: Data?
        var thresholdConfigData: Data?
        var sceneTagsData: Data?
        var hasSeenDisclaimer: Bool = false
        var displayModeRawValue: String = "simple"
        var lastModified: Date = Date.now
        var deviceIdentifier: String?
        
        init() {}
    }
    
    /// V1 版本的 MealRecord（photoData 无 externalStorage）
    @Model
    final class MealRecord {
        var carbLevelRawValue: String = "medium_carb"
        var mealDescription: String = ""
        var photoData: Data?
        var timestamp: Date = Date.now
        var note: String?
        var createdAt: Date = Date.now
        var deviceIdentifier: String?
        init() {}
    }
}

enum SchemaVersionsV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            UserSettings.self,
            GlucoseRecord.self,
            MedicationRecord.self,
            MealRecord.self
        ]
    }
    
    /// V2 版本的 MealRecord（photoData 无 externalStorage）
    @Model
    final class MealRecord {
        var carbLevelRawValue: String = "medium_carb"
        var mealDescription: String = ""
        var photoData: Data?
        var timestamp: Date = Date.now
        var note: String?
        var createdAt: Date = Date.now
        var deviceIdentifier: String?
        init() {}
    }
}

enum SchemaVersionsV3: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(3, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            UserSettings.self,
            GlucoseRecord.self,
            MedicationRecord.self,
            // 使用顶层 MealRecord（含 @Attribute(.externalStorage)）
            XueTangJiLu.MealRecord.self
        ]
    }
}
