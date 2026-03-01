//
//  SchemaVersions.swift
//  XueTangJiLu
//
//  Schema 版本管理 - 用于 SwiftData 迁移
//  当前仅有一个版本，未来需要变更 schema 时在此添加新版本
//

import Foundation
import SwiftData

// MARK: - V4: 当前版本

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
