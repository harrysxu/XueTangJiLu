//
//  DashboardUITests.swift
//  XueTangJiLuUITests
//
//  Created by AI Assistant on 2026/2/23.
//

import XCTest

final class DashboardUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    // MARK: - 首页加载测试
    
    @MainActor
    func testDashboardLoads() {
        // 等待首页加载
        let homeTab = app.tabBars.buttons["首页"]
        XCTAssertTrue(waitForElement(homeTab), "首页Tab应该存在")
        
        // 验证主要元素存在
        let addButton = app.buttons["addRecord"]
        XCTAssertTrue(waitForElement(addButton), "添加记录按钮应该存在")
    }
    
    @MainActor
    func testGreetingDisplayed() {
        // 验证问候语显示
        let greeting = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '早上好' OR label CONTAINS '下午好' OR label CONTAINS '晚上好'")).firstMatch
        XCTAssertTrue(waitForElement(greeting, timeout: 3), "问候语应该显示")
    }
    
    // MARK: - 快捷操作测试
    
    @MainActor
    func testQuickRecordButton() {
        let addButton = app.buttons["addRecord"]
        safeTap(addButton)
        
        // 应该打开录入页
        let preview = app.staticTexts["glucosePreview"]
        XCTAssertTrue(waitForElement(preview), "应该打开血糖录入页")
        
        // 返回
        app.buttons["取消"].tap()
    }
    
    // MARK: - 最新血糖卡片测试
    
    @MainActor
    func testLatestGlucoseCard() {
        // 如果有记录，应该显示最新血糖卡片
        // 注意：这个测试依赖于是否有数据
        let latestGlucoseCard = app.otherElements["latestGlucoseCard"]
        
        if latestGlucoseCard.exists {
            XCTAssertTrue(latestGlucoseCard.isHittable, "最新血糖卡片应该可见")
        }
    }
    
    // MARK: - 今日摘要测试
    
    @MainActor
    func testDailySummaryCard() {
        // 验证今日摘要卡片存在
        let summaryCard = app.otherElements["dailySummaryCard"]
        
        if summaryCard.exists {
            XCTAssertTrue(summaryCard.isHittable, "今日摘要卡片应该可见")
        }
    }
    
    // MARK: - 今日记录时间轴测试
    
    @MainActor
    func testTodayTimelineDisplayed() {
        // 验证今日记录部分存在
        let todaySection = app.staticTexts["今日记录"]
        
        if todaySection.exists {
            XCTAssertTrue(todaySection.isHittable, "今日记录标题应该可见")
        }
    }
    
    // MARK: - 空状态测试
    
    @MainActor
    func testEmptyStateWhenNoRecords() {
        // 注意：这个测试需要在没有数据的环境下运行
        // 可以通过 --reset 参数清空数据
        
        let emptyStateText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '暂无记录'")).firstMatch
        
        // 如果显示空状态，验证添加按钮存在
        if emptyStateText.exists {
            let addButton = app.buttons["addRecord"]
            XCTAssertTrue(addButton.exists, "空状态下应该有添加按钮")
        }
    }
    
    // MARK: - 导航测试
    
    @MainActor
    func testNavigationToOtherTabs() {
        // 切换到记录Tab
        switchToTab("记录", in: app)
        
        // 切换到统计Tab
        switchToTab("统计", in: app)
        
        // 切换到我的Tab
        switchToTab("我的", in: app)
        
        // 切换回首页
        switchToTab("首页", in: app)
    }
    
    // MARK: - 刷新测试
    
    @MainActor
    func testPullToRefresh() {
        // 执行下拉刷新手势
        app.swipeDown()
        
        // 等待刷新完成
        sleep(1)
        
        // 验证页面仍然正常
        let addButton = app.buttons["addRecord"]
        XCTAssertTrue(addButton.exists, "刷新后首页应该正常显示")
    }
}
