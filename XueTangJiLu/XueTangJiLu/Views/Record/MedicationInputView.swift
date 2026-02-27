//
//  MedicationInputView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData

/// 用药录入页
struct MedicationInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MedicationViewModel
    @State private var showDatePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 剂量预览
                dosagePreviewSection
                    .padding(.top, AppConstants.Spacing.lg)

                // 药物类型选择
                medicationTypeSelector
                    .padding(.top, AppConstants.Spacing.lg)

                // 药物名称（可选）
                nameField
                    .padding(.top, AppConstants.Spacing.md)

                // 日期时间
                dateTimeSection
                    .padding(.top, AppConstants.Spacing.md)

                Spacer()

                // 自定义数字键盘
                MinimalKeypadView { key in
                    viewModel.handleKeyPress(key)
                }
                .padding(.top, AppConstants.Spacing.md)

                // 保存按钮
                saveButton
                    .padding(.top, AppConstants.Spacing.lg)
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.bottom, AppConstants.Spacing.sm)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.isEditMode ? String(localized: "medication.edit") : "")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
            }
        }
    }

    // MARK: - 剂量预览

    private var dosagePreviewSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(viewModel.dosageText.isEmpty ? "0" : viewModel.dosageText)
                    .font(.glucoseDisplay)
                    .foregroundStyle(viewModel.dosageText.isEmpty ? Color(.tertiaryLabel) : .primary)
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.15), value: viewModel.dosageText)
            }

            Text(viewModel.selectedType.localizedUnitLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 药物类型选择器

    private var medicationTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.sm) {
                ForEach(MedicationType.allCases, id: \.self) { type in
                    Button(action: {
                        HapticManager.selection()
                        viewModel.selectedType = type
                    }) {
                        HStack(spacing: AppConstants.Spacing.xs) {
                            Image(systemName: type.iconName)
                                .font(.caption2)
                            Text(type.localizedDisplayName)
                                .font(.footnote)
                        }
                        .padding(.horizontal, AppConstants.Spacing.md)
                        .padding(.vertical, AppConstants.Spacing.sm)
                        .background(
                            viewModel.selectedType == type
                                ? Color.brandPrimary
                                : Color(.tertiarySystemGroupedBackground)
                        )
                        .foregroundStyle(viewModel.selectedType == type ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
        }
    }

    // MARK: - 药物名称

    private var nameField: some View {
        TextField(String(localized: "medication.name_placeholder"), text: $viewModel.medicationName)
            .font(.subheadline)
            .padding(AppConstants.Spacing.md)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.input))
            .padding(.horizontal, AppConstants.Spacing.lg)
    }

    // MARK: - 日期时间

    private var dateTimeSection: some View {
        Button(action: { showDatePicker.toggle() }) {
            Text(viewModel.selectedDate.fullDateTimeString)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker(
                    String(localized: "select.datetime"),
                    selection: $viewModel.selectedDate,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle(String(localized: "select.time"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "done")) { showDatePicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - 保存按钮

    private var saveButton: some View {
        Button(action: {
            viewModel.saveRecord(modelContext: modelContext)
            dismiss()
        }) {
            Group {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text(viewModel.isEditMode ? String(localized: "save") : String(localized: "medication.save_record"))
                        .font(.body.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.Size.saveButtonHeight)
            .background(
                viewModel.isSaveEnabled ? Color.brandPrimary : Color(.systemGray4)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
        }
        .disabled(!viewModel.isSaveEnabled || viewModel.isSaving)
    }
}

#Preview {
    @Previewable @State var viewModel = MedicationViewModel()
    MedicationInputView(viewModel: viewModel)
        .modelContainer(for: [MedicationRecord.self], inMemory: true)
}
