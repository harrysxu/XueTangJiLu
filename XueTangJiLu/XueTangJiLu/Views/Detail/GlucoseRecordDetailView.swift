//
//  GlucoseRecordDetailView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/19.
//

import SwiftUI
import SwiftData

/// 血糖记录详情页
struct GlucoseRecordDetailView: View {
    let record: GlucoseRecord
    @Query private var settingsArray: [UserSettings]
    @Environment(\.dismiss) private var dismiss
    
    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }
    
    private var unit: GlucoseUnit {
        settings.preferredUnit
    }
    
    private var level: GlucoseLevel {
        record.glucoseLevel(with: settings)
    }
    
    private var contextDisplayName: String {
        settings.displayName(for: record.sceneTagId)
    }
    
    private var contextIconName: String {
        settings.iconName(for: record.sceneTagId)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 血糖数值卡片
                glucoseValueCard
                
                // 详细信息
                detailsCard
                
                // 备注（如果有）
                if let note = record.note, !note.isEmpty {
                    noteCard(note: note)
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.lg)
        }
        .background(Color.pageBackground)
        .navigationTitle("记录详情")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 血糖数值卡片
    
    private var glucoseValueCard: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            // 血糖数值
            VStack(spacing: AppConstants.Spacing.sm) {
                Text("血糖数值")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(record.displayValue(in: unit))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.forGlucoseLevel(level))
                    
                    Text(unit.rawValue)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 血糖状态
            HStack(spacing: AppConstants.Spacing.xs) {
                Image(systemName: level.accessoryIconName)
                    .font(.body)
                Text(level.description)
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(Color.forGlucoseLevel(level))
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.sm)
            .background(Color.forGlucoseLevel(level).opacity(0.12))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }
    
    // MARK: - 详细信息卡片
    
    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(
                icon: "clock",
                title: "记录时间",
                value: record.timestamp.formatted(date: .abbreviated, time: .shortened)
            )
            
            Divider().padding(.horizontal, AppConstants.Spacing.lg)
            
            detailRow(
                icon: contextIconName,
                title: "场景",
                value: contextDisplayName
            )
            
            Divider().padding(.horizontal, AppConstants.Spacing.lg)
            
            detailRow(
                icon: "arrow.left.arrow.right",
                title: "数据来源",
                value: record.source == "manual" ? "手动录入" : "HealthKit"
            )
            
            if record.source == "manual" && settings.healthKitSyncEnabled {
                Divider().padding(.horizontal, AppConstants.Spacing.lg)
                
                detailRow(
                    icon: "heart.fill",
                    title: "HealthKit 同步",
                    value: record.syncedToHealthKit ? "已同步" : "未同步"
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }
    
    // MARK: - 备注卡片
    
    private func noteCard(note: String) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack(spacing: AppConstants.Spacing.xs) {
                Image(systemName: "note.text")
                    .font(.subheadline)
                    .foregroundStyle(Color.brandPrimary)
                Text("备注")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            Text(note)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }
    
    // MARK: - 详情行
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 28)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
        .padding(.vertical, AppConstants.Spacing.md)
    }
}

#Preview {
    NavigationStack {
        GlucoseRecordDetailView(
            record: GlucoseRecord(
                value: 7.8,
                sceneTagId: MealContext.afterLunch.rawValue,
                note: "吃了火锅，略微偏高"
            )
        )
    }
    .modelContainer(for: [UserSettings.self], inMemory: true)
}
