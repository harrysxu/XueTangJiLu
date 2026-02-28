//
//  MedicationViewModel.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import Foundation
import SwiftData
import Observation

/// 用药录入业务逻辑
@Observable
final class MedicationViewModel {

    // MARK: - 录入状态

    /// 选择的药物类型
    var selectedType: MedicationType = .rapidInsulin

    /// 药物名称
    var medicationName: String = ""

    /// 剂量输入文本
    var dosageText: String = ""

    /// 选择的日期时间
    var selectedDate: Date = .now

    /// 备注内容
    var noteText: String = ""

    /// 是否正在保存
    var isSaving: Bool = false

    /// 保存是否成功
    var saveSuccess: Bool = false

    /// 编辑模式：正在编辑的记录
    var editingRecord: MedicationRecord? = nil
    
    /// 是否处于编辑模式
    var isEditMode: Bool {
        editingRecord != nil
    }

    // MARK: - 计算属性

    /// 当前输入的剂量数值
    var dosageValue: Double? {
        Double(dosageText)
    }

    /// 保存按钮是否可用
    var isSaveEnabled: Bool {
        guard let value = dosageValue else { return false }
        return value > 0
    }

    // MARK: - 系统键盘输入校验

    func validateDosageInput(_ newValue: String) {
        var cleaned = newValue.filter { $0.isNumber || $0 == "." }

        let dots = cleaned.filter { $0 == "." }
        if dots.count > 1, let firstDot = cleaned.firstIndex(of: ".") {
            let afterDot = cleaned[cleaned.index(after: firstDot)...].filter { $0 != "." }
            cleaned = String(cleaned[...firstDot]) + afterDot
        }

        if let dotIndex = cleaned.firstIndex(of: ".") {
            let decimalPart = cleaned[cleaned.index(after: dotIndex)...]
            if decimalPart.count > 1 {
                cleaned = String(cleaned[...dotIndex]) + String(decimalPart.prefix(1))
            }
        }

        if cleaned != dosageText {
            dosageText = cleaned
        }
    }

    // MARK: - 键盘输入处理（保留供测试使用）

    func handleKeyPress(_ key: KeypadKey) {
        switch key {
        case .digit(let num):
            let newText = dosageText + "\(num)"
            // 限制小数点后1位
            if let dotIndex = newText.firstIndex(of: ".") {
                let decimalPlaces = newText.distance(from: newText.index(after: dotIndex), to: newText.endIndex)
                if decimalPlaces > 1 { return }
            }
            if dosageText == "0" && num != 0 {
                dosageText = "\(num)"
            } else {
                dosageText = newText
            }
        case .decimal:
            guard !dosageText.contains(".") else { return }
            dosageText = dosageText.isEmpty ? "0." : dosageText + "."
        case .delete:
            guard !dosageText.isEmpty else { return }
            dosageText.removeLast()
        }
    }

    // MARK: - 保存记录

    func saveRecord(modelContext: ModelContext) {
        guard let dosage = dosageValue, dosage > 0 else { return }

        isSaving = true

        if let existingRecord = editingRecord {
            // 编辑模式：更新现有记录
            existingRecord.medicationType = selectedType
            existingRecord.name = medicationName
            existingRecord.dosage = dosage
            existingRecord.timestamp = selectedDate
            existingRecord.note = noteText.isEmpty ? nil : noteText
        } else {
            // 新建模式：创建新记录
            let record = MedicationRecord(
                medicationType: selectedType,
                name: medicationName,
                dosage: dosage,
                timestamp: selectedDate,
                note: noteText.isEmpty ? nil : noteText
            )
            modelContext.insert(record)
        }

        HapticManager.success()
        saveSuccess = true
        isSaving = false

        resetInput()
    }

    /// 删除记录
    func deleteRecord(_ record: MedicationRecord, modelContext: ModelContext) {
        HapticManager.warning()
        modelContext.delete(record)
    }

    /// 重置输入状态
    func resetInput() {
        selectedType = .rapidInsulin
        medicationName = ""
        dosageText = ""
        selectedDate = .now
        noteText = ""
        editingRecord = nil
    }
    
    /// 加载记录进行编辑
    func loadRecordForEditing(_ record: MedicationRecord) {
        editingRecord = record
        selectedType = record.medicationType
        medicationName = record.name
        dosageText = String(format: "%.1f", record.dosage).replacingOccurrences(of: ".0", with: "")
        selectedDate = record.timestamp
        noteText = record.note ?? ""
    }
}
