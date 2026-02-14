//
//  LockScreenGlucoseWidget.swift
//  XueTangJiLuWidget
//
//  Created by XueTangJiLu on 2026/2/14.
//

import WidgetKit
import SwiftUI

/// 锁屏 Widget：圆形进度环显示今日 TIR（达标率）
struct LockScreenGlucoseWidget: Widget {
    let kind: String = "LockScreenGlucoseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GlucoseTimelineProvider()) { entry in
            LockScreenGlucoseWidgetView(entry: entry)
        }
        .configurationDisplayName("达标率")
        .description("在锁屏显示血糖达标率 (TIR)")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenGlucoseWidgetView: View {
    let entry: GlucoseWidgetEntry

    var body: some View {
        Gauge(value: entry.tirValue, in: 0...100) {
            Text("TIR")
                .font(.system(.caption2, design: .rounded))
        } currentValueLabel: {
            Text("\(Int(entry.tirValue))%")
                .font(.system(.body, design: .rounded, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

#Preview(as: .accessoryCircular) {
    LockScreenGlucoseWidget()
} timeline: {
    GlucoseWidgetEntry.placeholder
    GlucoseWidgetEntry.empty
}
