//
//  MedicationRecord.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import Foundation
import SwiftData

/// 胰岛素/药物类型
enum MedicationType: String, Codable, CaseIterable {
    case rapidInsulin = "rapid_insulin"       // 速效胰岛素
    case longInsulin = "long_insulin"         // 长效胰岛素
    case mixedInsulin = "mixed_insulin"       // 预混胰岛素
    case oralMedicine = "oral_medicine"       // 口服降糖药
    case other = "other_med"                  // 其他

    /// 本地化显示名称
    var displayName: String {
        switch self {
        case .rapidInsulin:  return "速效胰岛素"
        case .longInsulin:   return "长效胰岛素"
        case .mixedInsulin:  return "预混胰岛素"
        case .oralMedicine:  return "口服药物"
        case .other:         return "其他"
        }
    }

    /// SF Symbol 图标名
    var iconName: String {
        switch self {
        case .rapidInsulin:  return "syringe.fill"
        case .longInsulin:   return "syringe"
        case .mixedInsulin:  return "cross.vial.fill"
        case .oralMedicine:  return "pills.fill"
        case .other:         return "cross.case.fill"
        }
    }

    /// 单位
    var unitLabel: String {
        switch self {
        case .rapidInsulin, .longInsulin, .mixedInsulin:
            return "单位(U)"
        case .oralMedicine, .other:
            return "mg"
        }
    }
}

/// 用药记录数据模型
@Model
final class MedicationRecord {

    // MARK: - 核心数据

    /// 药物类型
    var medicationTypeRawValue: String = MedicationType.rapidInsulin.rawValue

    /// 药物名称（用户自定义，如"诺和锐"）
    var name: String = ""

    /// 剂量
    var dosage: Double = 0.0

    /// 记录时间
    var timestamp: Date = Date.now

    /// 备注
    var note: String?

    /// 创建时间
    var createdAt: Date = Date.now

    // MARK: - 计算属性

    var medicationType: MedicationType {
        get { MedicationType(rawValue: medicationTypeRawValue) ?? .rapidInsulin }
        set { medicationTypeRawValue = newValue.rawValue }
    }

    /// 格式化显示剂量
    var displayDosage: String {
        if dosage == Double(Int(dosage)) {
            return "\(Int(dosage)) \(medicationType.unitLabel)"
        }
        return String(format: "%.1f %@", dosage, medicationType.unitLabel)
    }

    // MARK: - 初始化

    init(
        medicationType: MedicationType = .rapidInsulin,
        name: String = "",
        dosage: Double,
        timestamp: Date = .now,
        note: String? = nil
    ) {
        self.medicationTypeRawValue = medicationType.rawValue
        self.name = name
        self.dosage = dosage
        self.timestamp = timestamp
        self.note = note
        self.createdAt = .now
    }
}
