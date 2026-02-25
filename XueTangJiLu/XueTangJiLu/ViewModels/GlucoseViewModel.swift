//
//  GlucoseViewModel.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import SwiftData
import Observation

/// 血糖录入/列表/删除业务逻辑
@Observable
final class GlucoseViewModel {

    // MARK: - 录入状态

    /// 当前输入的文本
    var inputText: String = ""

    /// 选择的场景标签 ID（支持内置和自定义标签）
    var selectedSceneTagId: String = TagEngine.suggestTagId()

    /// 选择的日期时间
    var selectedDate: Date = .now

    /// 备注内容
    var noteText: String = ""

    /// 是否显示备注输入框
    var showNoteField: Bool = false

    /// 是否正在保存
    var isSaving: Bool = false

    /// 保存是否成功（用于动画）
    var saveSuccess: Bool = false

    /// 编辑模式：正在编辑的记录
    var editingRecord: GlucoseRecord? = nil
    
    /// 是否处于编辑模式
    var isEditMode: Bool {
        editingRecord != nil
    }

    // MARK: - 计算属性

    /// 当前输入的数值
    var inputValue: Double? {
        Double(inputText)
    }

    /// 当前输入值的血糖等级（通用固定阈值）
    func currentLevel(unit: GlucoseUnit) -> GlucoseLevel? {
        guard let mmolL = normalizedValue(unit: unit) else { return nil }
        return GlucoseLevel.from(value: mmolL)
    }

    /// 当前输入值的血糖等级（场景感知，基于 sceneTagId）
    func currentLevel(unit: GlucoseUnit, settings: UserSettings) -> GlucoseLevel? {
        guard let mmolL = normalizedValue(unit: unit) else { return nil }
        return GlucoseLevel.from(value: mmolL, tagId: selectedSceneTagId, settings: settings)
    }

    /// 保存按钮是否可用
    func isSaveEnabled(unit: GlucoseUnit) -> Bool {
        guard let value = inputValue else { return false }
        return value >= unit.minValue && value <= unit.maxValue
    }

    /// 获取内部存储的 mmol/L 值
    func normalizedValue(unit: GlucoseUnit) -> Double? {
        guard let value = inputValue else { return nil }
        return GlucoseUnitConverter.normalize(value: value, preferredUnit: unit)
    }

    // MARK: - 键盘输入处理

    func handleKeyPress(_ key: KeypadKey, unit: GlucoseUnit) {
        switch key {
        case .digit(let num):
            handleDigit(num, unit: unit)
        case .decimal:
            handleDecimal(unit: unit)
        case .delete:
            handleDelete()
        }
    }

    private func handleDigit(_ num: Int, unit: GlucoseUnit) {
        let newText = inputText + "\(num)"

        if let dotIndex = newText.firstIndex(of: ".") {
            let decimalPlaces = newText.distance(from: newText.index(after: dotIndex), to: newText.endIndex)
            if decimalPlaces > unit.maxDecimalPlaces {
                return
            }
        }

        if inputText == "0" && num != 0 {
            inputText = "\(num)"
        } else {
            inputText = newText
        }
    }

    private func handleDecimal(unit: GlucoseUnit) {
        guard unit.maxDecimalPlaces > 0 else { return }
        guard !inputText.contains(".") else { return }

        if inputText.isEmpty {
            inputText = "0."
        } else {
            inputText += "."
        }
    }

    private func handleDelete() {
        guard !inputText.isEmpty else { return }
        inputText.removeLast()
    }

    // MARK: - 保存记录

    func saveRecord(
        modelContext: ModelContext,
        unit: GlucoseUnit,
        healthKitManager: HealthKitManager?,
        healthKitEnabled: Bool
    ) async {
        guard let mmolLValue = normalizedValue(unit: unit) else { return }

        isSaving = true
        defer { isSaving = false }

        if let existingRecord = editingRecord {
            // 编辑模式：更新现有记录
            existingRecord.value = mmolLValue
            existingRecord.timestamp = selectedDate
            existingRecord.sceneTagId = selectedSceneTagId
            existingRecord.note = noteText.isEmpty ? nil : noteText
            
            // 如果启用了 HealthKit，更新同步状态
            if healthKitEnabled, let hkManager = healthKitManager {
                do {
                    try await hkManager.saveGlucose(
                        value: mmolLValue,
                        date: selectedDate,
                        sceneTagId: selectedSceneTagId
                    )
                    existingRecord.syncedToHealthKit = true
                } catch {
                    print("HealthKit 同步失败: \(error)")
                }
            }
        } else {
            // 新建模式：创建新记录
            let record = GlucoseRecord(
                value: mmolLValue,
                timestamp: selectedDate,
                sceneTagId: selectedSceneTagId,
                note: noteText.isEmpty ? nil : noteText
            )

            modelContext.insert(record)

            // 同步到 HealthKit
            if healthKitEnabled, let hkManager = healthKitManager {
                do {
                    try await hkManager.saveGlucose(
                        value: mmolLValue,
                        date: selectedDate,
                        sceneTagId: selectedSceneTagId
                    )
                    record.syncedToHealthKit = true
                } catch {
                    print("HealthKit 同步失败: \(error)")
                }
            }
        }

        HapticManager.success()
        saveSuccess = true

        resetInput()
    }

    /// 删除记录
    func deleteRecord(_ record: GlucoseRecord, modelContext: ModelContext) {
        HapticManager.warning()
        modelContext.delete(record)
    }

    /// 重置输入状态
    func resetInput() {
        inputText = ""
        selectedSceneTagId = TagEngine.suggestTagId()
        selectedDate = .now
        noteText = ""
        showNoteField = false
        editingRecord = nil
    }
    
    /// 加载记录进行编辑
    func loadRecordForEditing(_ record: GlucoseRecord, unit: GlucoseUnit) {
        editingRecord = record
        inputText = record.displayValue(in: unit)
        selectedSceneTagId = record.sceneTagId
        selectedDate = record.timestamp
        noteText = record.note ?? ""
        showNoteField = record.note != nil && !record.note!.isEmpty
    }
}

/// 键盘按键类型
enum KeypadKey {
    case digit(Int)
    case decimal
    case delete
}
