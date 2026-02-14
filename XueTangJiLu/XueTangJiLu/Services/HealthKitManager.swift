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
/// 封装血糖、运动数据的读写操作，作为 Apple Health 的桥接层
@Observable
final class HealthKitManager {

    // MARK: - 属性

    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false

    /// 今日步数
    private(set) var todaySteps: Int = 0

    /// 今日运动分钟
    private(set) var todayExerciseMinutes: Int = 0

    /// HealthKit 是否可用（iPad 不支持）
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - 权限请求

    /// 请求血糖 + 运动数据读写权限
    func requestAuthorization() async throws {
        guard isAvailable else { return }

        let bloodGlucoseType = HKQuantityType(.bloodGlucose)
        let stepCountType = HKQuantityType(.stepCount)
        let exerciseTimeType = HKQuantityType(.appleExerciseTime)

        let typesToShare: Set<HKSampleType> = [bloodGlucoseType]
        let typesToRead: Set<HKObjectType> = [
            bloodGlucoseType,
            stepCountType,
            exerciseTimeType
        ]

        try await healthStore.requestAuthorization(
            toShare: typesToShare,
            read: typesToRead
        )
        isAuthorized = true
    }

    // MARK: - 写入血糖数据

    /// 将血糖记录写入 HealthKit
    func saveGlucose(value: Double, date: Date, mealContext: MealContext) async throws {
        guard isAvailable, isAuthorized else { return }

        let bloodGlucoseType = HKQuantityType(.bloodGlucose)
        let unit = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose)
            .unitDivided(by: .liter())
        let quantity = HKQuantity(unit: unit, doubleValue: value)

        var metadata: [String: Any] = [
            HKMetadataKeyWasUserEntered: true
        ]

        if let hkMealTime = mealContext.healthKitMealTime {
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

    // MARK: - 运动数据

    /// 获取今日步数
    func fetchTodaySteps() async {
        guard isAvailable, isAuthorized else { return }

        let stepType = HKQuantityType(.stepCount)
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: .now,
            options: .strictStartDate
        )

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            todaySteps = Int(steps)
        } catch {
            print("获取步数失败: \(error)")
        }
    }

    /// 获取今日运动分钟
    func fetchTodayExerciseMinutes() async {
        guard isAvailable, isAuthorized else { return }

        let exerciseType = HKQuantityType(.appleExerciseTime)
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: .now,
            options: .strictStartDate
        )

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: exerciseType, predicate: predicate),
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            let minutes = result?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
            todayExerciseMinutes = Int(minutes)
        } catch {
            print("获取运动分钟失败: \(error)")
        }
    }

    /// 获取指定日期范围内的每日步数
    func fetchDailySteps(from startDate: Date, to endDate: Date) async -> [(Date, Int)] {
        guard isAvailable, isAuthorized else { return [] }

        let stepType = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )

        do {
            let collection = try await descriptor.result(for: healthStore)
            var results: [(Date, Int)] = []

            collection.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                let steps = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
                results.append((stats.startDate, Int(steps)))
            }

            return results
        } catch {
            print("获取每日步数失败: \(error)")
            return []
        }
    }

    /// 刷新运动数据
    func refreshActivityData() async {
        await fetchTodaySteps()
        await fetchTodayExerciseMinutes()
    }
}
