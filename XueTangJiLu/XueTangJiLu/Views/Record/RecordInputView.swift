//
//  RecordInputView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData

/// 快速录入页 - App 的核心页面，承载 3 秒录入体验
struct RecordInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HealthKitManager.self) private var healthKitManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query private var settingsArray: [UserSettings]
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var allRecords: [GlucoseRecord]
    @Bindable var viewModel: GlucoseViewModel
    @State private var showDatePicker = false
    @State private var showAllScenes = false
    @State private var showUpgradeAlert = false

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }
    
    /// 今日已有记录数
    private var todayRecordsCount: Int {
        allRecords.filter { $0.timestamp.isToday }.count
    }
    
    /// 剩余可用记录数
    private var remainingRecords: Int? {
        FeatureManager.remainingRecordsToday(
            todayRecordsCount: todayRecordsCount,
            isPremium: subscriptionManager.isPremiumUser
        )
    }

    /// 当前输入值对应的颜色（场景感知）
    private var valueColor: Color {
        if let mmolL = viewModel.normalizedValue(unit: unit) {
            return Color.forGlucoseValue(mmolL, tagId: viewModel.selectedSceneTagId, settings: settings)
        }
        return .primary
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.md) {
                    // 限制提示横幅
                    if !subscriptionManager.isPremiumUser, let remaining = remainingRecords {
                        LimitationBanner(limitationType: .dailyRecords(remaining: remaining, total: 5))
                            .padding(.horizontal, AppConstants.Spacing.lg)
                    }

                    // 数值输入区域（带渐变背景）
                    valueInputSection
                        .padding(.top, AppConstants.Spacing.sm)

                    // 场景标签选择器（网格）
                    mealContextSelector

                    // 快捷备注标签
                    quickNoteSelector

                    // 日期时间
                    dateTimeSection

                    // 备注区域
                    noteSection
                }
                .padding(.vertical, AppConstants.Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.isEditMode ? String(localized: "record.edit") : "")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) {
                        if FeatureManager.hasReachedDailyLimit(
                            todayRecordsCount: todayRecordsCount,
                            isPremium: subscriptionManager.isPremiumUser
                        ) {
                            showUpgradeAlert = true
                            return
                        }
                        Task {
                            await viewModel.saveRecord(
                                modelContext: modelContext,
                                unit: unit,
                                healthKitManager: healthKitManager,
                                healthKitEnabled: settings.healthKitSyncEnabled
                            )
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isSaveEnabled(unit: unit) || viewModel.isSaving)
                    .fontWeight(.semibold)
                }
            }
            .featureLockAlert(isPresented: $showUpgradeAlert, feature: .unlimitedRecords)
            .sheet(isPresented: $showAllScenes) {
                allScenesSheet
            }
        }
    }

    // MARK: - 数值输入（带渐变背景）

    private var valueInputSection: some View {
        VStack(spacing: AppConstants.Spacing.xs) {
            TextField("0.0", text: $viewModel.inputText)
                .keyboardType(unit.maxDecimalPlaces > 0 ? .decimalPad : .numberPad)
                .multilineTextAlignment(.center)
                .font(.glucoseDisplay)
                .foregroundStyle(viewModel.inputText.isEmpty ? Color(.tertiaryLabel) : valueColor)
                .accessibilityIdentifier("glucosePreview")
                .onChange(of: viewModel.inputText) { _, newValue in
                    viewModel.validateInput(newValue, unit: unit)
                }

            Text(unit.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)

            // 血糖水平指示
            if let level = viewModel.currentLevel(unit: unit, settings: settings) {
                HStack(spacing: 4) {
                    Image(systemName: level.accessoryIconName)
                        .font(.caption2)
                    Text(level.localizedDescription)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(Color.forGlucoseLevel(level))
                .transition(.opacity)
                
                ReferenceSourceLink()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.md)
        .background(
            Group {
                if let level = viewModel.currentLevel(unit: unit, settings: settings) {
                    Color.glucoseGradient(for: level)
                } else {
                    Color.clear
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
        .padding(.horizontal, AppConstants.Spacing.lg)
    }

    // MARK: - 场景标签选择器（按用户配置顺序和可见性）

    private var mealContextSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.sm) {
                // 使用推荐的场景标签(根据用户类型)
                ForEach(settings.recommendedSceneTags) { tag in
                    MealContextTag(
                        tagId: tag.id,
                        label: tag.label,
                        iconName: tag.icon,
                        isSelected: viewModel.selectedSceneTagId == tag.id
                    ) {
                        viewModel.selectedSceneTagId = tag.id
                    }
                }
                
                // "更多"按钮(如果有隐藏的场景)
                if settings.visibleSceneTags.count > settings.recommendedSceneTags.count {
                    Button(action: {
                        showAllScenes = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "ellipsis")
                            Text(String(localized: "record.more"))
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.quaternarySystemFill))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
        }
    }

    // MARK: - 快捷备注标签（按用户配置）

    private var quickNoteSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.xs) {
                ForEach(settings.visibleAnnotationTags) { tag in
                    Button(action: {
                        HapticManager.selection()
                        if viewModel.noteText == tag.label {
                            viewModel.noteText = ""
                        } else {
                            viewModel.noteText = tag.label
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: tag.icon)
                                .font(.caption2)
                            Text(tag.label)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            viewModel.noteText == tag.label
                                ? Color.brandPrimary.opacity(0.15)
                                : Color(.quaternarySystemFill)
                        )
                        .foregroundStyle(
                            viewModel.noteText == tag.label
                                ? Color.brandPrimary
                                : .secondary
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
        }
    }

    // MARK: - 日期时间

    private var dateTimeSection: some View {
        Button(action: {
            showDatePicker.toggle()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption)
                Text(viewModel.selectedDate.fullDateTimeString)
                    .font(.footnote)
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.quaternarySystemFill))
            .clipShape(Capsule())
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack(spacing: 0) {
                    DatePicker(
                        String(localized: "select.datetime"),
                        selection: $viewModel.selectedDate,
                        in: ...Date.now,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    
                    Divider()
                    
                    // 快捷时间选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "record.quick_select"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                QuickTimeButton(title: String(localized: "record.time.now"), date: Date.now, selectedDate: $viewModel.selectedDate)
                                QuickTimeButton(title: String(localized: "record.time.1h_ago"), date: Date.now.addingTimeInterval(-3600), selectedDate: $viewModel.selectedDate)
                                QuickTimeButton(title: String(localized: "record.time.2h_ago"), date: Date.now.addingTimeInterval(-7200), selectedDate: $viewModel.selectedDate)
                                QuickTimeButton(title: String(localized: "record.time.today_7am"), date: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date.now) ?? Date.now, selectedDate: $viewModel.selectedDate)
                                QuickTimeButton(title: String(localized: "record.time.today_12pm"), date: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date.now) ?? Date.now, selectedDate: $viewModel.selectedDate)
                                QuickTimeButton(title: String(localized: "record.time.today_6pm"), date: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date.now) ?? Date.now, selectedDate: $viewModel.selectedDate)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemGroupedBackground))
                }
                .navigationTitle(String(localized: "select.time"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "done")) {
                            showDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - 备注

    private var noteSection: some View {
        TextField(String(localized: "add.note.optional"), text: $viewModel.noteText)
            .font(.subheadline)
            .padding(AppConstants.Spacing.md)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.input))
            .padding(.horizontal, AppConstants.Spacing.lg)
    }

    
    
    // MARK: - 所有场景选择Sheet
    
    private var allScenesSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppConstants.Spacing.md) {
                    ForEach(settings.visibleSceneTags) { tag in
                        Button(action: {
                            viewModel.selectedSceneTagId = tag.id
                            HapticManager.selection()
                            showAllScenes = false
                        }) {
                            VStack(spacing: AppConstants.Spacing.xs) {
                                Image(systemName: tag.icon)
                                    .font(.title2)
                                Text(tag.label)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppConstants.Spacing.md)
                            .background(
                                viewModel.selectedSceneTagId == tag.id
                                    ? Color.brandPrimary.opacity(0.15)
                                    : Color(.tertiarySystemGroupedBackground)
                            )
                            .foregroundStyle(
                                viewModel.selectedSceneTagId == tag.id
                                    ? Color.brandPrimary
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                                    .stroke(
                                        viewModel.selectedSceneTagId == tag.id ? Color.brandPrimary : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppConstants.Spacing.lg)
            }
            .navigationTitle(String(localized: "record.select_scene"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "done")) {
                        showAllScenes = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - 快捷时间选择按钮

private struct QuickTimeButton: View {
    let title: String
    let date: Date
    @Binding var selectedDate: Date
    
    private var isSelected: Bool {
        Calendar.current.isDate(selectedDate, equalTo: date, toGranularity: .minute)
    }
    
    var body: some View {
        Button(action: {
            selectedDate = date
            HapticManager.selection()
        }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.brandPrimary.opacity(0.15) : Color(.quaternarySystemFill))
                .foregroundStyle(isSelected ? Color.brandPrimary : .secondary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    @Previewable @State var viewModel = GlucoseViewModel()
    RecordInputView(viewModel: viewModel)
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
        .environment(HealthKitManager())
        .environment(SubscriptionManager())
}
