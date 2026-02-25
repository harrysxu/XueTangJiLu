//
//  DailySummaryCard.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/20.
//

import SwiftUI

/// 今日血糖总结卡片
struct DailySummaryCard: View {
    let todayRecords: [GlucoseRecord]
    let allRecords: [GlucoseRecord]  // 添加全部记录用于计算连续天数
    let settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(.blue)
                Text(String(localized: "daily.today_glucose"))
                    .font(.headline)
                Spacer()
                Text(Date.now.formatted(.dateTime.month().day().weekday()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // 连续记录天数（如果大于0）
            streakBanner
            
            if todayRecords.isEmpty {
                // 无记录状态
                emptyState
            } else {
                // 有记录状态
                summaryContent
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // MARK: - 连续记录天数横幅
    
    @ViewBuilder
    private var streakBanner: some View {
        let days = GlucoseCalculator.consecutiveDays(records: allRecords)
        if days > 0 {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "daily.streak_format", defaultValue: "已连续记录 \(days) 天"))
                        .font(.subheadline.weight(.semibold))
                    
                    if let encouragement = GlucoseCalculator.streakEncouragement(for: days) {
                        Text(encouragement)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.1))
            )
        }
    }
    
    // MARK: - 无记录状态
    
    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.tertiary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "daily.no_records_today"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(String(localized: "daily.tap_to_start"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
    
    // MARK: - 有记录状态
    
    private var summaryContent: some View {
        let inRangeCount = todayRecords.filter { 
            $0.glucoseLevel(with: settings) == .normal 
        }.count
        let avgGlucose = todayRecords.map(\.value).reduce(0, +) / Double(todayRecords.count)
        
        return VStack(spacing: 16) {
            HStack(spacing: 20) {
                // 记录次数
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(todayRecords.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("已记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                // 达标状态
                VStack(alignment: .leading, spacing: 6) {
                    if inRangeCount == todayRecords.count {
                        // 全部达标
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title3)
                            Text(String(localized: "daily.all_in_range"))
                                .font(.subheadline.weight(.semibold))
                        }
                        Text(String(localized: "daily.control_good"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        // 有超标
                        let outOfRangeCount = todayRecords.count - inRangeCount
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.title3)
                            Text(String(localized: "daily.out_of_range", defaultValue: "\(outOfRangeCount)次超标"))
                                .font(.subheadline.weight(.semibold))
                        }
                        Text(String(localized: "daily.suggestion"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // 平均血糖
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f", avgGlucose))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(String(localized: "daily.average_format", defaultValue: "平均 \(settings.preferredUnit.rawValue)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 低血糖警告（如果有）
            if todayRecords.contains(where: { $0.value < 3.9 }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(String(localized: "daily.low_warning"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview("有记录") {
    let settings = UserSettings()
    let records = [
        GlucoseRecord(value: 6.5, timestamp: Date(), sceneTagId: "breakfast_after"),
        GlucoseRecord(value: 11.2, timestamp: Date().addingTimeInterval(-3600), sceneTagId: "lunch_after"),
        GlucoseRecord(value: 7.8, timestamp: Date().addingTimeInterval(-7200), sceneTagId: "dinner_after")
    ]
    
    return DailySummaryCard(todayRecords: records, allRecords: records, settings: settings)
        .padding(.vertical)
}

#Preview("无记录") {
    let settings = UserSettings()
    
    return DailySummaryCard(todayRecords: [], allRecords: [], settings: settings)
        .padding(.vertical)
}

#Preview("全部达标") {
    let settings = UserSettings()
    let records = [
        GlucoseRecord(value: 6.5, timestamp: Date(), sceneTagId: "breakfast_after"),
        GlucoseRecord(value: 7.2, timestamp: Date().addingTimeInterval(-3600), sceneTagId: "lunch_after"),
        GlucoseRecord(value: 6.8, timestamp: Date().addingTimeInterval(-7200), sceneTagId: "dinner_after")
    ]
    
    return DailySummaryCard(todayRecords: records, allRecords: records, settings: settings)
        .padding(.vertical)
}

#Preview("有低血糖") {
    let settings = UserSettings()
    let records = [
        GlucoseRecord(value: 3.5, timestamp: Date(), sceneTagId: "breakfast_after"),
        GlucoseRecord(value: 7.2, timestamp: Date().addingTimeInterval(-3600), sceneTagId: "lunch_after")
    ]
    
    return DailySummaryCard(todayRecords: records, allRecords: records, settings: settings)
        .padding(.vertical)
}

#Preview("连续7天") {
    let settings = UserSettings()
    let calendar = Calendar.current
    var records: [GlucoseRecord] = []
    for i in 0..<7 {
        if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
            records.append(GlucoseRecord(value: 6.5, timestamp: date, sceneTagId: "breakfast_after"))
        }
    }
    
    return DailySummaryCard(todayRecords: [records[0]], allRecords: records, settings: settings)
        .padding(.vertical)
}
