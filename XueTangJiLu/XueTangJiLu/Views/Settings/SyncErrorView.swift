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
                            Text("sync.error.solutions", tableName: "Localizable")
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
                    
                    DisclosureGroup(String(localized: "sync.error.technical_details")) {
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
            .navigationTitle(String(localized: "sync.error.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.close")) {
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
        if containsQuotaExceeded { return String(localized: "sync.quota.title") }
        switch topLevelCKCode {
        case .notAuthenticated:
            return String(localized: "sync.error.not_authenticated_title")
        case .networkUnavailable, .networkFailure:
            return String(localized: "sync.error.network_title")
        case .permissionFailure:
            return String(localized: "sync.error.permission_title")
        default:
            return String(localized: "sync.failed")
        }
    }
    
    private var errorMessage: String {
        if containsQuotaExceeded {
            return String(localized: "sync.error.quota_full_message")
        }
        if let ckError = error as? CKError {
            return ckError.userFriendlyMessage
        }
        return error.localizedDescription
    }
    
    private var solutions: [String] {
        if containsQuotaExceeded {
            return [
                String(localized: "sync.error.quota.step1"),
                String(localized: "sync.error.quota.step2"),
                String(localized: "sync.error.quota.step3"),
                String(localized: "sync.error.quota.step4")
            ]
        }
        switch topLevelCKCode {
        case .notAuthenticated:
            return [
                String(localized: "sync.error.auth.step1"),
                String(localized: "sync.error.auth.step2"),
                String(localized: "sync.error.auth.step3")
            ]
        case .networkUnavailable, .networkFailure:
            return [
                String(localized: "sync.error.network.step1"),
                String(localized: "sync.error.network.step2"),
                String(localized: "sync.error.network.step3")
            ]
        case .permissionFailure:
            return [
                String(localized: "sync.error.permission.step1"),
                String(localized: "sync.error.permission.step2"),
                String(localized: "sync.error.permission.step3")
            ]
        default:
            return [
                String(localized: "sync.error.default.step1"),
                String(localized: "sync.error.default.step2")
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
                ActionButton(title: String(localized: "sync.quota.manage")) {
                    if let url = URL(string: "App-prefs:CASTLE") {
                        UIApplication.shared.open(url)
                    }
                }
            ]
        }
        switch topLevelCKCode {
        case .notAuthenticated:
            return [
                ActionButton(title: String(localized: "common.open_settings")) {
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
