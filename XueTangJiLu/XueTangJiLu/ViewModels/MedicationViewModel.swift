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

    // MARK: - 键盘输入处理

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

        let record = MedicationRecord(
            medicationType: selectedType,
            name: medicationName,
            dosage: dosage,
            timestamp: selectedDate,
            note: noteText.isEmpty ? nil : noteText
        )

        modelContext.insert(record)
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
    }
}
