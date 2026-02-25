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
                    // 错误图标和标题
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
                    
                    // 解决方案
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
                    
                    // 操作按钮
                    if let action = primaryAction {
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
                    
                    // 技术详情（可展开）
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
    
    // MARK: - Private Properties
    
    private var errorIcon: String {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                return "person.crop.circle.badge.exclamationmark"
            case .networkUnavailable, .networkFailure:
                return "wifi.slash"
            case .quotaExceeded:
                return "externaldrive.badge.exclamationmark"
            case .permissionFailure:
                return "lock.shield"
            default:
                return "exclamationmark.triangle"
            }
        }
        return "exclamationmark.triangle"
    }
    
    private var errorColor: Color {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated, .quotaExceeded, .permissionFailure:
                return .orange
            case .networkUnavailable, .networkFailure:
                return .blue
            default:
                return .red
            }
        }
        return .red
    }
    
    private var errorTitle: String {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                return "未登录 iCloud"
            case .networkUnavailable, .networkFailure:
                return "网络连接失败"
            case .quotaExceeded:
                return "存储空间不足"
            case .permissionFailure:
                return "权限不足"
            default:
                return "同步失败"
            }
        }
        return "同步失败"
    }
    
    private var errorMessage: String {
        if let ckError = error as? CKError {
            return ckError.userFriendlyMessage
        }
        return error.localizedDescription
    }
    
    private var solutions: [String] {
        if let ckError = error as? CKError {
            switch ckError.code {
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
            case .quotaExceeded:
                return [
                    "打开「设置」> Apple ID > iCloud",
                    "查看存储空间使用情况",
                    "删除不需要的数据或升级容量"
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
        return ["稍后重试", "如问题持续，请联系技术支持"]
    }
    
    private var primaryAction: (title: String, action: () -> Void)? {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                return ("打开设置", {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                })
            case .quotaExceeded:
                return ("管理存储空间", {
                    if let url = URL(string: "App-prefs:CASTLE") {
                        UIApplication.shared.open(url)
                    }
                })
            default:
                return nil
            }
        }
        return nil
    }
}

#Preview {
    SyncErrorView(error: CKError(.notAuthenticated))
}
