//
//  MockHealthKitManager.swift
//  XueTangJiLuTests
//
//  Created by AI Assistant on 2026/2/23.
//

import Foundation
import HealthKit
@testable import XueTangJiLu

/// HealthKitManager 协议，用于测试注入
protocol HealthKitManagerProtocol {
    var isAuthorized: Bool { get }
    var isAvailable: Bool { get }
    var todaySteps: Int { get }
    var todayExerciseMinutes: Int { get }
    
    func requestAuthorization() async throws
    func saveGlucose(value: Double, date: Date, sceneTagId: String) async throws
    func fetchGlucoseRecords(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample]
    func isDuplicate(date: Date) async throws -> Bool
}

/// Mock HealthKitManager，用于单元测试
final class MockHealthKitManager: HealthKitManagerProtocol {
    
    // MARK: - 控制属性
    
    /// 是否已授权
    var isAuthorized: Bool = true
    
    /// 是否可用
    var isAvailable: Bool = true
    
    /// 今日步数
    var todaySteps: Int = 0
    
    /// 今日运动分钟
    var todayExerciseMinutes: Int = 0
    
    /// 是否应该抛出错误
    var shouldThrowError: Bool = false
    
    /// 模拟的错误
    var errorToThrow: Error = MockError.simulatedError
    
    // MARK: - 记录调用
    
    /// 是否调用了 requestAuthorization
    var requestAuthorizationCalled: Bool = false
    
    /// 是否调用了 saveGlucose
    var saveGlucoseCalled: Bool = false
    
    /// 保存的血糖值
    var savedGlucoseValues: [(value: Double, date: Date, sceneTagId: String)] = []
    
    /// 是否调用了 fetchGlucoseRecords
    var fetchGlucoseRecordsCalled: Bool = false
    
    /// 模拟的查询结果
    var mockGlucoseRecords: [HKQuantitySample] = []
    
    /// 是否调用了 isDuplicate
    var isDuplicateCalled: Bool = false
    
    /// 模拟的重复检查结果
    var mockIsDuplicate: Bool = false
    
    // MARK: - 协议实现
    
    func requestAuthorization() async throws {
        requestAuthorizationCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        isAuthorized = true
    }
    
    func saveGlucose(value: Double, date: Date, sceneTagId: String) async throws {
        saveGlucoseCalled = true
        savedGlucoseValues.append((value, date, sceneTagId))
        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    func fetchGlucoseRecords(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        fetchGlucoseRecordsCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return mockGlucoseRecords
    }
    
    func isDuplicate(date: Date) async throws -> Bool {
        isDuplicateCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return mockIsDuplicate
    }
    
    // MARK: - 辅助方法
    
    /// 重置所有状态
    func reset() {
        isAuthorized = true
        isAvailable = true
        shouldThrowError = false
        requestAuthorizationCalled = false
        saveGlucoseCalled = false
        savedGlucoseValues.removeAll()
        fetchGlucoseRecordsCalled = false
        mockGlucoseRecords.removeAll()
        isDuplicateCalled = false
        mockIsDuplicate = false
        todaySteps = 0
        todayExerciseMinutes = 0
    }
}

/// Mock 错误类型
enum MockError: Error, LocalizedError {
    case simulatedError
    case authorizationFailed
    case saveFailed
    case fetchFailed
    
    var errorDescription: String? {
        switch self {
        case .simulatedError:
            return "模拟错误"
        case .authorizationFailed:
            return "授权失败"
        case .saveFailed:
            return "保存失败"
        case .fetchFailed:
            return "查询失败"
        }
    }
}
