//
//  EmptyStateView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI

/// 空状态占位图
struct EmptyStateView: View {
    let icon: String           // SF Symbol 名称
    let title: String          // 主标题
    let subtitle: String       // 辅助说明

    var body: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

#Preview {
    EmptyStateView(
        icon: "drop",
        title: "还没有任何记录",
        subtitle: "点击下方 \"+\" 开始记录"
    )
}
