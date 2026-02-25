//
//  PDFExportServiceTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import Foundation
@testable import XueTangJiLu

struct PDFExportServiceTests {
    
    // MARK: - PDF生成基本测试
    
    @Test("生成PDF - 基本功能")
    func testGenerateReportBasic() {
        let records = TestDataFactory.createGlucoseRecords(count: 5)
        let settings = TestDataFactory.createUserSettings()
        
        let pdfData = PDFExportService.generateReport(
            records: records,
            dateRange: "2026-02-16 至 2026-02-23",
            unit: .mmolL,
            settings: settings
        )
        
        #expect(!pdfData.isEmpty)
        #expect(pdfData.count > 1000) // PDF文件应该有一定大小
    }
    
    @Test("生成PDF - 空记录")
    func testGenerateReportEmpty() {
        let settings = TestDataFactory.createUserSettings()
        
        let pdfData = PDFExportService.generateReport(
            records: [],
            dateRange: "2026-02-16 至 2026-02-23",
            unit: .mmolL,
            settings: settings
        )
        
        #expect(!pdfData.isEmpty) // 即使没有记录，也应该生成PDF（包含标题等）
    }
    
    @Test("生成PDF - 不同单位")
    func testGenerateReportDifferentUnits() {
        let records = TestDataFactory.createGlucoseRecords(count: 3)
        let settings = TestDataFactory.createUserSettings()
        
        // mmol/L
        let pdfMmol = PDFExportService.generateReport(
            records: records,
            dateRange: "测试范围",
            unit: .mmolL,
            settings: settings
        )
        #expect(!pdfMmol.isEmpty)
        
        // mg/dL
        let pdfMgdl = PDFExportService.generateReport(
            records: records,
            dateRange: "测试范围",
            unit: .mgdL,
            settings: settings
        )
        #expect(!pdfMgdl.isEmpty)
    }
    
    @Test("生成PDF - 包含用药记录")
    func testGenerateReportWithMedications() {
        let records = TestDataFactory.createGlucoseRecords(count: 5)
        let medications = [
            TestDataFactory.createMedicationRecord(medicationType: MedicationType.rapidInsulin, name: "诺和锐", dosage: 4.0),
            TestDataFactory.createMedicationRecord(medicationType: MedicationType.longInsulin, name: "来得时", dosage: 8.0)
        ]
        let settings = TestDataFactory.createUserSettings()
        
        let pdfData = PDFExportService.generateReport(
            records: records,
            dateRange: "测试范围",
            unit: .mmolL,
            settings: settings,
            medications: medications
        )
        
        #expect(!pdfData.isEmpty)
    }
    
    @Test("生成PDF - 包含饮食记录")
    func testGenerateReportWithMeals() {
        let records = TestDataFactory.createGlucoseRecords(count: 5)
        let meals = [
            TestDataFactory.createMealRecord(carbLevel: CarbLevel.medium, mealDescription: "早餐"),
            TestDataFactory.createMealRecord(carbLevel: CarbLevel.high, mealDescription: "午餐")
        ]
        let settings = TestDataFactory.createUserSettings()
        
        let pdfData = PDFExportService.generateReport(
            records: records,
            dateRange: "测试范围",
            unit: .mmolL,
            settings: settings,
            meals: meals
        )
        
        #expect(!pdfData.isEmpty)
    }
    
    // MARK: - CSV导出测试
    
    @Test("生成CSV - 基本功能")
    func testGenerateCSVBasic() {
        let records = TestDataFactory.createGlucoseRecords(count: 3)
        let settings = TestDataFactory.createUserSettings()
        
        let csvString = PDFExportService.generateCSV(
            records: records,
            unit: .mmolL,
            settings: settings
        )
        
        #expect(!csvString.isEmpty)
        #expect(csvString.contains("日期"))
        #expect(csvString.contains("血糖值"))
        #expect(csvString.contains("场景"))
    }
    
    @Test("生成CSV - 空记录")
    func testGenerateCSVEmpty() {
        let settings = TestDataFactory.createUserSettings()
        
        let csvString = PDFExportService.generateCSV(
            records: [],
            unit: .mmolL,
            settings: settings
        )
        
        #expect(!csvString.isEmpty) // 应该至少包含表头
        #expect(csvString.contains("日期"))
    }
    
    @Test("生成CSV - 验证格式")
    func testGenerateCSVFormat() {
        let record = TestDataFactory.createGlucoseRecord(value: 5.6, sceneTagId: "beforeBreakfast")
        let settings = TestDataFactory.createUserSettings()
        
        let csvString = PDFExportService.generateCSV(
            records: [record],
            unit: .mmolL,
            settings: settings
        )
        
        // 验证CSV包含逗号分隔符
        #expect(csvString.contains(","))
        
        // 验证包含换行符
        #expect(csvString.contains("\n"))
    }
}
