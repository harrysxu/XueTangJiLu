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

    /// 选择的用餐场景
    var selectedMealContext: MealContext = TagEngine.suggestContext()

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

    // MARK: - 计算属性

    /// 当前输入的数值
    var inputValue: Double? {
        Double(inputText)
    }

    /// 当前输入值的血糖等级（需传入单位以正确转换）
    func currentLevel(unit: GlucoseUnit) -> GlucoseLevel? {
        guard let mmolL = normalizedValue(unit: unit) else { return nil }
        return GlucoseLevel.from(value: mmolL)
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

        // 检查小数位数限制
        if let dotIndex = newText.firstIndex(of: ".") {
            let decimalPlaces = newText.distance(from: newText.index(after: dotIndex), to: newText.endIndex)
            if decimalPlaces > unit.maxDecimalPlaces {
                return  // 忽略超过位数的输入
            }
        }

        // 去除前导零（但保留 "0." 的情况）
        if inputText == "0" && num != 0 {
            inputText = "\(num)"
        } else {
            inputText = newText
        }
    }

    private func handleDecimal(unit: GlucoseUnit) {
        // mg/dL 不允许小数
        guard unit.maxDecimalPlaces > 0 else { return }
        // 已有小数点则忽略
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

        // 创建记录
        let record = GlucoseRecord(
            value: mmolLValue,
            timestamp: selectedDate,
            mealContext: selectedMealContext,
            note: noteText.isEmpty ? nil : noteText
        )

        modelContext.insert(record)

        // 同步到 HealthKit
        if healthKitEnabled, let hkManager = healthKitManager {
            do {
                try await hkManager.saveGlucose(
                    value: mmolLValue,
                    date: selectedDate,
                    mealContext: selectedMealContext
                )
                record.syncedToHealthKit = true
            } catch {
                // HealthKit 同步失败不影响主流程
                print("HealthKit 同步失败: \(error)")
            }
        }

        HapticManager.success()
        saveSuccess = true

        // 重置输入状态
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
        selectedMealContext = TagEngine.suggestContext()
        selectedDate = .now
        noteText = ""
        showNoteField = false
    }
}

/// 键盘按键类型
enum KeypadKey {
    case digit(Int)
    case decimal
    case delete
}
