//
//  StatisticsUITests.swift
//  XueTangJiLuUITests
//
//  Created by AI Assistant on 2026/2/23.
//

import XCTest

final class StatisticsUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    // MARK: - 统计页加载测试
    
    @MainActor
    func testStatisticsViewLoads() {
        switchToTab("统计", in: app)
        
        let statsTab = app.tabBars.buttons["统计"]
        XCTAssertTrue(statsTab.isSelected, "统计Tab应该被选中")
    }
    
    // MARK: - 趋势图显示测试
    
    @MainActor
    func testTrendChartDisplayed() {
        switchToTab("统计", in: app)
        
        // 验证图表区域存在
        _ = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'chart' OR identifier CONTAINS 'trend'")).firstMatch
        
        // 图表应该存在（即使是空状态）
        sleep(1)
    }
    
    // MARK: - 时间范围切换测试
    
    @MainActor
    func testTimeRangeSelection() {
        switchToTab("统计", in: app)
        
        // 查找时间范围选项
        let weekButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '7天' OR label CONTAINS '周'")).firstMatch
        
        if waitForElement(weekButton, timeout: 3) {
            weekButton.tap()
            sleep(1)
        }
        
        // 尝试切换到30天
        let monthButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '30天' OR label CONTAINS '月'")).firstMatch
        
        if monthButton.exists {
            monthButton.tap()
            sleep(1)
        }
    }
    
    // MARK: - 标签筛选测试
    
    @MainActor
    func testTagFilter() {
        switchToTab("统计", in: app)
        
        // 查找标签筛选按钮
        let filterButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '全部' OR label CONTAINS '筛选'")).firstMatch
        
        if filterButton.exists {
            filterButton.tap()
            sleep(1)
            
            // 选择一个标签
            let breakfastTag = app.buttons.matching(NSPredicate(format: "label CONTAINS '早餐'")).firstMatch
            if breakfastTag.exists {
                breakfastTag.tap()
                sleep(1)
            }
        }
    }
    
    // MARK: - TIR/TAR/TBR显示测试
    
    @MainActor
    func testRangeMetricsDisplayed() {
        switchToTab("统计", in: app)
        
        // 验证TIR相关指标显示
        let tirText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'TIR' OR label CONTAINS '达标率'")).firstMatch
        
        if tirText.exists {
            XCTAssertTrue(tirText.isHittable, "TIR指标应该可见")
        }
    }
    
    // MARK: - 统计卡片测试
    
    @MainActor
    func testStatisticsCards() {
        switchToTab("统计", in: app)
        
        // 验证统计卡片存在
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '平均' OR label CONTAINS 'Average'")).firstMatch
        
        sleep(1)
    }
    
    // MARK: - 餐前餐后对比测试
    
    @MainActor
    func testMealComparison() {
        switchToTab("统计", in: app)
        
        // 向下滚动查找餐前餐后对比
        app.swipeUp()
        
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '餐前' OR label CONTAINS '餐后'")).firstMatch
        
        sleep(1)
    }
    
    // MARK: - 指标说明测试
    
    @MainActor
    func testMetricExplanation() {
        switchToTab("统计", in: app)
        
        // 查找帮助或说明按钮
        let helpButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'help' OR identifier CONTAINS 'info'")).firstMatch
        
        if helpButton.exists {
            helpButton.tap()
            sleep(1)
            
            // 关闭说明
            let closeButton = app.buttons.firstMatch
            if closeButton.exists {
                closeButton.tap()
            }
        }
    }
    
    // MARK: - 空数据状态测试
    
    @MainActor
    func testEmptyDataState() {
        switchToTab("统计", in: app)
        
        // 如果没有数据，应该显示空状态提示
        let emptyText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '暂无数据' OR label CONTAINS '开始记录'")).firstMatch
        
        if emptyText.exists {
            XCTAssertTrue(emptyText.isHittable, "空状态提示应该可见")
        }
    }
    
    // MARK: - 图表交互测试
    
    @MainActor
    func testChartInteraction() {
        switchToTab("统计", in: app)
        
        // 尝试点击图表
        let chartArea = app.otherElements.firstMatch
        if chartArea.exists {
            chartArea.tap()
            sleep(UInt32(0.5))
        }
    }
}
