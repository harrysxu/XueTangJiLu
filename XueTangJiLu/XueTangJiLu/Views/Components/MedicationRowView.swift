//
//  MedicationRowView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/20.
//

import SwiftUI

/// 用药记录行视图
struct MedicationRowView: View {
    let record: MedicationRecord

    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            // 左侧：图标
            Image(systemName: record.medicationType.iconName)
                .font(.body)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 32, height: 32)
                .background(Color.brandPrimary.opacity(0.12))
                .clipShape(Circle())

            // 中间：类型 + 名称
            VStack(alignment: .leading, spacing: 2) {
                Text(record.medicationType.localizedDisplayName)
                    .font(.subheadline)
                if !record.name.isEmpty {
                    Text(record.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 右侧：时间 + 剂量
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.displayDosage)
                    .font(.glucoseCallout)
                    .foregroundStyle(.primary)
                Text(record.timestamp, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, AppConstants.Spacing.md)
        .padding(.horizontal, AppConstants.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.timestamp.timeString) \(record.medicationType.localizedDisplayName) \(record.displayDosage)")
        .accessibilityHint("轻点可编辑，右划可删除")
    }
}

#Preview {
    VStack {
        MedicationRowView(
            record: MedicationRecord(
                medicationType: .rapidInsulin,
                name: "诺和锐",
                dosage: 8.0,
                timestamp: .now
            )
        )
        MedicationRowView(
            record: MedicationRecord(
                medicationType: .oralMedicine,
                name: "二甲双胍",
                dosage: 500,
                timestamp: .now.addingTimeInterval(-3600)
            )
        )
    }
}
