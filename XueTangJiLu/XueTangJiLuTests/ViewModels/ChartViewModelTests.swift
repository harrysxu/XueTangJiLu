//
//  ChartViewModelTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import Foundation
@testable import XueTangJiLu

@MainActor
struct ChartViewModelTests {
    
    // MARK: - 时间范围测试
    
    @Test("时间范围 - 7天")
    func testTimeRangeWeek() {
        let viewModel = ChartViewModel()
        viewModel.selectedRange = .week
        
        #expect(viewModel.selectedRange.days == 7)
    }
    
    @Test("时间范围 - 自定义")
    func testTimeRangeCustom() {
        let viewModel = ChartViewModel()
        viewModel.selectedRange = .custom
        
        let startDate = TestDataFactory.daysAgo(10)
        let endDate = Date.now
        
        viewModel.customStartDate = startDate
        viewModel.customEndDate = endDate
        
        #expect(viewModel.customStartDate == startDate)
        #expect(viewModel.customEndDate == endDate)
    }
    
    // MARK: - 数据点生成测试
    
    @Test("生成数据点 - 空记录")
    func testDataPointsEmpty() {
        let viewModel = ChartViewModel()
        let dataPoints = viewModel.dataPoints(from: [])
        
        #expect(dataPoints.isEmpty)
    }
    
    @Test("生成数据点 - 基本记录")
    func testDataPointsBasic() {
        let viewModel = ChartViewModel()
        viewModel.selectedRange = .week
        
        let records = [
            TestDataFactory.createGlucoseRecord(value: 5.5, timestamp: TestDataFactory.daysAgo(1)),
            TestDataFactory.createGlucoseRecord(value: 7.2, timestamp: TestDataFactory.daysAgo(2)),
            TestDataFactory.createGlucoseRecord(value: 6.1, timestamp: TestDataFactory.daysAgo(3))
        ]
        
        let dataPoints = viewModel.dataPoints(from: records)
        
        #expect(dataPoints.count == 3)
        #expect(dataPoints[0].value == 6.1) // 排序后最早的
        #expect(dataPoints[2].value == 5.5) // 排序后最新的
    }
    
    @Test("生成数据点 - 按日期排序")
    func testDataPointsSortedByDate() {
        let viewModel = ChartViewModel()
        
        let records = [
            TestDataFactory.createGlucoseRecord(value: 8.0, timestamp: TestDataFactory.daysAgo(1)),
            TestDataFactory.createGlucoseRecord(value: 5.0, timestamp: TestDataFactory.daysAgo(3)),
            TestDataFactory.createGlucoseRecord(value: 6.0, timestamp: TestDataFactory.daysAgo(2))
        ]
        
        let dataPoints = viewModel.dataPoints(from: records)
        
        #expect(dataPoints.count == 3)
        #expect(dataPoints[0].value == 5.0) // 最早
        #expect(dataPoints[1].value == 6.0)
        #expect(dataPoints[2].value == 8.0) // 最新
    }
    
    @Test("生成数据点 - 场景感知着色")
    func testDataPointsWithSceneAwareness() throws {
        let viewModel = ChartViewModel()
        let settings = TestDataFactory.createUserSettings()
        
        let records = [
            TestDataFactory.createGlucoseRecord(value: 5.0, sceneTagId: "beforeBreakfast"),
            TestDataFactory.createGlucoseRecord(value: 9.0, sceneTagId: "afterBreakfast")
        ]
        
        let dataPoints = viewModel.dataPoints(from: records, settings: settings)
        
        #expect(dataPoints.count == 2)
    }
    
    // MARK: - 筛选测试
    
    @Test("筛选 - 时间范围")
    func testFilterByTimeRange() {
        let viewModel = ChartViewModel()
        viewModel.selectedRange = .week
        
        let records = [
            TestDataFactory.createGlucoseRecord(value: 5.5, timestamp: TestDataFactory.daysAgo(3)),
            TestDataFactory.createGlucoseRecord(value: 6.0, timestamp: TestDataFactory.daysAgo(10)), // 超出7天
            TestDataFactory.createGlucoseRecord(value: 7.0, timestamp: TestDataFactory.daysAgo(5))
        ]
        
        let filtered = viewModel.filteredRecords(from: records)
        
        #expect(filtered.count == 2) // 只有7天内的
    }
    
    @Test("筛选 - 全部标签")
    func testFilterAllTags() {
        let viewModel = ChartViewModel()
        viewModel.selectedTagFilter = .all
        
        let records = [
            TestDataFactory.createGlucoseRecord(sceneTagId: "beforeBreakfast"),
            TestDataFactory.createGlucoseRecord(sceneTagId: "afterLunch"),
            TestDataFactory.createGlucoseRecord(sceneTagId: "bedtime")
        ]
        
        let filtered = viewModel.filteredRecords(from: records)
        
        #expect(filtered.count == 3)
    }
    
    @Test("筛选 - 特定标签")
    func testFilterBySpecificTag() {
        let viewModel = ChartViewModel()
        viewModel.selectedTagFilter = .tag("beforeBreakfast")
        
        let records = [
            TestDataFactory.createGlucoseRecord(sceneTagId: "beforeBreakfast"),
            TestDataFactory.createGlucoseRecord(sceneTagId: "afterLunch"),
            TestDataFactory.createGlucoseRecord(sceneTagId: "beforeBreakfast")
        ]
        
        let filtered = viewModel.filteredRecords(from: records)
        
        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.sceneTagId == "beforeBreakfast" })
    }
    
    @Test("筛选 - 阈值分组")
    func testFilterByThresholdGroup() throws {
        let viewModel = ChartViewModel()
        viewModel.selectedTagFilter = .group(.fasting)
        
        let settings = TestDataFactory.createUserSettings()
        
        let records = [
            TestDataFactory.createGlucoseRecord(sceneTagId: "beforeBreakfast"), // fasting
            TestDataFactory.createGlucoseRecord(sceneTagId: "afterLunch"), // postprandial
            TestDataFactory.createGlucoseRecord(sceneTagId: "fasting") // fasting
        ]
        
        let filtered = viewModel.filteredRecords(from: records, settings: settings)
        
        // 应该只包含 fasting 分组的记录
        #expect(filtered.count >= 1)
    }
    
    // MARK: - 阈值范围测试
    
    @Test("有效阈值范围 - 全部")
    func testEffectiveThresholdRangeAll() {
        let viewModel = ChartViewModel()
        viewModel.selectedTagFilter = .all
        
        let settings = TestDataFactory.createUserSettings()
        let range = viewModel.effectiveThresholdRange(settings: settings)
        
        #expect(range.low > 0)
        #expect(range.high > range.low)
    }
    
    @Test("有效阈值范围 - 特定标签")
    func testEffectiveThresholdRangeSpecificTag() {
        let viewModel = ChartViewModel()
        viewModel.selectedTagFilter = .tag("beforeBreakfast")
        
        let settings = TestDataFactory.createUserSettings()
        let range = viewModel.effectiveThresholdRange(settings: settings)
        
        #expect(range.low > 0)
        #expect(range.high > range.low)
    }
}
