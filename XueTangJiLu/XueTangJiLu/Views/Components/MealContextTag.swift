//
//  MealContextTag.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

/// 场景标签胶囊组件
struct MealContextTag: View {
    let context: MealContext
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            HStack(spacing: AppConstants.Spacing.xs) {
                Image(systemName: context.iconName)
                    .font(.caption2)
                Text(context.displayName)
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
        .accessibilityLabel("\(context.displayName)，\(isSelected ? "已选中" : "未选中")")
        .accessibilityHint("双击切换选中状态")
    }
}

#Preview {
    HStack {
        MealContextTag(context: .beforeBreakfast, isSelected: true) {}
        MealContextTag(context: .afterBreakfast, isSelected: false) {}
        MealContextTag(context: .beforeLunch, isSelected: false) {}
    }
}
