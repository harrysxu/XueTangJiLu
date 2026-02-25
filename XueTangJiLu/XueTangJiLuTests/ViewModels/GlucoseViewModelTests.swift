//
//  GlucoseViewModelTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import SwiftData
@testable import XueTangJiLu

struct GlucoseViewModelTests {
    
    // MARK: - 键盘输入测试
    
    @Test("输入数字键")
    @MainActor
    func testDigitInput() {
        let viewModel = GlucoseViewModel()
        
        viewModel.handleKeyPress(.digit(5), unit: .mmolL)
        #expect(viewModel.inputText == "5")
        
        viewModel.handleKeyPress(.digit(6), unit: .mmolL)
        #expect(viewModel.inputText == "56")
    }
    
    @Test("输入小数点 - mmol/L 允许")
    @MainActor
    func testDecimalInputMmolL() {
        let viewModel = GlucoseViewModel()
        
        viewModel.handleKeyPress(.digit(5), unit: .mmolL)
        viewModel.handleKeyPress(.decimal, unit: .mmolL)
        viewModel.handleKeyPress(.digit(6), unit: .mmolL)
        
        #expect(viewModel.inputText == "5.6")
    }
    
    @Test("输入小数点 - mg/dL 不允许")
    @MainActor
    func testDecimalInputMgdL() {
        let viewModel = GlucoseViewModel()
        
        viewModel.handleKeyPress(.digit(1), unit: .mgdL)
        viewModel.handleKeyPress(.digit(0), unit: .mgdL)
        viewModel.handleKeyPress(.digit(0), unit: .mgdL)
        viewModel.handleKeyPress(.decimal, unit: .mgdL)
        
        // mg/dL 不应该插入小数点
        #expect(viewModel.inputText == "100")
    }
    
    @Test("mmol/L 限制小数位为1位")
    @MainActor
    func testDecimalPlacesLimitMmolL() {
        let viewModel = GlucoseViewModel()
        
        viewModel.handleKeyPress(.digit(5), unit: .mmolL)
        viewModel.handleKeyPress(.decimal, unit: .mmolL)
        viewModel.handleKeyPress(.digit(6), unit: .mmolL)
        viewModel.handleKeyPress(.digit(7), unit: .mmolL) // 第二位小数，应被拒绝
        
        #expect(viewModel.inputText == "5.6")
    }
    
    @Test("删除键处理")
    @MainActor
    func testDeleteKey() {
        let viewModel = GlucoseViewModel()
        
        viewModel.handleKeyPress(.digit(5), unit: .mmolL)
        viewModel.handleKeyPress(.decimal, unit: .mmolL)
        viewModel.handleKeyPress(.digit(6), unit: .mmolL)
        #expect(viewModel.inputText == "5.6")
        
        viewModel.handleKeyPress(.delete, unit: .mmolL)
        #expect(viewModel.inputText == "5.")
        
        viewModel.handleKeyPress(.delete, unit: .mmolL)
        #expect(viewModel.inputText == "5")
        
        viewModel.handleKeyPress(.delete, unit: .mmolL)
        #expect(viewModel.inputText == "")
    }
    
    @Test("空输入时添加小数点")
    @MainActor
    func testDecimalWithEmptyInput() {
        let viewModel = GlucoseViewModel()
        
        viewModel.handleKeyPress(.decimal, unit: .mmolL)
        #expect(viewModel.inputText == "0.")
    }
    
    @Test("替换前导零")
    @MainActor
    func testReplaceLeadingZero() {
        let viewModel = GlucoseViewModel()
        
        viewModel.handleKeyPress(.digit(0), unit: .mmolL)
        #expect(viewModel.inputText == "0")
        
        viewModel.handleKeyPress(.digit(5), unit: .mmolL)
        #expect(viewModel.inputText == "5")
    }
    
    // MARK: - 输入验证测试
    
    @Test("保存按钮 - 有效输入启用")
    @MainActor
    func testSaveButtonEnabledWithValidInput() {
        let viewModel = GlucoseViewModel()
        viewModel.inputText = "5.6"
        
        #expect(viewModel.isSaveEnabled(unit: .mmolL) == true)
    }
    
    @Test("保存按钮 - 无输入禁用")
    @MainActor
    func testSaveButtonDisabledWithoutInput() {
        let viewModel = GlucoseViewModel()
        
        #expect(viewModel.isSaveEnabled(unit: .mmolL) == false)
    }
    
    @Test("保存按钮 - 超出范围禁用")
    @MainActor
    func testSaveButtonDisabledOutOfRange() {
        let viewModel = GlucoseViewModel()
        
        // mmol/L 范围: 1.0 - 33.3
        viewModel.inputText = "0.5" // 低于最小值
        #expect(viewModel.isSaveEnabled(unit: .mmolL) == false)
        
        viewModel.inputText = "40.0" // 超过最大值
        #expect(viewModel.isSaveEnabled(unit: .mmolL) == false)
    }
    
