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
    @Query private var settingsArray: [UserSettings]
    @Binding var viewModel: GlucoseViewModel
    @State private var showDatePicker = false

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    /// 当前输入值对应的颜色
    private var valueColor: Color {
        if let mmolL = viewModel.normalizedValue(unit: unit) {
            return Color.forGlucoseValue(mmolL)
        }
        return .primary
    }

    /// 快捷备注标签
    private let quickNotes = ["运动后", "压力大", "生病", "旅行", "加餐", "饮酒"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 数值预览区域（带渐变背景）
                valuePreviewSection
                    .padding(.top, AppConstants.Spacing.sm)

                // 场景标签选择器（网格）
                mealContextSelector
                    .padding(.top, AppConstants.Spacing.md)

                // 快捷备注标签
                quickNoteSelector
                    .padding(.top, AppConstants.Spacing.sm)

                // 日期时间
                dateTimeSection
                    .padding(.top, AppConstants.Spacing.sm)

                // 备注区域
                if viewModel.showNoteField {
                    noteSection
                        .padding(.top, AppConstants.Spacing.sm)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                // 自定义数字键盘
                MinimalKeypadView { key in
                    viewModel.handleKeyPress(key, unit: unit)
                }
                .padding(.top, AppConstants.Spacing.sm)

                // 保存按钮
                saveButton
                    .padding(.top, AppConstants.Spacing.md)
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.bottom, AppConstants.Spacing.sm)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(viewModel.showNoteField ? "隐藏备注" : "备注") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showNoteField.toggle()
                        }
                    }
                }
            }
        }
    }

    // MARK: - 数值预览（带渐变背景）

    private var valuePreviewSection: some View {
        VStack(spacing: AppConstants.Spacing.xs) {
            Text(viewModel.inputText.isEmpty ? "0.0" : viewModel.inputText)
                .font(.glucoseDisplay)
                .foregroundStyle(viewModel.inputText.isEmpty ? Color(.tertiaryLabel) : valueColor)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.15), value: viewModel.inputText)
                .accessibilityIdentifier("glucosePreview")

            Text(unit.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)

            // 血糖水平指示
            if let level = viewModel.currentLevel(unit: unit) {
                HStack(spacing: 4) {
                    Image(systemName: level.accessoryIconName)
                        .font(.caption2)
                    Text(level.description)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(Color.forGlucoseLevel(level))
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.md)
        .background(
            Group {
                if let level = viewModel.currentLevel(unit: unit) {
                    Color.glucoseGradient(for: level)
                } else {
                    Color.clear
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
        .padding(.horizontal, AppConstants.Spacing.lg)
    }

    // MARK: - 场景标签选择器（2行可滚动）

    private var mealContextSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.sm) {
                ForEach(MealContext.allCases, id: \.self) { context in
                    MealContextTag(
                        context: context,
                        isSelected: viewModel.selectedMealContext == context
                    ) {
                        viewModel.selectedMealContext = context
                    }
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
        }
    }

    // MARK: - 快捷备注标签

    private var quickNoteSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.xs) {
                ForEach(quickNotes, id: \.self) { note in
                    Button(action: {
                        HapticManager.selection()
                        if viewModel.noteText == note {
                            viewModel.noteText = ""
                        } else {
                            viewModel.noteText = note
                            viewModel.showNoteField = true
                        }
                    }) {
                        Text(note)
                            .font(.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                viewModel.noteText == note
                                    ? Color.brandPrimary.opacity(0.15)
                                    : Color(.quaternarySystemFill)
                            )
                            .foregroundStyle(
                                viewModel.noteText == note
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
            Text(viewModel.selectedDate.fullDateTimeString)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker(
                    "选择日期和时间",
                    selection: $viewModel.selectedDate,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("选择时间")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            showDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - 备注

    private var noteSection: some View {
        TextField("添加备注（可选）", text: $viewModel.noteText)
            .font(.subheadline)
            .padding(AppConstants.Spacing.md)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.input))
            .padding(.horizontal, AppConstants.Spacing.lg)
    }

    // MARK: - 保存按钮

    private var saveButton: some View {
        Button(action: {
            Task {
                await viewModel.saveRecord(
                    modelContext: modelContext,
                    unit: unit,
                    healthKitManager: healthKitManager,
                    healthKitEnabled: settings.healthKitSyncEnabled
                )
                dismiss()
            }
        }) {
            Group {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("保存记录")
                        .font(.body.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.Size.saveButtonHeight)
            .background(
                viewModel.isSaveEnabled(unit: unit)
                    ? Color.brandPrimary
                    : Color(.systemGray4)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
        }
        .disabled(!viewModel.isSaveEnabled(unit: unit) || viewModel.isSaving)
        .accessibilityLabel("保存记录 \(viewModel.inputText) \(unit.rawValue) \(viewModel.selectedMealContext.displayName)")
        .accessibilityIdentifier("saveRecord")
    }
}

#Preview {
    RecordInputView(viewModel: .constant(GlucoseViewModel()))
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self], inMemory: true)
        .environment(HealthKitManager())
}
