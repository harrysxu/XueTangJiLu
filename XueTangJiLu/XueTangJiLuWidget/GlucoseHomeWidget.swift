//
//  GlucoseHomeWidget.swift
//  XueTangJiLuWidget
//
//  Created by XueTangJiLu on 2026/2/14.
//

import WidgetKit
import SwiftUI
import Charts

/// 主屏幕 Widget：统一支持所有尺寸，根据 widgetFamily 自动切换布局
struct GlucoseHomeWidget: Widget {
    let kind: String = "GlucoseHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GlucoseTimelineProvider()) { entry in
            GlucoseHomeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("血糖记录")
        .description("显示最新血糖读数、趋势和记录")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

// MARK: - 根据尺寸分发视图

struct GlucoseHomeWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: GlucoseWidgetEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallGlucoseWidgetView(entry: entry)
        case .systemMedium:
            MediumGlucoseWidgetView(entry: entry)
        case .systemLarge:
            LargeGlucoseWidgetView(entry: entry)
        case .systemExtraLarge:
            ExtraLargeGlucoseWidgetView(entry: entry)
        default:
            SmallGlucoseWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    GlucoseHomeWidget()
} timeline: {
    GlucoseWidgetEntry.placeholder
    GlucoseWidgetEntry.empty
}

#Preview("Medium", as: .systemMedium) {
    GlucoseHomeWidget()
} timeline: {
    GlucoseWidgetEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    GlucoseHomeWidget()
} timeline: {
    GlucoseWidgetEntry.placeholder
    GlucoseWidgetEntry.empty
}

#Preview("ExtraLarge", as: .systemExtraLarge) {
    GlucoseHomeWidget()
} timeline: {
    GlucoseWidgetEntry.placeholder
    GlucoseWidgetEntry.empty
}
