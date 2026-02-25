//
//  MealContextTag.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

/// 场景标签胶囊组件（支持内置和自定义标签）
struct MealContextTag: View {
    let tagId: String
    let label: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void

    init(tagId: String, label: String, iconName: String, isSelected: Bool, action: @escaping () -> Void) {
        self.tagId = tagId
        self.label = label
        self.iconName = iconName
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            HStack(spacing: AppConstants.Spacing.xs) {
                Image(systemName: iconName)
                    .font(.caption2)
                Text(label)
                    .font(.footnote)
            }
            .padding(.horizontal, AppConstants.Spacing.md)
            .padding(.vertical, AppConstants.Spacing.sm)
            .background(
                isSelected
                    ? Color.brandPrimary
                    : Color(.tertiarySystemGroupedBackground)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)，\(isSelected ? "已选中" : "未选中")")
        .accessibilityHint("双击切换选中状态")
    }
}

#Preview {
    HStack {
        MealContextTag(tagId: "breakfast_before", label: "早餐前", iconName: "sunrise", isSelected: true) {}
        MealContextTag(tagId: "breakfast_after", label: "早餐后", iconName: "sunrise", isSelected: false) {}
        MealContextTag(tagId: "custom_1", label: "下午茶", iconName: "cup.and.saucer", isSelected: false) {}
    }
}
