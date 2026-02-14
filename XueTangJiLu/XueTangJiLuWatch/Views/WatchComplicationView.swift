//
//  WatchComplicationView.swift
//  XueTangJiLuWatch
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import WidgetKit
import SwiftData

/// Watch Complication - 表盘显示最新血糖
/// 注意：需要在 Xcode 中创建 Widget Extension (watchOS) target
struct WatchComplicationEntry: TimelineEntry {
    let date: Date
    let value: Double?
    let unit: GlucoseUnit
    let level: GlucoseLevel?
}

struct WatchComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchComplicationEntry {
        WatchComplicationEntry(date: .now, value: 5.6, unit: .mmolL, level: .normal)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        completion(WatchComplicationEntry(date: .now, value: 5.6, unit: .mmolL, level: .normal))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        // 从 App Group 读取最新数据
        let entry = WatchComplicationEntry(date: .now, value: nil, unit: .mmolL, level: nil)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(30 * 60)))
        completion(timeline)
    }
}

struct WatchComplicationCircularView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        ZStack {
            if let value = entry.value, let level = entry.level {
                VStack(spacing: 0) {
                    Text(GlucoseUnitConverter.displayString(mmolLValue: value, in: entry.unit))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(level.colorName))

                    Text(entry.unit.rawValue)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "drop.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
