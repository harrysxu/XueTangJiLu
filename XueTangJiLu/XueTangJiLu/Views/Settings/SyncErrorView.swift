//
//  SyncErrorView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

import SwiftUI
import CloudKit

/// 同步错误详情页
struct SyncErrorView: View {
    let error: Error
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
                    VStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: errorIcon)
                            .font(.system(size: 60))
                            .foregroundStyle(errorColor)
                        
                        Text(errorTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppConstants.Spacing.xxl)
                    
                    if !solutions.isEmpty {
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                            Text("解决方案")
                                .font(.headline)
                            
                            ForEach(Array(solutions.enumerated()), id: \.offset) { index, solution in
                                HStack(alignment: .top, spacing: AppConstants.Spacing.sm) {
                                    Text("\(index + 1).")
                                        .foregroundStyle(.secondary)
                                    Text(solution)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(AppConstants.Spacing.lg)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                    }
                    
                    ForEach(actionButtons, id: \.title) { action in
                        Button(action: action.action) {
                            Text(action.title)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
                        }
                    }
                    
                    DisclosureGroup("技术详情") {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, AppConstants.Spacing.sm)
                    }
                    .padding(AppConstants.Spacing.lg)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                }
                .padding(AppConstants.Spacing.lg)
            }
            .navigationTitle("同步错误")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Quota Detection
    
    /// Partial Failure 内部可能包含 quotaExceeded
    private var containsQuotaExceeded: Bool {
        guard let ckError = error as? CKError else { return false }
        if ckError.code == .quotaExceeded { return true }
        if ckError.code == .partialFailure,
           let partialErrors = ckError.partialErrorsByItemID {
            return partialErrors.values.contains { ($0 as? CKError)?.code == .quotaExceeded }
        }
        return false
    }
    
    private var topLevelCKCode: CKError.Code? {
        (error as? CKError)?.code
    }
    
    // MARK: - Computed UI Properties
    
    private var errorIcon: String {
        if containsQuotaExceeded {
            return "externaldrive.badge.exclamationmark"
        }
        switch topLevelCKCode {
        case .notAuthenticated:
            return "person.crop.circle.badge.exclamationmark"
        case .networkUnavailable, .networkFailure:
            return "wifi.slash"
        case .permissionFailure:
            return "lock.shield"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    private var errorColor: Color {
        if containsQuotaExceeded { return .orange }
        switch topLevelCKCode {
        case .notAuthenticated, .permissionFailure:
            return .orange
        case .networkUnavailable, .networkFailure:
            return .blue
        default:
            return .red
        }
    }
    
    private var errorTitle: String {
        if containsQuotaExceeded { return "iCloud 存储空间不足" }
        switch topLevelCKCode {
        case .notAuthenticated:
            return "未登录 iCloud"
        case .networkUnavailable, .networkFailure:
            return "网络连接失败"
        case .permissionFailure:
            return "权限不足"
        default:
            return "同步失败"
        }
    }
    
    private var errorMessage: String {
        if containsQuotaExceeded {
            return "您的 iCloud 存储空间已满，无法将数据同步到云端。本地数据不受影响，清理空间后将自动恢复同步。"
        }
        if let ckError = error as? CKError {
            return ckError.userFriendlyMessage
        }
        return error.localizedDescription
    }
    
    private var solutions: [String] {
        if containsQuotaExceeded {
            return [
                "打开「设置」> 点击顶部 Apple ID > iCloud > 管理账户储存空间",
                "删除不需要的 iCloud 备份、照片或其他应用数据",
                "或升级到 iCloud+ 获取更多存储空间（50GB 仅需 ¥6/月）",
                "清理后重新打开本应用，同步将自动恢复"
            ]
        }
        switch topLevelCKCode {
        case .notAuthenticated:
            return [
                "打开「设置」应用",
                "点击顶部的 Apple ID",
                "登录您的 iCloud 账户"
            ]
        case .networkUnavailable, .networkFailure:
            return [
                "检查设备的网络连接",
                "确保已连接到互联网",
                "尝试切换网络或重启路由器"
            ]
        case .permissionFailure:
            return [
                "打开「设置」> 隐私与安全性",
                "确保应用有 iCloud 访问权限",
                "重新授权应用"
            ]
        default:
            return [
                "稍后重试",
                "如问题持续，请联系技术支持"
            ]
        }
    }
    
    private struct ActionButton: Hashable {
        let title: String
        let action: () -> Void
        
        static func == (lhs: ActionButton, rhs: ActionButton) -> Bool { lhs.title == rhs.title }
        func hash(into hasher: inout Hasher) { hasher.combine(title) }
    }
    
    private var actionButtons: [ActionButton] {
        if containsQuotaExceeded {
            return [
                ActionButton(title: "管理 iCloud 存储空间") {
                    if let url = URL(string: "App-prefs:CASTLE") {
                        UIApplication.shared.open(url)
                    }
                }
            ]
        }
        switch topLevelCKCode {
        case .notAuthenticated:
            return [
                ActionButton(title: "打开设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            ]
        default:
            return []
        }
    }
}

#Preview {
    SyncErrorView(error: CKError(.notAuthenticated))
}
