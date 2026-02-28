//
//  HealthKitManager.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import HealthKit
import Observation

/// HealthKit 数据管理器
/// 封装血糖数据的读写操作，作为 Apple Health 的桥接层
@Observable
final class HealthKitManager {

    // MARK: - 属性

    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false

    /// HealthKit 是否可用（iPad 不支持）
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - 权限请求

    /// 请求血糖数据读写权限
    func requestAuthorization() async throws {
        guard isAvailable else { return }

        let bloodGlucoseType = HKQuantityType(.bloodGlucose)

        let typesToShare: Set<HKSampleType> = [bloodGlucoseType]
        let typesToRead: Set<HKObjectType> = [bloodGlucoseType]

        try await healthStore.requestAuthorization(
            toShare: typesToShare,
            read: typesToRead
        )
        isAuthorized = true
    }

    // MARK: - 写入血糖数据

    /// 将血糖记录写入 HealthKit
    /// - Parameters:
    ///   - value: 血糖值 (mmol/L)
    ///   - date: 记录时间
    ///   - sceneTagId: 场景标签 ID，用于映射 HealthKit 的 MealTime
    func saveGlucose(value: Double, date: Date, sceneTagId: String) async throws {
        guard isAvailable, isAuthorized else { return }

        let bloodGlucoseType = HKQuantityType(.bloodGlucose)
        let unit = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose)
            .unitDivided(by: .liter())
        let quantity = HKQuantity(unit: unit, doubleValue: value)

        var metadata: [String: Any] = [
            HKMetadataKeyWasUserEntered: true
        ]

        // 仅内置标签有 HealthKit MealTime 映射
        if let mealContext = MealContext(rawValue: sceneTagId),
           let hkMealTime = mealContext.healthKitMealTime {
            metadata[HKMetadataKeyBloodGlucoseMealTime] = hkMealTime
        }

        let sample = HKQuantitySample(
            type: bloodGlucoseType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: metadata
        )

        try await healthStore.save(sample)
    }

    // MARK: - 查询血糖数据

    /// 查询指定日期范围内的血糖记录
    func fetchGlucoseRecords(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard isAvailable, isAuthorized else { return [] }

        let bloodGlucoseType = HKQuantityType(.bloodGlucose)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .reverse)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: bloodGlucoseType, predicate: predicate)],
            sortDescriptors: [sortDescriptor]
        )

        return try await descriptor.result(for: healthStore)
    }

    // MARK: - 统计查询

    /// 获取指定范围内的平均血糖
    func fetchAverageGlucose(from startDate: Date, to endDate: Date) async throws -> Double? {
        guard isAvailable, isAuthorized else { return nil }

        let bloodGlucoseType = HKQuantityType(.bloodGlucose)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: bloodGlucoseType, predicate: predicate),
            options: .discreteAverage
        )

        let result = try await descriptor.result(for: healthStore)
        let unit = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose)
            .unitDivided(by: .liter())
        return result?.averageQuantity()?.doubleValue(for: unit)
    }

    // MARK: - 防重复

    /// 检查 HealthKit 中是否已存在相同时间戳的记录
    func isDuplicate(date: Date) async throws -> Bool {
        guard isAvailable, isAuthorized else { return false }

        let bloodGlucoseType = HKQuantityType(.bloodGlucose)
        let startDate = Calendar.current.date(byAdding: .second, value: -1, to: date)!
        let endDate = Calendar.current.date(byAdding: .second, value: 1, to: date)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: bloodGlucoseType, predicate: predicate)],
            sortDescriptors: [],
            limit: 1
        )

        let results = try await descriptor.result(for: healthStore)
        return !results.isEmpty
    }

}