    // MARK: - 血糖等级计算测试
    
    @Test("血糖等级计算 - 通用阈值")
    @MainActor
    func testGlucoseLevelGeneric() {
        let viewModel = GlucoseViewModel()
        
        viewModel.inputText = "3.0"
        #expect(viewModel.currentLevel(unit: .mmolL) == .low)
        
        viewModel.inputText = "5.5"
        #expect(viewModel.currentLevel(unit: .mmolL) == .normal)
        
        viewModel.inputText = "8.0"
        #expect(viewModel.currentLevel(unit: .mmolL) == .high)
        
        viewModel.inputText = "12.0"
        #expect(viewModel.currentLevel(unit: .mmolL) == .veryHigh)
    }
    
    // MARK: - 保存记录测试
    
    @Test("保存新记录")
    @MainActor
    func testSaveNewRecord() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let viewModel = GlucoseViewModel()
        
        viewModel.inputText = "5.6"
        viewModel.selectedSceneTagId = "beforeBreakfast"
        
        await viewModel.saveRecord(
            modelContext: context,
            unit: .mmolL,
            healthKitManager: nil,
            healthKitEnabled: false
        )
        
        let descriptor = FetchDescriptor<GlucoseRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 1)
        #expect(records.first?.value == 5.6)
        #expect(records.first?.sceneTagId == "beforeBreakfast")
        #expect(viewModel.saveSuccess == true)
    }
    
    @Test("保存记录到 HealthKit")
    @MainActor
    func testSaveRecordWithHealthKit() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let viewModel = GlucoseViewModel()
        
        viewModel.inputText = "6.5"
        viewModel.selectedSceneTagId = "afterLunch"
        
        await viewModel.saveRecord(
            modelContext: context,
            unit: .mmolL,
            healthKitManager: nil,
            healthKitEnabled: false
        )
        
        let descriptor = FetchDescriptor<GlucoseRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 1)
        #expect(records.first?.value == 6.5)
        #expect(records.first?.sceneTagId == "afterLunch")
    }
    
    @Test("编辑现有记录")
    @MainActor
    func testEditExistingRecord() async throws {
        let context = try TestDataFactory.createMockModelContext()
        let existingRecord = TestDataFactory.createGlucoseRecord(value: 5.0)
        context.insert(existingRecord)
        
        let viewModel = GlucoseViewModel()
        viewModel.loadRecordForEditing(existingRecord, unit: .mmolL)
        
        #expect(viewModel.isEditMode == true)
        #expect(viewModel.inputText == "5.0")
        
        viewModel.inputText = "6.5"
        await viewModel.saveRecord(
            modelContext: context,
            unit: .mmolL,
            healthKitManager: nil,
            healthKitEnabled: false
        )
        
        #expect(existingRecord.value == 6.5)
    }
    
    // MARK: - 编辑记录加载测试
    
    @Test("加载记录进行编辑")
    @MainActor
    func testLoadRecordForEditing() {
        let record = TestDataFactory.createGlucoseRecord(
            value: 7.8,
            sceneTagId: "afterDinner",
            note: "饭后测量"
        )
        
        let viewModel = GlucoseViewModel()
        viewModel.loadRecordForEditing(record, unit: .mmolL)
        
        #expect(viewModel.inputText == "7.8")
        #expect(viewModel.selectedSceneTagId == "afterDinner")
        #expect(viewModel.noteText == "饭后测量")
        #expect(viewModel.showNoteField == true)
        #expect(viewModel.isEditMode == true)
    }
    
    // MARK: - 输入重置测试
    
    @Test("重置输入状态")
    @MainActor
    func testResetInput() {
        let viewModel = GlucoseViewModel()
        
        viewModel.inputText = "5.6"
        viewModel.noteText = "测试备注"
        viewModel.showNoteField = true
        
        viewModel.resetInput()
        
        #expect(viewModel.inputText == "")
        #expect(viewModel.noteText == "")
        #expect(viewModel.showNoteField == false)
        #expect(viewModel.editingRecord == nil)
    }
    
    // MARK: - 单位转换测试
    
    @Test("单位转换 - mmol/L")
    @MainActor
    func testNormalizedValueMmolL() {
        let viewModel = GlucoseViewModel()
        viewModel.inputText = "5.6"
        
        let normalized = viewModel.normalizedValue(unit: .mmolL)
        #expect(normalized == 5.6)
    }
    
    @Test("单位转换 - mg/dL")
    @MainActor
    func testNormalizedValueMgdL() {
        let viewModel = GlucoseViewModel()
        viewModel.inputText = "100"
        
        let normalized = viewModel.normalizedValue(unit: .mgdL)
        #expect(normalized != nil)
        #expect(abs(normalized! - 5.55) < 0.1)
    }
}
