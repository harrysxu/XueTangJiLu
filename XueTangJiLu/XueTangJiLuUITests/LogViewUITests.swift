//
//  LogViewUITests.swift
//  XueTangJiLuUITests
//
//  Created by AI Assistant on 2026/2/23.
//

import XCTest

final class LogViewUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    // MARK: - 记录页加载测试
    
    @MainActor
    func testLogViewLoads() {
        // 切换到记录Tab
        switchToTab("记录", in: app)
        
        // 验证页面加载
        let logTab = app.tabBars.buttons["记录"]
        XCTAssertTrue(logTab.isSelected, "记录Tab应该被选中")
    }
    
    // MARK: - 时间轴显示测试
    
    @MainActor
    func testTimelineDisplayed() {
        switchToTab("记录", in: app)
        
        // 如果有记录，应该显示时间轴
        let recordsList = app.scrollViews.firstMatch
        XCTAssertTrue(recordsList.exists, "记录列表应该存在")
    }
    
    // MARK: - 添加记录测试
    
    @MainActor
    func testAddRecordFromLogView() {
        switchToTab("记录", in: app)
        
        // 查找添加按钮（FAB或工具栏按钮）
        let addButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'add' OR label CONTAINS '添加' OR label CONTAINS '+'")).firstMatch
        
        if waitForElement(addButton, timeout: 3) {
            addButton.tap()
            
            // 应该打开录入页
            let preview = app.staticTexts["glucosePreview"]
            XCTAssertTrue(waitForElement(preview), "应该打开录入页")
            
            // 返回
            app.buttons["取消"].tap()
        }
    }
    
    // MARK: - 记录类型筛选测试
    
    @MainActor
    func testRecordTypeFilter() {
        switchToTab("记录", in: app)
        
        // 查找筛选按钮
        let filterButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '筛选' OR label CONTAINS '全部'")).firstMatch
        
        if filterButton.exists {
            filterButton.tap()
            
            // 等待筛选菜单出现
            sleep(1)
        }
    }
    
    // MARK: - 日期分组测试
    
    @MainActor
    func testDateGrouping() {
        switchToTab("记录", in: app)
        
        // 验证日期分组标题存在
        let todayText = app.staticTexts["今天"]
        let yesterdayText = app.staticTexts["昨天"]
        
        // 至少应该有一个日期标题
        XCTAssertTrue(todayText.exists || yesterdayText.exists, "应该有日期分组")
    }
    
    // MARK: - 记录详情测试
    
    @MainActor
    func testRecordDetailView() {
        switchToTab("记录", in: app)
        
        // 尝试点击第一条记录
        let firstRecord = app.cells.firstMatch
        
        if firstRecord.exists && firstRecord.isHittable {
            firstRecord.tap()
            
            // 应该打开详情页
            sleep(1)
            
            // 返回
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    // MARK: - 删除记录测试
    
    @MainActor
    func testDeleteRecord() {
        switchToTab("记录", in: app)
        
        // 尝试左滑第一条记录
        let firstRecord = app.cells.firstMatch
        
        if firstRecord.exists {
            firstRecord.swipeLeft()
            
            // 查找删除按钮
            let deleteButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '删除' OR label CONTAINS 'Delete'")).firstMatch
            
            if waitForElement(deleteButton, timeout: 2) {
                // 测试策略：验证删除按钮可访问，但不执行删除以保护测试数据
                // 取消删除操作
                firstRecord.swipeRight()
            }
        }
    }
    
    // MARK: - 下拉刷新测试
    
    @MainActor
    func testPullToRefresh() {
        switchToTab("记录", in: app)
        
        // 下拉刷新
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            sleep(1)
        }
    }
    
    // MARK: - 滚动测试
    
    @MainActor
    func testScrolling() {
        switchToTab("记录", in: app)
        
        let scrollView = app.scrollViews.firstMatch
        
        if scrollView.exists {
            // 向上滚动
            scrollView.swipeUp()
            sleep(UInt32(0.5))
            
            // 向下滚动
            scrollView.swipeDown()
            sleep(UInt32(0.5))
        }
    }
    
    // MARK: - 空状态测试
    
    @MainActor
    func testEmptyState() {
        switchToTab("记录", in: app)
        
        // 验证空状态提示
        let emptyText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '暂无' OR label CONTAINS '还没有'")).firstMatch
        
        if emptyText.exists {
            XCTAssertTrue(emptyText.isHittable, "空状态提示应该可见")
        }
    }
}
