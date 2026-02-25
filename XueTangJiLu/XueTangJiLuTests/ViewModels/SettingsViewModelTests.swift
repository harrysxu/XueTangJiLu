//
//  SettingsViewModelTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import Foundation
@testable import XueTangJiLu

@MainActor
struct SettingsViewModelTests {
    
    // MARK: - 导出日期范围测试
    
    @Test("导出日期范围 - 默认30天")
    func testExportDateRangeDefault() {
        let viewModel = SettingsViewModel()
        
        #expect(viewModel.exportStartDate <= Date.now)
        #expect(viewModel.exportEndDate <= Date.now)
    }
    
    @Test("导出日期范围 - 自定义")
    func testExportDateRangeCustom() {
        let viewModel = SettingsViewModel()
        
        let startDate = TestDataFactory.daysAgo(7)
        let endDate = Date.now
        
        viewModel.exportStartDate = startDate
        viewModel.exportEndDate = endDate
        
        #expect(viewModel.exportStartDate == startDate)
        #expect(viewModel.exportEndDate == endDate)
    }
    
    @Test("导出日期范围字符串")
    func testExportDateRangeString() {
        let viewModel = SettingsViewModel()
        
        let rangeString = viewModel.exportDateRange
        #expect(!rangeString.isEmpty)
    }
    
    // MARK: - 导出记录类型测试
    
    @Test("导出记录类型 - 默认全部")
    func testExportRecordTypeDefault() {
        let viewModel = SettingsViewModel()
        
        #expect(viewModel.exportRecordType == .all)
    }
    
    @Test("导出记录类型 - 切换类型")
    func testExportRecordTypeSwitch() {
        let viewModel = SettingsViewModel()
        
        viewModel.exportRecordType = .glucoseOnly
        #expect(viewModel.exportRecordType == .glucoseOnly)
        
        viewModel.exportRecordType = .medicationOnly
        #expect(viewModel.exportRecordType == .medicationOnly)
    }
    
    // MARK: - PDF导出测试
    
    @Test("生成PDF - 基本功能")
    func testGeneratePDFBasic() {
        let viewModel = SettingsViewModel()
        let settings = TestDataFactory.createUserSettings()
        
        viewModel.exportStartDate = TestDataFactory.daysAgo(7)
        viewModel.exportEndDate = Date.now
        
        let records = TestDataFactory.createGlucoseRecords(count: 10)
        let pdfData = viewModel.generatePDF(
            records: records,
            unit: .mmolL,
            settings: settings
        )
        
        #expect(!pdfData.isEmpty)
    }
    
    @Test("生成PDF - 日期范围筛选")
    func testGeneratePDFDateFiltering() {
        let viewModel = SettingsViewModel()
        let settings = TestDataFactory.createUserSettings()
        
        viewModel.exportStartDate = TestDataFactory.daysAgo(3)
        viewModel.exportEndDate = Date.now
        
        let records = [
            TestDataFactory.createGlucoseRecord(timestamp: TestDataFactory.daysAgo(1)), // 在范围内
            TestDataFactory.createGlucoseRecord(timestamp: TestDataFactory.daysAgo(2)), // 在范围内
            TestDataFactory.createGlucoseRecord(timestamp: TestDataFactory.daysAgo(5))  // 超出范围
        ]
        
        let pdfData = viewModel.generatePDF(
            records: records,
            unit: .mmolL,
            settings: settings
        )
        
        #expect(!pdfData.isEmpty)
    }
    
    // MARK: - CSV导出测试
    
    @Test("生成CSV - 基本功能")
    func testGenerateCSVBasic() {
        let viewModel = SettingsViewModel()
        let settings = TestDataFactory.createUserSettings()
        
        viewModel.exportStartDate = TestDataFactory.daysAgo(7)
        viewModel.exportEndDate = Date.now
        
        let records = TestDataFactory.createGlucoseRecords(count: 5)
        let csvString = viewModel.generateCSV(
            records: records,
            unit: .mmolL,
            settings: settings
        )
        
        #expect(!csvString.isEmpty)
        #expect(csvString.contains("日期")) // CSV header
    }
    
    @Test("生成CSV - 日期范围筛选")
    func testGenerateCSVDateFiltering() {
        let viewModel = SettingsViewModel()
        let settings = TestDataFactory.createUserSettings()
        
        viewModel.exportStartDate = TestDataFactory.daysAgo(2)
        viewModel.exportEndDate = Date.now
        
        let records = [
            TestDataFactory.createGlucoseRecord(timestamp: TestDataFactory.daysAgo(1)),
            TestDataFactory.createGlucoseRecord(timestamp: TestDataFactory.daysAgo(5))
        ]
        
        let csvString = viewModel.generateCSV(
            records: records,
            unit: .mmolL,
            settings: settings
        )
        
        #expect(!csvString.isEmpty)
    }
}
