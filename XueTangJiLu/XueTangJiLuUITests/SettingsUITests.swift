//
//  SettingsUITests.swift
//  XueTangJiLuUITests
//
//  Created by AI Assistant on 2026/2/23.
//

import XCTest

final class SettingsUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    // MARK: - 设置页加载测试
    
    @MainActor
    func testSettingsViewLoads() {
        switchToTab("我的", in: app)
        
        // 查找设置入口
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '设置' OR label CONTAINS 'Settings'")).firstMatch
        
        if waitForElement(settingsButton, timeout: 3) {
            settingsButton.tap()
            
            // 验证设置页打开
            let settingsTitle = app.navigationBars["设置"]
            XCTAssertTrue(waitForElement(settingsTitle), "设置页应该打开")
            
            // 返回
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 单位切换测试
    
    @MainActor
    func testUnitSelection() {
        switchToTab("我的", in: app)
        
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '设置'")).firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            
            // 查找单位设置
            let unitSetting = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '单位' OR label CONTAINS 'mmol'")).firstMatch
            
            if unitSetting.exists {
                unitSetting.tap()
                sleep(1)
                
                // 返回
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 标签管理测试
    
    @MainActor
    func testTagManagement() {
        switchToTab("我的", in: app)
        
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '设置'")).firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            
            // 查找标签管理
            let tagManagement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '标签' OR label CONTAINS '场景'")).firstMatch
            
            if tagManagement.exists {
                tagManagement.tap()
                sleep(1)
                
                // 返回
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 阈值配置测试
    
    @MainActor
    func testThresholdConfiguration() {
        switchToTab("我的", in: app)
        
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '设置'")).firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            
            // 查找阈值设置
            let thresholdSetting = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '阈值' OR label CONTAINS '目标'")).firstMatch
            
            if thresholdSetting.exists {
                thresholdSetting.tap()
                sleep(1)
                
                // 返回
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - HealthKit开关测试
    
    @MainActor
    func testHealthKitToggle() {
        switchToTab("我的", in: app)
        
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '设置'")).firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            
            // 查找HealthKit开关
            let healthKitSwitch = app.switches.matching(NSPredicate(format: "identifier CONTAINS 'healthkit' OR label CONTAINS 'Health'")).firstMatch
            
            if healthKitSwitch.exists {
                // 不实际切换，避免触发权限请求
                XCTAssertTrue(healthKitSwitch.isHittable, "HealthKit开关应该可见")
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 同步设置测试
    
    @MainActor
    func testSyncSettings() {
        switchToTab("我的", in: app)
        
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '设置'")).firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            
            // 查找同步设置
            let syncSetting = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '同步' OR label CONTAINS 'iCloud'")).firstMatch
            
            if syncSetting.exists {
                syncSetting.tap()
                sleep(1)
                
                // 返回
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 提醒设置测试
    
    @MainActor
    func testReminderSettings() {
        switchToTab("我的", in: app)
        
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '设置'")).firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            
            // 查找提醒设置
            let reminderSetting = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '提醒'")).firstMatch
            
            if reminderSetting.exists {
                reminderSetting.tap()
                sleep(1)
                
                // 返回
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 关于页面测试
    
    @MainActor
    func testAboutPage() {
        switchToTab("我的", in: app)
        
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '设置'")).firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            
            // 查找关于
            let aboutButton = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '关于'")).firstMatch
            
            if aboutButton.exists {
                aboutButton.tap()
                sleep(1)
                
                // 返回
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 显示模式切换测试
    
    @MainActor
    func testDisplayModeToggle() {
        switchToTab("我的", in: app)
        
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '设置'")).firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            
            // 查找显示模式设置
            let displayModeSetting = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '显示模式' OR label CONTAINS '简化'")).firstMatch
            
            if displayModeSetting.exists {
                displayModeSetting.tap()
                sleep(1)
                
                // 返回
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
}
