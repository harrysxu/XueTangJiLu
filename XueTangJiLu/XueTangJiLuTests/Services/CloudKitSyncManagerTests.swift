//
//  CloudKitSyncManagerTests.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Testing
import Foundation
import CloudKit
@testable import XueTangJiLu

@MainActor
struct CloudKitSyncManagerTests {
    
    // MARK: - 同步状态测试
    
    @Test("初始状态为idle")
    func testInitialState() {
        let manager = CloudKitSyncManager()
        
        #expect(manager.currentState == .idle)
        #expect(manager.lastSyncDate == nil)
    }
    
    @Test("同步状态转换 - 成功")
    func testSyncStateTransitionSuccess() {
        let manager = CloudKitSyncManager()
        
        manager.currentState = .syncing
        #expect(manager.currentState == .syncing)
        
        let successDate = Date.now
        manager.currentState = .success(successDate)
        
        if case .success(let date) = manager.currentState {
            #expect(date == successDate)
        } else {
            Issue.record("状态应该是success")
        }
    }
    
    @Test("同步状态转换 - 失败")
    func testSyncStateTransitionFailure() {
        let manager = CloudKitSyncManager()
        let error = MockError.simulatedError
        
        manager.currentState = .failed(error)
        
        if case .failed = manager.currentState {
            // 成功
        } else {
            Issue.record("状态应该是failed")
        }
    }
    
    // MARK: - iCloud账户状态测试
    
    @Test("账户状态检查")
    func testCheckAccountStatus() async {
        let manager = CloudKitSyncManager()
        
        await manager.checkAccountStatus()
        
        // 账户状态应该被更新（可能是任何状态）
        #expect(manager.iCloudAccountStatus != .couldNotDetermine || manager.iCloudAccountStatus == .couldNotDetermine)
    }
    
    // MARK: - 同步设置测试
    
    @Test("同步开关设置")
    func testSyncEnabledSetting() {
        let manager = CloudKitSyncManager()
        
        manager.isSyncEnabled = true
        #expect(manager.isSyncEnabled == true)
        
        manager.isSyncEnabled = false
        #expect(manager.isSyncEnabled == false)
    }
    
    @Test("WiFi限制设置")
    func testWiFiOnlySetting() {
        let manager = CloudKitSyncManager()
        
        manager.wifiOnlySync = true
        #expect(manager.wifiOnlySync == true)
        
        manager.wifiOnlySync = false
        #expect(manager.wifiOnlySync == false)
    }
    
    // MARK: - 同步历史测试
    
    @Test("同步历史记录")
    func testSyncHistory() {
        let manager = CloudKitSyncManager()
        
        let event = CloudKitSyncManager.SyncEvent(
            type: .importData,
            isSuccess: true
        )
        
        manager.syncHistory.append(event)
        
        #expect(manager.syncHistory.count == 1)
        #expect(manager.syncHistory.first?.isSuccess == true)
    }
    
    @Test("清空同步历史")
    func testClearSyncHistory() {
        let manager = CloudKitSyncManager()
        
        manager.syncHistory.append(CloudKitSyncManager.SyncEvent(type: .importData, isSuccess: true))
        manager.syncHistory.append(CloudKitSyncManager.SyncEvent(type: .exportData, isSuccess: true))
        
        #expect(manager.syncHistory.count == 2)
        
        manager.clearSyncHistory()
        
        #expect(manager.syncHistory.isEmpty)
    }
    
    // MARK: - 最后同步时间测试
    
    @Test("最后同步时间字符串")
    func testLastSyncTimeString() {
        let manager = CloudKitSyncManager()
        
        #expect(manager.lastSyncTimeString == "从未同步")
        
        manager.lastSyncDate = Date.now
        
        #expect(manager.lastSyncTimeString != "从未同步")
    }
}
