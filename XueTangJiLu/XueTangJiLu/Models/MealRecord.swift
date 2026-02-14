//
//  MealRecord.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import Foundation
import SwiftData

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
    }
}
