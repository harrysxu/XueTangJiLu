//
//  DisclaimerView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/20.
//

import SwiftUI

/// 免责声明弹窗（首次使用时显示）
struct DisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    let onAccept: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 图标
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 70))
                        .foregroundStyle(.blue)
                        .padding(.top, 20)
                    
                    // 标题
                    Text(String(localized: "disclaimer.title"))
                        .font(.title.bold())
                    
                    // 免责条款
                    VStack(alignment: .leading, spacing: 16) {
                        DisclaimerItem(
                            icon: "stethoscope",
                            text: String(localized: "disclaimer.item1")
                        )
                        
                        DisclaimerItem(
                            icon: "chart.bar",
                            text: String(localized: "disclaimer.item2")
                        )
                        
                        DisclaimerItem(
                            icon: "phone.arrow.up.right",
                            text: String(localized: "disclaimer.item3")
                        )
                        
                        DisclaimerItem(
                            icon: "exclamationmark.triangle",
                            text: String(localized: "disclaimer.item4")
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // 说明文字
                    Text(String(localized: "disclaimer.description"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle(String(localized: "disclaimer.navigation_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "disclaimer.accept")) {
                        onAccept()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

/// 免责条款单项
struct DisclaimerItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 免责声明横幅（统计页面顶部）
struct DisclaimerBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
                .font(.callout)
            
            Text(String(localized: "disclaimer.banner"))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}

#Preview("免责声明弹窗") {
    DisclaimerView {
        print("用户已接受")
    }
}

#Preview("免责横幅") {
    DisclaimerBanner()
}
