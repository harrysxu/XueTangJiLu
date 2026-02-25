//
//  ChartSnapshotServiceTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import SwiftUI
@testable import XueTangJiLu

struct ChartSnapshotServiceTests {
    
    // MARK: - 趋势图渲染测试
    
    @Test("渲染趋势图 - 基本功能")
    @MainActor
    func testRenderTrendChartBasic() {
        let dataPoints = [
            ChartDataPoint(date: TestDataFactory.daysAgo(2), value: 5.5, level: .normal),
            ChartDataPoint(date: TestDataFactory.daysAgo(1), value: 6.2, level: .normal),
            ChartDataPoint(date: Date.now, value: 7.1, level: .high)
        ]
        
        let size = CGSize(width: 400, height: 300)
        let image = ChartSnapshotService.renderTrendChart(
            dataPoints: dataPoints,
            targetLow: 4.4,
            targetHigh: 7.0,
            unit: .mmolL,
            size: size
        )
        
        #expect(image != nil)
        #expect(image?.size.width == size.width)
        #expect(image?.size.height == size.height)
    }
    
    @Test("渲染趋势图 - 空数据")
    @MainActor
    func testRenderTrendChartEmpty() {
        let size = CGSize(width: 400, height: 300)
        let image = ChartSnapshotService.renderTrendChart(
            dataPoints: [],
            targetLow: 4.4,
            targetHigh: 7.0,
            unit: .mmolL,
            size: size
        )
        
        #expect(image != nil) // 即使没有数据也应该生成图片
    }
    
    // MARK: - 条形图渲染测试
    
    @Test("渲染场景TIR条形图")
    @MainActor
    func testRenderPerTagTIRChart() {
        let records = TestDataFactory.createGlucoseRecords(count: 10)
        let settings = TestDataFactory.createUserSettings()
        let size = CGSize(width: 400, height: 300)
        
        let image = ChartSnapshotService.renderPerTagTIRChart(
            records: records,
            settings: settings,
            size: size
        )
        
        #expect(image != nil)
    }
    
    // MARK: - 范围分布条渲染测试
    
    @Test("渲染范围分布条")
    @MainActor
    func testRenderRangeDistributionBar() {
        let records = TestDataFactory.createGlucoseRecords(count: 20, valueRange: 4.0...12.0)
        let settings = TestDataFactory.createUserSettings()
        let size = CGSize(width: 400, height: 50)
        
        let image = ChartSnapshotService.renderRangeDistributionBar(
            records: records,
            settings: settings,
            size: size
        )
        
        #expect(image != nil)
    }
    
    // MARK: - 箱线图渲染测试
    
    @Test("渲染箱线图")
    @MainActor
    func testRenderBoxPlotChart() {
        let records = TestDataFactory.createGlucoseRecords(count: 50, valueRange: 4.0...10.0)
        let settings = TestDataFactory.createUserSettings()
        let size = CGSize(width: 400, height: 300)
        
        let image = ChartSnapshotService.renderBoxPlotChart(
            records: records,
            settings: settings,
            size: size
        )
        
        #expect(image != nil)
    }
}
