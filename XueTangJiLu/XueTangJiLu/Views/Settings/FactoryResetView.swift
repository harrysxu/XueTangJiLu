//
//  FactoryResetView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/22.
//

import SwiftUI
import SwiftData

/// 清除历史记录页面
struct FactoryResetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CloudKitSyncManager.self) private var syncManager
    @Query private var allGlucoseRecords: [GlucoseRecord]
    @Query private var allMealRecords: [MealRecord]
    @Query private var allMedicationRecords: [MedicationRecord]
    @Query private var settingsArray: [UserSettings]
    
    @State private var confirmationText = ""
    @State private var showFirstWarning = false
    @State private var showSecondWarning = false
    @State private var isResetting = false
    @State private var resetComplete = false
    @State private var isSyncingDeletion = false
    @State private var syncDeletionResult: SyncDeletionResult?
    
    private enum SyncDeletionResult {
        case synced
        case timeout
    }
    
    private let requiredText = String(localized: "factory_reset.required_text")
    
    private var totalRecords: Int {
        allGlucoseRecords.count + allMealRecords.count + allMedicationRecords.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    // 警告图标
                    warningHeader
                    
                    // 数据统计
                    dataStatistics
                    
                    // 删除说明
                    deletionExplanation
                    
                    // 确认输入框
                    confirmationInput
                    
                    // 重置按钮
                    resetButton
                }
                .padding(AppConstants.Spacing.lg)
            }
            .navigationTitle(String(localized: "factory_reset.navigation_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "factory_reset.cancel")) {
                        dismiss()
                    }
                }
            }
            .alert(String(localized: "factory_reset.first_warning_title"), isPresented: $showFirstWarning) {
                Button(String(localized: "factory_reset.think_again_button"), role: .cancel) {
                    confirmationText = ""
                }
                Button(String(localized: "factory_reset.continue_button"), role: .destructive) {
                    showSecondWarning = true
                }
            } message: {
                Text(String(localized: "factory_reset.first_warning_message", defaultValue: "此操作将永久删除 \(totalRecords) 条记录和所有自定义设置。\n\n⚠️ 重要：数据删除后会通过 iCloud 同步到所有设备，所有设备上的数据都会被清空！\n\n删除后数据无法恢复，您确定要继续吗？"))
            }
            .alert(String(localized: "factory_reset.second_warning_title"), isPresented: $showSecondWarning) {
                Button(String(localized: "factory_reset.cancel"), role: .cancel) {
                    confirmationText = ""
                }
                Button(String(localized: "factory_reset.confirm_delete_button"), role: .destructive) {
                    performFactoryReset()
                }
            } message: {
                Text(String(localized: "factory_reset.second_warning_message", defaultValue: "这是最后一次确认。\n\n点击\"确认删除\"后，所有数据将被永久删除，包括：\n• \(allGlucoseRecords.count) 条血糖记录\n• \(allMealRecords.count) 条饮食记录\n• \(allMedicationRecords.count) 条用药记录\n• 所有自定义标签和设置\n\n⚠️ 此操作会通过 iCloud 同步到所有设备！\n⚠️ 此操作不可撤销！"))
            }
            .alert(String(localized: "factory_reset.complete_title"), isPresented: $resetComplete) {
                Button(String(localized: "factory_reset.done_button")) {
                    dismiss()
                }
            } message: {
                switch syncDeletionResult {
                case .synced:
                    Text(String(localized: "factory_reset.complete_synced", defaultValue: "所有数据已清除，删除已同步到 iCloud。"))
                case .timeout:
                    Text(String(localized: "factory_reset.complete_sync_pending", defaultValue: "所有本地数据已清除。请保持应用打开并连接网络，以确保删除同步到 iCloud 上所有设备。"))
                case nil:
                    Text(String(localized: "factory_reset.complete_message"))
                }
            }
        }
    }
    
    // MARK: - 警告头部
    
    private var warningHeader: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)
            
            Text(String(localized: "factory_reset.danger_title"))
                .font(.title.bold())
                .foregroundStyle(.red)
            
            Text(String(localized: "factory_reset.danger_description"))
                .font(.subheadline)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppConstants.Spacing.lg)
    }
    
    // MARK: - 数据统计
    
    private var dataStatistics: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Text(String(localized: "factory_reset.data_to_delete"))
                .font(.headline)
            
            VStack(spacing: AppConstants.Spacing.sm) {
                dataRow(icon: "drop.fill", label: String(localized: "factory_reset.glucose_records"), count: allGlucoseRecords.count, color: .blue)
                dataRow(icon: "fork.knife", label: String(localized: "factory_reset.meal_records"), count: allMealRecords.count, color: .green)
                dataRow(icon: "pills.fill", label: String(localized: "factory_reset.medication_records"), count: allMedicationRecords.count, color: .orange)
                dataRow(icon: "tag.fill", label: String(localized: "factory_reset.custom_tags"), count: customTagCount, color: .purple)
            }
            .padding(AppConstants.Spacing.md)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
            
            Text(String(localized: "factory_reset.total_items", defaultValue: "总计：\(totalRecords + customTagCount) 项数据"))
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }
    
    private func dataRow(icon: String, label: String, count: Int, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(count)")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
        }
    }
    
    private var customTagCount: Int {
        let settings = settingsArray.first ?? UserSettings()
        let customSceneTags = settings.sceneTags.filter { !$0.isBuiltIn }
        let customAnnotationTags = settings.annotationTags.filter { !$0.isBuiltIn }
        return customSceneTags.count + customAnnotationTags.count
    }
    
    // MARK: - 删除说明
    
    private var deletionExplanation: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text(String(localized: "factory_reset.what_will_reset"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                bulletPoint(String(localized: "factory_reset.all_records_item"))
                bulletPoint(String(localized: "factory_reset.custom_tags_item"))
                bulletPoint(String(localized: "factory_reset.settings_item"))
                bulletPoint(String(localized: "factory_reset.reminders_item"))
                bulletPoint(String(localized: "factory_reset.healthkit_item"))
            }
            .padding(AppConstants.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
            
            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                Text(String(localized: "factory_reset.icloud_warning_title"))
                    .font(.caption.bold())
                    .foregroundStyle(.red)
                
                Text(String(localized: "factory_reset.icloud_sync_warning"))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .padding(AppConstants.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppConstants.Spacing.sm) {
            Text("•")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - 确认输入
    
    private var confirmationInput: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text(String(localized: "factory_reset.confirm_input_prompt"))
                .font(.headline)
            
            Text(String(localized: "factory_reset.type_to_confirm_prompt", defaultValue: "请输入：\(requiredText)"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField("", text: $confirmationText)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.body)
        }
    }
    
    // MARK: - 重置按钮
    
    private var resetButton: some View {
        VStack(spacing: 0) {
            Button(action: {
                guard confirmationText == requiredText else {
                    HapticManager.warning()
                    return
                }
                showFirstWarning = true
            }) {
                HStack {
                    if isResetting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "trash.fill")
                        Text(String(localized: "factory_reset.confirm_button"))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppConstants.Spacing.md)
                .background(confirmationText == requiredText ? Color.red : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
            }
            .disabled(confirmationText != requiredText || isResetting)
            
            if isSyncingDeletion {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(String(localized: "factory_reset.syncing_deletion", defaultValue: "正在同步删除到 iCloud..."))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.top, AppConstants.Spacing.sm)
            }
        }
    }
    
    // MARK: - 执行重置
    
    private func performFactoryReset() {
        isResetting = true
        
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            
            await MainActor.run {
                for record in allGlucoseRecords {
                    modelContext.delete(record)
                }
                for record in allMealRecords {
                    modelContext.delete(record)
                }
                for record in allMedicationRecords {
                    modelContext.delete(record)
                }
                if let existingSettings = settingsArray.first {
                    modelContext.delete(existingSettings)
                }
                let newSettings = UserSettings()
                modelContext.insert(newSettings)
            }
            
            do {
                try modelContext.save()
                HapticManager.success()
                
                if syncManager.isSyncEnabled && syncManager.networkMonitor.isConnected {
                    await MainActor.run { isSyncingDeletion = true }
                    let exported = await syncManager.waitForExportCompletion(timeout: 15)
                    await MainActor.run {
                        isSyncingDeletion = false
                        syncDeletionResult = exported ? .synced : .timeout
                        isResetting = false
                        resetComplete = true
                    }
                } else {
                    await MainActor.run {
                        syncDeletionResult = syncManager.isSyncEnabled ? .timeout : nil
                        isResetting = false
                        resetComplete = true
                    }
                }
            } catch {
                #if DEBUG
                print("重置失败: \(error)")
                #endif
                HapticManager.warning()
                await MainActor.run { isResetting = false }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FactoryResetView()
    }
    .environment(CloudKitSyncManager())
    .modelContainer(for: [GlucoseRecord.self, MealRecord.self, MedicationRecord.self, UserSettings.self], inMemory: true)
}
