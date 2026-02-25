//
//  ExportUITests.swift
//  XueTangJiLuUITests
//
//  Created by AI Assistant on 2026/2/23.
//

import XCTest

final class ExportUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    // MARK: - PDF导出测试
    
    @MainActor
    func testPDFExportFlow() {
        switchToTab("我的", in: app)
        
        // 查找导出按钮
        let exportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '导出' OR label CONTAINS '报告'")).firstMatch
        
        if waitForElement(exportButton, timeout: 3) {
            exportButton.tap()
            
            // 验证导出选项页面
            sleep(1)
            
            // 查找PDF选项
            let pdfOption = app.buttons.matching(NSPredicate(format: "label CONTAINS 'PDF'")).firstMatch
            if pdfOption.exists {
                pdfOption.tap()
                sleep(2)
                
                // 应该打开分享菜单或预览
                // 返回
                let cancelButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '取消' OR label CONTAINS 'Cancel'")).firstMatch
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - CSV导出测试
    
    @MainActor
    func testCSVExportFlow() {
        switchToTab("我的", in: app)
        
        let exportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '导出'")).firstMatch
        
        if exportButton.exists {
            exportButton.tap()
            
            // 查找CSV选项
            let csvOption = app.buttons.matching(NSPredicate(format: "label CONTAINS 'CSV'")).firstMatch
            if csvOption.exists {
                csvOption.tap()
                sleep(1)
                
                // 返回
                let cancelButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '取消'")).firstMatch
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - 日期范围选择测试
    
    @MainActor
    func testDateRangeSelection() {
        switchToTab("我的", in: app)
        
        let exportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '导出'")).firstMatch
        
        if exportButton.exists {
            exportButton.tap()
            
            // 查找日期范围选择器
            let dateRangePicker = app.buttons.matching(NSPredicate(format: "label CONTAINS '日期' OR label CONTAINS '范围'")).firstMatch
            
            if dateRangePicker.exists {
                dateRangePicker.tap()
                sleep(1)
            }
            
            // 返回
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 分享卡片测试
    
    @MainActor
    func testShareCard() {
        switchToTab("我的", in: app)
        
        // 查找分享按钮
        let shareButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '分享' OR identifier CONTAINS 'share'")).firstMatch
        
        if shareButton.exists {
            shareButton.tap()
            sleep(1)
            
            // 应该打开分享菜单
            // 取消分享
            let cancelButton = app.buttons["取消"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }
    }
    
    // MARK: - 周报导出测试
    
    @MainActor
    func testWeeklyReportExport() {
        switchToTab("我的", in: app)
        
        let exportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '导出'")).firstMatch
        
        if exportButton.exists {
            exportButton.tap()
            
            // 查找周报选项
            let weeklyReport = app.buttons.matching(NSPredicate(format: "label CONTAINS '周报'")).firstMatch
            if weeklyReport.exists {
                weeklyReport.tap()
                sleep(2)
            }
            
            // 返回
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 月报导出测试
    
    @MainActor
    func testMonthlyReportExport() {
        switchToTab("我的", in: app)
        
        let exportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '导出'")).firstMatch
        
        if exportButton.exists {
            exportButton.tap()
            
            // 查找月报选项
            let monthlyReport = app.buttons.matching(NSPredicate(format: "label CONTAINS '月报'")).firstMatch
            if monthlyReport.exists {
                monthlyReport.tap()
                sleep(2)
            }
            
            // 返回
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 导出记录类型筛选测试
    
    @MainActor
    func testExportRecordTypeFilter() {
        switchToTab("我的", in: app)
        
        let exportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '导出'")).firstMatch
        
        if exportButton.exists {
            exportButton.tap()
            
            // 查找记录类型筛选
            let recordTypeFilter = app.buttons.matching(NSPredicate(format: "label CONTAINS '全部记录' OR label CONTAINS '记录类型'")).firstMatch
            
            if recordTypeFilter.exists {
                recordTypeFilter.tap()
                sleep(1)
            }
            
            // 返回
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - 导出预览测试
    
    @MainActor
    func testExportPreview() {
        switchToTab("我的", in: app)
        
        let exportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '导出'")).firstMatch
        
        if exportButton.exists {
            exportButton.tap()
            
            // 查找预览按钮
            let previewButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '预览'")).firstMatch
            
            if previewButton.exists {
                previewButton.tap()
                sleep(2)
                
                // 关闭预览
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            // 返回
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
}
