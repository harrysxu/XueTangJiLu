//
//  MealPhotoView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

private struct ImageTransferable: Transferable {
    let data: Data
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            ImageTransferable(data: data)
        }
    }
}

/// 饮食记录页
struct MealPhotoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var carbLevel: CarbLevel = .medium
    @State private var mealDescription: String = ""
    @State private var noteText: String = ""
    @State private var selectedDate: Date = .now
    @State private var showDatePicker = false
    @State private var isSaving = false
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showPhotoSection = false
    @State private var showCamera = false
    
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
                    carbLevelSelector
                    descriptionField
                    photoSectionToggle
                    if showPhotoSection {
                        photoSection
                    }
                    dateTimeSection
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
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera, selectedImageData: $selectedImageData)
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
                    carbLevelButton(for: level)
                }
            }
        }
    }

    private func carbLevelButton(for level: CarbLevel) -> some View {
        let isSelected = carbLevel == level
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                carbLevel = level
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: AppConstants.Spacing.xs) {
                Image(systemName: level.iconName)
                    .font(.title3)
                Text(level.localizedDisplayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppConstants.Spacing.md)
            .background(
                isSelected
                    ? Color(level.colorName).opacity(0.15)
                    : Color(.tertiarySystemGroupedBackground)
            )
            .foregroundStyle(
                isSelected
                    ? Color(level.colorName)
                    : .secondary
            )
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonMedium))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonMedium)
                    .stroke(
                        isSelected ? Color(level.colorName) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
    
    // MARK: - 照片开关

    private var photoSectionToggle: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showPhotoSection.toggle()
            }
        }) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.subheadline)
                Text(String(localized: "meal.photo.toggle"))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: showPhotoSection ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(showPhotoSection ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 照片区域

    private var photoSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            if let imageData = selectedImageData,
               let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))

                    Button {
                        withAnimation {
                            selectedImageData = nil
                            selectedItem = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .padding(8)
                }
            } else {
                HStack(spacing: AppConstants.Spacing.lg) {
                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: AppConstants.Spacing.xs) {
                            Image(systemName: "camera")
                                .font(.title3)
                            Text(String(localized: "meal.photo.camera"))
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.Spacing.lg)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonMedium))
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        VStack(spacing: AppConstants.Spacing.xs) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                            Text(String(localized: "meal.photo.library"))
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.Spacing.lg)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonMedium))
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.secondary)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task { @MainActor in
                if let result = try? await newItem.loadTransferable(type: ImageTransferable.self),
                   let uiImage = UIImage(data: result.data) {
                    let resized = uiImage.resizedForMealStorage()
                    selectedImageData = resized.jpegData(compressionQuality: 0.7)
                }
            }
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

        if let existingRecord = editingRecord {
            existingRecord.carbLevel = carbLevel
            existingRecord.mealDescription = mealDescription
            existingRecord.timestamp = selectedDate
            existingRecord.note = noteText.isEmpty ? nil : noteText
            existingRecord.photoData = selectedImageData
        } else {
            let record = MealRecord(
                carbLevel: carbLevel,
                mealDescription: mealDescription,
                timestamp: selectedDate,
                note: noteText.isEmpty ? nil : noteText,
                photoData: selectedImageData
            )
            modelContext.insert(record)
        }

        HapticManager.success()
        isSaving = false
        dismiss()
    }
}

// MARK: - UIImage 压缩扩展

private extension UIImage {
    func resizedForMealStorage(maxDimension: CGFloat = 1024) -> UIImage {
        let longerSide = max(size.width, size.height)
        guard longerSide > maxDimension else { return self }
        let scale = maxDimension / longerSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

#Preview {
    MealPhotoView(editingRecord: nil)
        .modelContainer(for: [MealRecord.self], inMemory: true)
}
