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
            ScrollView {
                VStack(spacing: AppConstants.Spacing.md) {
                    // 剂量输入
                    dosageInputSection
                        .padding(.top, AppConstants.Spacing.lg)

                    // 药物类型选择
                    medicationTypeSelector

                    // 药物名称（可选）
                    nameField

                    // 日期时间
                    dateTimeSection
                }
                .padding(.vertical, AppConstants.Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.isEditMode ? String(localized: "medication.edit") : "")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) {
                        viewModel.saveRecord(modelContext: modelContext)
                        dismiss()
                    }
                    .disabled(!viewModel.isSaveEnabled || viewModel.isSaving)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - 剂量输入

    private var dosageInputSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            TextField("0", text: $viewModel.dosageText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.glucoseDisplay)
                .foregroundStyle(viewModel.dosageText.isEmpty ? Color(.tertiaryLabel) : .primary)
                .onChange(of: viewModel.dosageText) { _, newValue in
                    viewModel.validateDosageInput(newValue)
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

    
}

#Preview {
    @Previewable @State var viewModel = MedicationViewModel()
    MedicationInputView(viewModel: viewModel)
        .modelContainer(for: [MedicationRecord.self], inMemory: true)
}
