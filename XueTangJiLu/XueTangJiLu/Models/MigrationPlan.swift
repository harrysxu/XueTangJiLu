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
        [
            SchemaVersionsV3.self,
            SchemaVersionsV4.self
        ]
    }
    
    static var stages: [MigrationStage] {
        [migrateV3toV4]
    }
    
    /// V3→V4: 为 MealRecord 添加 photoData 字段（可选字段，轻量迁移即可）
    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaVersionsV3.self,
        toVersion: SchemaVersionsV4.self
    )
}
