//
//  MealRowView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/20.
//

import SwiftUI

/// 饮食记录行视图
struct MealRowView: View {
    let record: MealRecord

    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            // 左侧：照片缩略图或图标
            if let photoData = record.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(record.carbLevel.colorName))
                    .frame(width: 40, height: 40)
            }

            // 中间：描述 + 碳水标签
            VStack(alignment: .leading, spacing: 2) {
                if !record.mealDescription.isEmpty {
                    Text(record.mealDescription)
                        .font(.subheadline)
                        .lineLimit(1)
                } else {
                    Text("饮食记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: AppConstants.Spacing.xs) {
                    Image(systemName: record.carbLevel.iconName)
                        .font(.caption2)
                    Text(record.carbLevel.displayName)
                        .font(.caption)
                }
                .foregroundStyle(Color(record.carbLevel.colorName))
            }

            Spacer()

            // 右侧：时间
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.timestamp, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.primary)
                
                if record.note != nil {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, AppConstants.Spacing.md)
        .padding(.horizontal, AppConstants.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.timestamp.timeString) \(record.carbLevel.displayName) \(record.mealDescription)")
        .accessibilityHint("轻点可编辑，右划可删除")
    }
}

#Preview {
    VStack(spacing: 0) {
        MealRowView(
            record: MealRecord(
                carbLevel: .high,
                mealDescription: "米饭 + 红烧肉 + 可乐",
                photoData: nil,
                timestamp: .now
            )
        )
        Divider()
        MealRowView(
            record: MealRecord(
                carbLevel: .low,
                mealDescription: "鸡胸肉沙拉",
                photoData: nil,
                timestamp: .now.addingTimeInterval(-3600),
                note: "健康饮食"
            )
        )
        Divider()
        MealRowView(
            record: MealRecord(
                carbLevel: .medium,
                mealDescription: "",
                photoData: nil,
                timestamp: .now.addingTimeInterval(-7200)
            )
        )
    }
    .background(Color.cardBackground)
}
