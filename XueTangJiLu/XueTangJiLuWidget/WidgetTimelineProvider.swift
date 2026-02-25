//
//  WidgetTimelineProvider.swift
//  XueTangJiLuWidget
//
//  Created by XueTangJiLu on 2026/2/14.
//

import WidgetKit
import SwiftData
import Foundation

/// Widget 数据提供者 - 从 App Groups 共享的 SwiftData 读取数据
struct GlucoseTimelineProvider: TimelineProvider {

    typealias Entry = GlucoseWidgetEntry

    // MARK: - TimelineProvider

    func placeholder(in context: Context) -> GlucoseWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (GlucoseWidgetEntry) -> Void) {
        let entry = fetchLatestEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GlucoseWidgetEntry>) -> Void) {
        let entry = fetchLatestEntry()

        // 每 30 分钟刷新一次
        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: AppConstants.widgetRefreshInterval,
            to: .now
        )!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - 数据查询

    private func fetchLatestEntry() -> GlucoseWidgetEntry {
        do {
            let schema = Schema([GlucoseRecord.self, UserSettings.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(AppConstants.appGroupID),
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)

            // 获取用户设置
            let settingsDescriptor = FetchDescriptor<UserSettings>()
            let settings = try context.fetch(settingsDescriptor).first
            let unitRawValue = settings?.preferredUnitRawValue ?? GlucoseUnit.systemDefault.rawValue

            // 获取最新记录
            var latestDescriptor = FetchDescriptor<GlucoseRecord>(
                sortBy: [SortDescriptor(\GlucoseRecord.timestamp, order: .reverse)]
            )
            latestDescriptor.fetchLimit = 1
            let latestRecords = try context.fetch(latestDescriptor)
            let latest = latestRecords.first

            // 解析最新记录的场景标签
            let latestTagLabel: String?
            let latestTagIcon: String?
            if let latest {
                latestTagLabel = resolveTagLabel(tagId: latest.sceneTagId, settings: settings)
                latestTagIcon = resolveTagIcon(tagId: latest.sceneTagId, settings: settings)
            } else {
                latestTagLabel = nil
                latestTagIcon = nil
            }

            // 获取 7 天内记录（用于趋势图和 TIR）
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
            let weekDescriptor = FetchDescriptor<GlucoseRecord>(
                predicate: #Predicate<GlucoseRecord> { record in
                    record.timestamp >= sevenDaysAgo
                },
                sortBy: [SortDescriptor(\GlucoseRecord.timestamp)]
            )
            let weekRecords = try context.fetch(weekDescriptor)

            // 计算 TIR（逐条按场景阈值评判）
            let tirValue: Double
            if weekRecords.isEmpty {
                tirValue = 0
            } else if let settings {
                let inRange = weekRecords.filter { record in
                    let range = settings.thresholdRange(for: record.sceneTagId)
                    return record.value >= range.low && record.value <= range.high
                }
                tirValue = Double(inRange.count) / Double(weekRecords.count) * 100.0
            } else {
                let inRange = weekRecords.filter { $0.value >= 3.9 && $0.value <= 10.0 }
                tirValue = Double(inRange.count) / Double(weekRecords.count) * 100.0
            }

            // 趋势数据点
            let weekTrend: [(Date, Double)] = weekRecords.map { ($0.timestamp, $0.value) }

            // 最近 5 条记录（用于大号 Widget）
            var recentDescriptor = FetchDescriptor<GlucoseRecord>(
                sortBy: [SortDescriptor(\GlucoseRecord.timestamp, order: .reverse)]
            )
            recentDescriptor.fetchLimit = 5
            let recentRecords = try context.fetch(recentDescriptor)
            let recentData: [WidgetRecordData] = recentRecords.map { record in
                WidgetRecordData(
                    value: record.value,
                    timestamp: record.timestamp,
                    sceneTagLabel: resolveTagLabel(tagId: record.sceneTagId, settings: settings),
                    sceneTagIcon: resolveTagIcon(tagId: record.sceneTagId, settings: settings),
                    note: record.note
                )
            }

            // 7 日统计
            let weekValues = weekRecords.map(\.value)
            let weekAverage = weekValues.isEmpty ? nil : weekValues.reduce(0, +) / Double(weekValues.count)
            let weekMin = weekValues.min()
            let weekMax = weekValues.max()

            return GlucoseWidgetEntry(
                date: .now,
                latestValue: latest?.value,
                latestTime: latest?.timestamp,
                sceneTagLabel: latestTagLabel,
                sceneTagIcon: latestTagIcon,
                unitRawValue: unitRawValue,
                tirValue: tirValue,
                weekTrend: weekTrend,
                recentRecords: recentData,
                weekAverage: weekAverage,
                weekMin: weekMin,
                weekMax: weekMax,
                weekCount: weekRecords.count
            )
        } catch {
            // 数据库读取失败，返回空数据
            return .empty
        }
    }

    // MARK: - 标签解析辅助

    private func resolveTagLabel(tagId: String, settings: UserSettings?) -> String {
        if let settings {
            return settings.displayName(for: tagId)
        }
        return MealContext(rawValue: tagId)?.localizedDisplayName ?? String(localized: "meal.other")
    }

    private func resolveTagIcon(tagId: String, settings: UserSettings?) -> String {
        if let settings {
            return settings.iconName(for: tagId)
        }
        return MealContext(rawValue: tagId)?.iconName ?? "clock"
    }
}
