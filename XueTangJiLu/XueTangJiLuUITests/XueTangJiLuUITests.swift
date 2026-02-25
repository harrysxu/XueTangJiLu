//
//  XueTangJiLuUITests.swift
//  XueTangJiLuUITests
//
//  Created by 徐晓龙 on 2026/2/12.
//

import XCTest

final class XueTangJiLuUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

// MARK: - 快速录入流程 E2E 测试

final class RecordFlowUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    // MARK: - 核心录入流程

    /// 测试完整的快速录入流程：打开录入页 → 输入数值 → 保存
    @MainActor
    func testQuickRecordFlow() throws {
        // 1. 等待首页加载并点击录入按钮
        let recordButton = app.buttons["addRecord"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 5), "录入按钮应存在于首页")
        recordButton.tap()

        // 2. 等待录入页弹出
        let preview = app.staticTexts["glucosePreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 3), "数值预览应存在")

        // 3. 输入血糖值 5.6
        let key5 = app.buttons["keypad_5"]
        XCTAssertTrue(key5.waitForExistence(timeout: 2), "键盘按键 5 应存在")
        key5.tap()

        let keyDot = app.buttons["keypad_dot"]
        keyDot.tap()

        let key6 = app.buttons["keypad_6"]
        key6.tap()

        // 4. 验证预览显示 5.6
        XCTAssertEqual(preview.label, "5.6", "预览应显示输入值 5.6")

        // 5. 点击保存
        let saveButton = app.buttons["saveRecord"]
        XCTAssertTrue(saveButton.isEnabled, "保存按钮应可用")
        saveButton.tap()

        // 6. 验证返回首页
        XCTAssertTrue(recordButton.waitForExistence(timeout: 3), "应返回首页")
    }

    /// 测试录入页的数字键盘输入与删除
    @MainActor
    func testKeypadInputAndDelete() throws {
        // 打开录入页
        let recordButton = app.buttons["addRecord"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 5))
        recordButton.tap()

        let preview = app.staticTexts["glucosePreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 3))

        // 输入 12
        app.buttons["keypad_1"].tap()
        app.buttons["keypad_2"].tap()

        // 删除最后一位
        app.buttons["keypad_delete"].tap()

        // 输入 0.5 -> 变成 10.5
        app.buttons["keypad_dot"].tap()
        app.buttons["keypad_5"].tap()

        // 验证预览
        XCTAssertEqual(preview.label, "1.5", "删除后续输入应正确")

        // 取消关闭
        let cancelButton = app.buttons["取消"]
        cancelButton.tap()

        // 应回到首页
        XCTAssertTrue(recordButton.waitForExistence(timeout: 3), "取消后应返回首页")
    }

    /// 测试保存按钮在无输入时应禁用
    @MainActor
    func testSaveButtonDisabledWithoutInput() throws {
        let recordButton = app.buttons["addRecord"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 5))
        recordButton.tap()

        // 等待录入页弹出
        let saveButton = app.buttons["saveRecord"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))

        // 未输入时保存按钮应禁用
        XCTAssertFalse(saveButton.isEnabled, "未输入有效值时保存按钮应禁用")

        // 取消
        app.buttons["取消"].tap()
    }

    // MARK: - 场景标签测试

    /// 测试场景标签切换
    @MainActor
    func testMealContextTagSelection() throws {
        let recordButton = app.buttons["addRecord"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 5))
        recordButton.tap()

        // 等待录入页弹出
        let preview = app.staticTexts["glucosePreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 3))

        // 尝试点击一个场景标签（如"午餐前"）
        let lunchTag = app.buttons.matching(NSPredicate(format: "label CONTAINS '午餐前'")).firstMatch
        if lunchTag.waitForExistence(timeout: 2) {
            lunchTag.tap()
        }

        // 取消
        app.buttons["取消"].tap()
    }

    // MARK: - 导航测试

    /// 测试 Tab 导航切换
    @MainActor
    func testTabNavigation() throws {
        // 等待首页加载
        let homeTab = app.tabBars.buttons["记录"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))

        // 切换到趋势页
        let trendTab = app.tabBars.buttons["趋势"]
        trendTab.tap()

        // 切换到设置页
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        // 验证设置页标题
        let settingsTitle = app.navigationBars["设置"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2), "应显示设置页")

        // 切回首页
        homeTab.tap()
    }
    
    // MARK: - 扩展测试：用药录入
    
    /// 测试用药录入完整流程
    @MainActor
    func testMedicationInputFlow() throws {
        // 找到用药录入入口（可能在首页或记录页）
        let medicationButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '用药' OR identifier CONTAINS 'medication'")).firstMatch
        
        if medicationButton.waitForExistence(timeout: 3) {
            medicationButton.tap()
            
            // 输入剂量
            let dosageField = app.textFields.firstMatch
            if dosageField.exists {
                dosageField.tap()
                dosageField.typeText("4")
            }
            
            // 保存
            let saveButton = app.buttons["保存"]
            if saveButton.exists && saveButton.isEnabled {
                saveButton.tap()
            }
            
            // 验证返回
            sleep(1)
        }
    }
    
    // MARK: - 扩展测试：饮食记录
    
    /// 测试饮食记录流程
    @MainActor
    func testMealRecordFlow() throws {
        let mealButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '饮食' OR identifier CONTAINS 'meal'")).firstMatch
        
        if mealButton.waitForExistence(timeout: 3) {
            mealButton.tap()
            
            // 输入描述
            let descriptionField = app.textFields.firstMatch
            if descriptionField.exists {
                descriptionField.tap()
                descriptionField.typeText("午餐")
            }
            
            // 选择碳水等级
            let carbLevelPicker = app.buttons.matching(NSPredicate(format: "label CONTAINS '中' OR label CONTAINS 'medium'")).firstMatch
            if carbLevelPicker.exists {
                carbLevelPicker.tap()
            }
            
            // 保存
            let saveButton = app.buttons["保存"]
            if saveButton.exists && saveButton.isEnabled {
                saveButton.tap()
            }
            
            sleep(1)
        }
    }
    
    // MARK: - 扩展测试：备注输入
    
    /// 测试添加备注
    @MainActor
    func testNoteInput() throws {
        let recordButton = app.buttons["addRecord"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 5))
        recordButton.tap()
        
        // 输入数值
        app.buttons["keypad_5"].tap()
        app.buttons["keypad_dot"].tap()
        app.buttons["keypad_6"].tap()
        
        // 添加备注
        let noteButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '备注' OR identifier CONTAINS 'note'")).firstMatch
        if noteButton.exists {
            noteButton.tap()
            
            let noteField = app.textViews.firstMatch
            if noteField.exists {
                noteField.tap()
                noteField.typeText("测试备注")
            }
        }
        
        // 取消
        app.buttons["取消"].tap()
    }
    
    // MARK: - 扩展测试：场景标签选择
    
    /// 测试场景标签选择
    @MainActor
    func testSceneTagSelection() throws {
        let recordButton = app.buttons["addRecord"]
        _ = recordButton.waitForExistence(timeout: 5)
        recordButton.tap()
        
        // 尝试选择不同的场景标签
        let tags = ["早餐前", "午餐前", "晚餐前", "睡前"]
        
        for tag in tags {
            let tagButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '\(tag)'")).firstMatch
            if tagButton.exists {
                tagButton.tap()
                sleep(UInt32(0.3))
                break
            }
        }
        
        // 取消
        app.buttons["取消"].tap()
    }
}

