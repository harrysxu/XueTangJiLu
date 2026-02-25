//
//  WatchHomeView.swift
//  XueTangJiLuWatch
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData

/// Watch 首页 - 显示最新血糖 + 快速记录入口
struct WatchHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var records: [GlucoseRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var showQuickRecord = false

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    private var latestRecord: GlucoseRecord? {
        records.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 最新血糖
                    if let latest = latestRecord {
                        VStack(spacing: 4) {
                            Text(String(localized: "watch.latest_glucose"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(latest.displayValue(in: unit))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(latest.glucoseLevel.colorName))

                            Text(unit.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                Image(systemName: latest.mealContext.iconName)
                                    .font(.caption2)
                                Text(latest.mealContext.displayName)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)

                            Text(latest.timestamp.relativeDescription)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    } else {
                        Text(String(localized: "watch.no_records"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // 快速记录按钮
                    Button(action: { showQuickRecord = true }) {
                        Label(String(localized: "watch.record_glucose"), systemImage: "plus.circle.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("BrandPrimary"))

                    // 今日概要
                    if !records.isEmpty {
                        todaySummary
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle(String(localized: "app.name"))
            .sheet(isPresented: $showQuickRecord) {
                WatchQuickRecordView()
            }
        }
    }

    private var todaySummary: some View {
        let todayRecords = records.filter { $0.timestamp.isToday }
        return VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "watch.today"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                VStack {
                    Text("\(todayRecords.count)")
                        .font(.caption.weight(.bold))
                    Text(String(localized: "watch.count"))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack {
                    if let avg = GlucoseCalculator.estimatedAverageGlucose(records: todayRecords) {
                        Text(GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit))
                            .font(.caption.weight(.bold))
                    } else {
                        Text(String(localized: "watch.placeholder_dash"))
                            .font(.caption.weight(.bold))
                    }
                    Text(String(localized: "watch.average"))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
