//
//  SchemaVersions.swift
//  XueTangJiLu
//
//  Schema 版本管理 - 用于 SwiftData 迁移
//

import Foundation
import SwiftData

// MARK: - V3: 基础版本（无照片）

enum SchemaVersionsV3: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(3, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            UserSettings.self,
            GlucoseRecord.self,
            MedicationRecord.self,
            SchemaVersionsV3.MealRecordV3.self
        ]
    }
    
    @Model
    final class MealRecordV3 {
        var carbLevelRawValue: String = CarbLevel.medium.rawValue
        var mealDescription: String = ""
        var timestamp: Date = Date.now
        var note: String?
        var createdAt: Date = Date.now
        var deviceIdentifier: String?
        
        init() {}
    }
}

// MARK: - V4: 添加饮食照片

enum SchemaVersionsV4: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(4, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            UserSettings.self,
            GlucoseRecord.self,
            MedicationRecord.self,
            MealRecord.self
        ]
    }
}
