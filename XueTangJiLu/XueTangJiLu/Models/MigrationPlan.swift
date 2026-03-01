//
//  MigrationPlan.swift
//  XueTangJiLu
//
//  SwiftData 迁移计划
//  当前仅有一个版本，无需迁移。未来新增版本时在此添加迁移阶段。
//

import Foundation
import SwiftData

enum XueTangJiLuMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaVersionsV4.self
        ]
    }
    
    static var stages: [MigrationStage] {
        []
    }
}
