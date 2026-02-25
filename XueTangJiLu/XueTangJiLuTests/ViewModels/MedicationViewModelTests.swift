//
//  MedicationViewModelTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import SwiftData
@testable import XueTangJiLu

@MainActor
struct MedicationViewModelTests {
    
    // MARK: - 键盘输入测试
    
    @Test("输入数字键")
    @MainActor
    func testDigitInput() {
        let viewModel = MedicationViewModel()
        
        viewModel.handleKeyPress(.digit(4))
        #expect(viewModel.dosageText == "4")
        
        viewModel.handleKeyPress(.digit(5))
        #expect(viewModel.dosageText == "45")
    }
    
    @Test("输入小数点")
    @MainActor
    func testDecimalInput() {
        let viewModel = MedicationViewModel()
        
        viewModel.handleKeyPress(.digit(4))
        viewModel.handleKeyPress(.decimal)
        viewModel.handleKeyPress(.digit(5))
        
        #expect(viewModel.dosageText == "4.5")
    }
    
    @Test("限制小数位为1位")
    @MainActor
    func testDecimalPlacesLimit() {
        let viewModel = MedicationViewModel()
        
        viewModel.handleKeyPress(.digit(4))
        viewModel.handleKeyPress(.decimal)
        viewModel.handleKeyPress(.digit(5))
        viewModel.handleKeyPress(.digit(6)) // 第二位小数，应被拒绝
        
        #expect(viewModel.dosageText == "4.5")
    }
    
    @Test("删除键处理")
    @MainActor
    func testDeleteKey() {
        let viewModel = MedicationViewModel()
        
        viewModel.handleKeyPress(.digit(1))
        viewModel.handleKeyPress(.digit(2))
        viewModel.handleKeyPress(.decimal)
        viewModel.handleKeyPress(.digit(5))
        #expect(viewModel.dosageText == "12.5")
        
        viewModel.handleKeyPress(.delete)
        #expect(viewModel.dosageText == "12.")
        
        viewModel.handleKeyPress(.delete)
        #expect(viewModel.dosageText == "12")
    }
    
    @Test("空输入时添加小数点")
    @MainActor
    func testDecimalWithEmptyInput() {
        let viewModel = MedicationViewModel()
        
        viewModel.handleKeyPress(.decimal)
        #expect(viewModel.dosageText == "0.")
    }
    
    // MARK: - 输入验证测试
    
    @Test("保存按钮 - 有效输入启用")
    @MainActor
    func testSaveButtonEnabledWithValidInput() {
        let viewModel = MedicationViewModel()
        viewModel.medicationName = "诺和锐"
        viewModel.dosageText = "4"
        
        #expect(viewModel.isSaveEnabled == true)
    }
    
    @Test("保存按钮 - 零剂量禁用")
    @MainActor
    func testSaveButtonDisabledWithZeroDosage() {
        let viewModel = MedicationViewModel()
        viewModel.medicationName = "诺和锐"
        viewModel.dosageText = "0"
        
        #expect(viewModel.isSaveEnabled == false)
    }
    
    @Test("保存按钮 - 无输入禁用")
    @MainActor
    func testSaveButtonDisabledWithoutInput() {
        let viewModel = MedicationViewModel()
        viewModel.medicationName = "诺和锐"
        
        #expect(viewModel.isSaveEnabled == false)
    }
    
    // MARK: - 保存记录测试
    
    @Test("保存新记录")
    @MainActor
    func testSaveNewRecord() throws {
        let context = try TestDataFactory.createMockModelContext()
        let viewModel = MedicationViewModel()
        
        viewModel.selectedType = .rapidInsulin
        viewModel.medicationName = "诺和锐"
        viewModel.dosageText = "4.5"
        
        viewModel.saveRecord(modelContext: context)
        
        let descriptor = FetchDescriptor<MedicationRecord>()
        let records = try context.fetch(descriptor)
        
        #expect(records.count == 1)
        #expect(records.first?.medicationType == .rapidInsulin)
        #expect(records.first?.name == "诺和锐")
        #expect(records.first?.dosage == 4.5)
        #expect(viewModel.saveSuccess == true)
    }
    
    @Test("编辑现有记录")
    @MainActor
    func testEditExistingRecord() throws {
        let context = try TestDataFactory.createMockModelContext()
        let existingRecord = TestDataFactory.createMedicationRecord(
            medicationType: MedicationType.rapidInsulin,
            name: "诺和锐",
            dosage: 4.0
        )
        context.insert(existingRecord)
        
        let viewModel = MedicationViewModel()
        viewModel.loadRecordForEditing(existingRecord)
        
        #expect(viewModel.isEditMode == true)
        
        viewModel.dosageText = "6"
        viewModel.saveRecord(modelContext: context)
        
        #expect(existingRecord.dosage == 6.0)
    }
    
    // MARK: - 编辑记录加载测试
    
    @Test("加载记录进行编辑")
    @MainActor
    func testLoadRecordForEditing() {
        let record = TestDataFactory.createMedicationRecord(
            medicationType: MedicationType.longInsulin,
            name: "来得时",
            dosage: 8.0,
            note: "睡前注射"
        )
        
        let viewModel = MedicationViewModel()
        viewModel.loadRecordForEditing(record)
        
        #expect(viewModel.selectedType == .longInsulin)
        #expect(viewModel.medicationName == "来得时")
        #expect(viewModel.dosageText == "8")
        #expect(viewModel.noteText == "睡前注射")
        #expect(viewModel.isEditMode == true)
    }
    
    // MARK: - 输入重置测试
    
    @Test("重置输入状态")
    @MainActor
    func testResetInput() {
        let viewModel = MedicationViewModel()
        
        viewModel.selectedType = .longInsulin
        viewModel.medicationName = "来得时"
        viewModel.dosageText = "8"
        viewModel.noteText = "测试备注"
        
        viewModel.resetInput()
        
        #expect(viewModel.selectedType == .rapidInsulin)
        #expect(viewModel.medicationName == "")
        #expect(viewModel.dosageText == "")
        #expect(viewModel.noteText == "")
        #expect(viewModel.editingRecord == nil)
    }
}
