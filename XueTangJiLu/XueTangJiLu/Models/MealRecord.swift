//
//  MealRecord.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

/// 碳水水平
enum CarbLevel: String, Codable, CaseIterable {
    case low = "low_carb"
    case medium = "medium_carb"
    case high = "high_carb"

    var displayName: String {
        switch self {
        case .low:    return "低碳水"
        case .medium: return "中碳水"
        case .high:   return "高碳水"
        }
    }
    
    /// 本地化的显示名称
    var localizedDisplayName: String {
        switch self {
        case .low:    return String(localized: "meal.carb_low")
        case .medium: return String(localized: "meal.carb_medium")
        case .high:   return String(localized: "meal.carb_high")
        }
    }

    var iconName: String {
        switch self {
        case .low:    return "leaf.fill"
        case .medium: return "fork.knife"
        case .high:   return "takeoutbag.and.cup.and.straw.fill"
        }
    }

    var colorName: String {
        switch self {
        case .low:    return "GlucoseNormal"
        case .medium: return "GlucoseHigh"
        case .high:   return "GlucoseVeryHigh"
        }
    }
}

/// 饮食记录数据模型
@Model
final class MealRecord {

    // MARK: - 核心数据

    /// 碳水水平
    var carbLevelRawValue: String = CarbLevel.medium.rawValue

    /// 饮食描述
    var mealDescription: String = ""

    /// 照片数据（JPEG compressed）
    var photoData: Data?

    /// 记录时间
    var timestamp: Date = Date.now

    /// 备注
    var note: String?

    /// 创建时间
    var createdAt: Date = Date.now
    
    /// 设备标识符（用于多设备冲突检测）
    var deviceIdentifier: String?

    // MARK: - 计算属性

    var carbLevel: CarbLevel {
        get { CarbLevel(rawValue: carbLevelRawValue) ?? .medium }
        set { carbLevelRawValue = newValue.rawValue }
    }

    /// 是否有照片
    var hasPhoto: Bool {
        photoData != nil
    }

    // MARK: - 初始化

    init(
        carbLevel: CarbLevel = .medium,
        mealDescription: String = "",
        photoData: Data? = nil,
        timestamp: Date = .now,
        note: String? = nil
    ) {
        self.carbLevelRawValue = carbLevel.rawValue
        self.mealDescription = mealDescription
        self.photoData = photoData
        self.timestamp = timestamp
        self.note = note
        self.createdAt = .now
        #if canImport(UIKit)
        self.deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString
        #endif
    }
}

// MARK: - Conflict Resolution

extension MealRecord {
    
    /// 判断是否与另一条记录重复
    func isDuplicate(of other: MealRecord) -> Bool {
        // 时间相近、描述相同，则可能重复
        return abs(timestamp.timeIntervalSince(other.timestamp)) < 60.0 &&
               mealDescription == other.mealDescription &&
               carbLevel == other.carbLevel
    }
    
    /// 在冲突时选择应该保留的记录
    static func resolveConflict(between record1: MealRecord, and record2: MealRecord) -> MealRecord {
        // 优先保留有照片的记录
        if record1.hasPhoto && !record2.hasPhoto {
            return record1
        } else if record2.hasPhoto && !record1.hasPhoto {
            return record2
        }
        // 都有或都没有照片，保留创建时间更早的
        return record1.createdAt < record2.createdAt ? record1 : record2
    }
}
