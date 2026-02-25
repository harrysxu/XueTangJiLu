//
//  MealPhotoView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData
import PhotosUI

/// 饮食记录页
struct MealPhotoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var carbLevel: CarbLevel = .medium
    @State private var mealDescription: String = ""
    @State private var noteText: String = ""
    @State private var selectedDate: Date = .now
    @State private var showDatePicker = false
    @State private var showPhotoSection = false
    @State private var showCamera = false
    @State private var isSaving = false
    
    /// 编辑模式：正在编辑的记录
    var editingRecord: MealRecord? = nil
    
    /// 是否处于编辑模式
    private var isEditMode: Bool {
        editingRecord != nil
    }
    
    init(editingRecord: MealRecord? = nil) {
        self.editingRecord = editingRecord
        if let record = editingRecord {
            _carbLevel = State(initialValue: record.carbLevel)
            _mealDescription = State(initialValue: record.mealDescription)
            _noteText = State(initialValue: record.note ?? "")
            _selectedDate = State(initialValue: record.timestamp)
            _selectedImageData = State(initialValue: record.photoData)
            _showPhotoSection = State(initialValue: record.hasPhoto)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    // 碳水水平选择
                    carbLevelSelector

                    // 饮食描述
                    descriptionField

                    // 照片区域（可选）
                    photoSectionToggle

                    // 日期时间
                    dateTimeSection

                    // 备注
                    noteField
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.lg)
            }
            .navigationTitle(isEditMode ? String(localized: "meal.edit") : String(localized: "meal.record"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) { saveMeal() }
                        .disabled(!isSaveEnabled || isSaving)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - 照片区域切换

    private var photoSectionToggle: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            HStack {
                Text(String(localized: "meal.photo"))
                    .font(.subheadline.weight(.medium))
                Text(String(localized: "meal.optional"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if selectedImageData != nil || showPhotoSection {
                    Button(action: {
                        withAnimation {
                            showPhotoSection.toggle()
                            if !showPhotoSection {
                                selectedImageData = nil
                                selectedItem = nil
                            }
                        }
                    }) {
                        Image(systemName: showPhotoSection ? "chevron.up.circle" : "chevron.down.circle")
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }
            
            if showPhotoSection {
                photoSection
            } else {
                Button(action: {
                    withAnimation {
                        showPhotoSection = true
                    }
                }) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.title3)
                        Text(String(localized: "meal.add_photo"))
                            .font(.subheadline)
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 照片区域

    private var photoSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            if let imageData = selectedImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                    .overlay(alignment: .topTrailing) {
                        Button(action: { 
                            selectedImageData = nil
                            selectedItem = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .padding(8)
                    }
            } else {
                HStack(spacing: AppConstants.Spacing.xl) {
                    // 拍照按钮
                    Button(action: { showCamera = true }) {
                        VStack(spacing: AppConstants.Spacing.sm) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(Color.brandPrimary)
                            Text(String(localized: "meal.take_photo"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                    }
                    .buttonStyle(.plain)

                    // 相册选择
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: AppConstants.Spacing.sm) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundStyle(Color.brandPrimary)
                            Text(String(localized: "meal.choose_from_library"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }

    // MARK: - 碳水水平选择器

    private var carbLevelSelector: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text(String(localized: "meal.carb_level"))
                .font(.subheadline.weight(.medium))

            HStack(spacing: AppConstants.Spacing.md) {
                ForEach(CarbLevel.allCases, id: \.self) { level in
                    Button(action: {
                        HapticManager.selection()
                        carbLevel = level
                    }) {
                        VStack(spacing: AppConstants.Spacing.xs) {
                            Image(systemName: level.iconName)
                                .font(.title3)
                            Text(level.localizedDisplayName)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.Spacing.md)
                        .background(
                            carbLevel == level
                                ? Color(level.colorName).opacity(0.15)
                                : Color(.tertiarySystemGroupedBackground)
                        )
                        .foregroundStyle(
                            carbLevel == level
                                ? Color(level.colorName)
                                : .secondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonMedium)
                                .stroke(
                                    carbLevel == level ? Color(level.colorName) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 饮食描述

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            HStack {
                Text(String(localized: "meal.description"))
                    .font(.subheadline.weight(.medium))
                Text("*")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.red)
            }
            TextField(String(localized: "meal.description_placeholder"), text: $mealDescription)
                .font(.subheadline)
                .padding(AppConstants.Spacing.md)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.input))
        }
    }
    
    // MARK: - 保存验证
    
    private var isSaveEnabled: Bool {
        !mealDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - 日期时间

    private var dateTimeSection: some View {
        Button(action: { showDatePicker.toggle() }) {
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text(selectedDate.fullDateTimeString)
                    .font(.footnote)
            }
            .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker(String(localized: "select.datetime"), selection: $selectedDate, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
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

    // MARK: - 备注

    private var noteField: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text(String(localized: "note"))
                .font(.subheadline.weight(.medium))
            TextField(String(localized: "add.note.optional"), text: $noteText)
                .font(.subheadline)
                .padding(AppConstants.Spacing.md)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.input))
        }
    }

    // MARK: - 保存

    private func saveMeal() {
        guard !mealDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isSaving = true

        // 压缩照片
        var compressedData: Data?
        if let imageData = selectedImageData,
           let uiImage = UIImage(data: imageData) {
            compressedData = uiImage.jpegData(compressionQuality: 0.6)
        }

        if let existingRecord = editingRecord {
            // 编辑模式：更新现有记录
            existingRecord.carbLevel = carbLevel
            existingRecord.mealDescription = mealDescription
            existingRecord.photoData = compressedData
            existingRecord.timestamp = selectedDate
            existingRecord.note = noteText.isEmpty ? nil : noteText
        } else {
            // 新建模式：创建新记录
            let record = MealRecord(
                carbLevel: carbLevel,
                mealDescription: mealDescription,
                photoData: compressedData,
                timestamp: selectedDate,
                note: noteText.isEmpty ? nil : noteText
            )
            modelContext.insert(record)
        }

        HapticManager.success()
        isSaving = false
        dismiss()
    }
}

#Preview {
    MealPhotoView(editingRecord: nil)
        .modelContainer(for: [MealRecord.self], inMemory: true)
}
