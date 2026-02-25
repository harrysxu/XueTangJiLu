//
//  UITestHelpers.swift
//  XueTangJiLuUITests
//
//  Created by AI Assistant on 2026/2/23.
//

import XCTest

/// UI测试辅助工具集
extension XCTestCase {
    
    // MARK: - 等待元素
    
    /// 等待元素出现
    /// - Parameters:
    ///   - element: 要等待的元素
    ///   - timeout: 超时时间（秒）
    /// - Returns: 元素是否在超时前出现
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    /// 等待元素消失
    /// - Parameters:
    ///   - element: 要等待消失的元素
    ///   - timeout: 超时时间（秒）
    /// - Returns: 元素是否在超时前消失
    @discardableResult
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// 等待元素可点击
    /// - Parameters:
    ///   - element: 要等待的元素
    ///   - timeout: 超时时间（秒）
    /// - Returns: 元素是否在超时前变为可点击
    @discardableResult
    func waitForElementToBeHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    // MARK: - 安全点击
    
    /// 安全点击元素（先等待元素可点击）
    /// - Parameters:
    ///   - element: 要点击的元素
    ///   - timeout: 超时时间（秒）
    func safeTap(_ element: XCUIElement, timeout: TimeInterval = 5) {
        XCTAssertTrue(waitForElementToBeHittable(element, timeout: timeout), "元素在超时前未变为可点击: \(element)")
        element.tap()
    }
    
    /// 点击并等待导航完成
    /// - Parameters:
    ///   - element: 要点击的元素
    ///   - destinationElement: 目标页面的元素
    ///   - timeout: 超时时间（秒）
    func tapAndWaitForNavigation(_ element: XCUIElement, destinationElement: XCUIElement, timeout: TimeInterval = 5) {
        element.tap()
        XCTAssertTrue(waitForElement(destinationElement, timeout: timeout), "导航后目标元素未出现")
    }
    
    // MARK: - 文本输入
    
    /// 清空并输入文本
    /// - Parameters:
    ///   - element: 文本输入框
    ///   - text: 要输入的文本
    func clearAndType(_ element: XCUIElement, text: String) {
        element.tap()
        
        // 如果有现有文本，先清空
        if let value = element.value as? String, !value.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)
            element.typeText(deleteString)
        }
        
        element.typeText(text)
    }
    
    // MARK: - 截图
    
    /// 截图并附加到测试结果
    /// - Parameter name: 截图名称
    func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// 失败时自动截图
    func screenshotOnFailure() {
        if testRun?.hasSucceeded == false {
            takeScreenshot(named: "失败截图-\(name)")
        }
    }
    
    // MARK: - 滚动
    
    /// 滚动到元素可见
    /// - Parameter element: 要滚动到的元素
    func scrollToElement(_ element: XCUIElement) {
        while !element.isHittable {
            let app = XCUIApplication()
            app.swipeUp()
            
            // 防止无限循环
            if !element.exists {
                break
            }
        }
    }
    
    /// 向上滚动到顶部
    func scrollToTop(in app: XCUIApplication) {
        app.swipeDown()
        app.swipeDown()
    }
    
    // MARK: - 键盘
    
    /// 关闭键盘
    func dismissKeyboard() {
        let app = XCUIApplication()
        app.keyboards.buttons["完成"].tap()
    }
    
    /// 检查键盘是否显示
    /// - Returns: 键盘是否可见
    func isKeyboardVisible() -> Bool {
        return XCUIApplication().keyboards.count > 0
    }
    
    // MARK: - 等待加载
    
    /// 等待加载指示器消失
    /// - Parameter timeout: 超时时间（秒）
    func waitForLoadingToComplete(timeout: TimeInterval = 10) {
        let app = XCUIApplication()
        let loadingIndicator = app.activityIndicators.firstMatch
        waitForElementToDisappear(loadingIndicator, timeout: timeout)
    }
    
    // MARK: - Tab 导航
    
    /// 切换到指定 Tab
    /// - Parameters:
    ///   - tabName: Tab 名称
    ///   - app: XCUIApplication 实例
    func switchToTab(_ tabName: String, in app: XCUIApplication) {
        let tabButton = app.tabBars.buttons[tabName]
        safeTap(tabButton)
    }
    
    // MARK: - Alert 处理
    
    /// 点击 Alert 按钮
    /// - Parameters:
    ///   - buttonTitle: 按钮标题
    ///   - timeout: 超时时间（秒）
    func tapAlertButton(_ buttonTitle: String, timeout: TimeInterval = 5) {
        let app = XCUIApplication()
        let alertButton = app.alerts.buttons[buttonTitle]
        if waitForElement(alertButton, timeout: timeout) {
            alertButton.tap()
        }
    }
    
    // MARK: - 数据清理
    
    /// 重置应用状态（需要应用支持 --uitesting 参数）
    func resetAppState() {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--reset")
        app.launch()
    }
    
    // MARK: - 断言辅助
    
    /// 断言元素存在且可见
    /// - Parameter element: 要检查的元素
    func assertElementExistsAndVisible(_ element: XCUIElement, message: String = "") {
        XCTAssertTrue(element.exists, "元素不存在: \(message)")
        XCTAssertTrue(element.isHittable, "元素不可见: \(message)")
    }
    
    /// 断言元素不存在
    /// - Parameter element: 要检查的元素
    func assertElementDoesNotExist(_ element: XCUIElement, message: String = "") {
        XCTAssertFalse(element.exists, "元素不应该存在: \(message)")
    }
    
    /// 断言文本匹配
    /// - Parameters:
    ///   - element: 包含文本的元素
    ///   - expectedText: 期望的文本
    func assertTextEquals(_ element: XCUIElement, _ expectedText: String) {
        XCTAssertEqual(element.label, expectedText, "文本不匹配")
    }
    
    /// 断言文本包含
    /// - Parameters:
    ///   - element: 包含文本的元素
    ///   - substring: 期望包含的子字符串
    func assertTextContains(_ element: XCUIElement, _ substring: String) {
        XCTAssertTrue(element.label.contains(substring), "文本不包含期望的子字符串: \(substring)")
    }
}

// MARK: - 常用查询扩展

extension XCUIApplication {
    
    /// 查找包含指定文本的按钮
    func buttonContaining(_ text: String) -> XCUIElement {
        return buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }
    
    /// 查找包含指定文本的静态文本
    func textContaining(_ text: String) -> XCUIElement {
        return staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }
    
    /// 查找指定 accessibility identifier 的元素
    func elementWithIdentifier(_ identifier: String) -> XCUIElement {
        return descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