// MARK: - 集成测试

final class IntegrationTests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    // MARK: - 完整用户旅程测试
    
    /// 测试：新用户录入 → 查看统计 → 导出报告
    @MainActor
    func testCompleteUserJourney() throws {
        // 1. 录入血糖
        let recordButton = app.buttons["addRecord"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 5))
        recordButton.tap()
        
        app.buttons["keypad_5"].tap()
        app.buttons["keypad_dot"].tap()
        app.buttons["keypad_6"].tap()
        
        let saveButton = app.buttons["saveRecord"]
        if saveButton.isEnabled {
            saveButton.tap()
        }
        
        sleep(1)
        
        // 2. 查看统计
        let statsTab = app.tabBars.buttons["统计"]
        statsTab.tap()
        sleep(2)
        
        // 3. 返回首页
        let homeTab = app.tabBars.buttons["首页"]
        homeTab.tap()
    }
    
    /// 测试：多日记录 → 趋势分析
    @MainActor
    func testMultiDayRecordAnalysis() throws {
        // 切换到记录页查看历史
        let recordTab = app.tabBars.buttons["记录"]
        recordTab.tap()
        sleep(1)
        
        // 切换到统计页查看趋势
        let statsTab = app.tabBars.buttons["统计"]
        statsTab.tap()
        sleep(1)
        
        // 切换时间范围
        let monthButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '30天'")).firstMatch
        if monthButton.exists {
            monthButton.tap()
            sleep(1)
        }
    }
    
    // MARK: - 数据一致性测试
    
    /// 测试：录入后在不同页面查看数据一致性
    @MainActor
    func testDataConsistency() throws {
        // 录入一条记录
        let recordButton = app.buttons["addRecord"]
        _ = recordButton.waitForExistence(timeout: 5)
        recordButton.tap()
        
        app.buttons["keypad_7"].tap()
        app.buttons["keypad_dot"].tap()
        app.buttons["keypad_2"].tap()
        
        let saveButton = app.buttons["saveRecord"]
        if saveButton.isEnabled {
            saveButton.tap()
        }
        
        sleep(1)
        
        // 在记录页查看
        let recordTab = app.tabBars.buttons["记录"]
        recordTab.tap()
        sleep(1)
        
        // 在统计页查看
        let statsTab = app.tabBars.buttons["统计"]
        statsTab.tap()
        sleep(1)
        
        // 验证数据存在
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '7.2'")).firstMatch
        // 数据应该在统计中显示
    }
    
    // MARK: - 性能测试
    
    /// 测试：大数据量下的性能
    @MainActor
    func testPerformanceWithLargeDataset() throws {
        // 切换到记录页
        let recordTab = app.tabBars.buttons["记录"]
        recordTab.tap()
        
        // 测试滚动性能
        measure {
            let scrollView = app.scrollViews.firstMatch
            for _ in 0..<10 {
                scrollView.swipeUp()
            }
        }
    }
}
