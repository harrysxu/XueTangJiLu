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
    @State private var showCamera = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    // 照片区域
                    photoSection

                    // 碳水水平选择
                    carbLevelSelector

                    // 饮食描述
                    descriptionField

                    // 日期时间
                    dateTimeSection

                    // 备注
                    noteField
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.lg)
            }
            .navigationTitle("记录饮食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveMeal() }
                        .disabled(isSaving)
                        .fontWeight(.semibold)
                }
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
                        Button(action: { selectedImageData = nil }) {
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
                            Text("拍照")
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
                            Text("相册")
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
            Text("碳水水平")
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
                            Text(level.displayName)
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
            Text("饮食描述")
                .font(.subheadline.weight(.medium))
            TextField("如\"米饭 + 青菜 + 鸡胸肉\"", text: $mealDescription)
                .font(.subheadline)
                .padding(AppConstants.Spacing.md)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.input))
        }
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
                DatePicker("选择时间", selection: $selectedDate, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .padding()
                    .navigationTitle("选择时间")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完成") { showDatePicker = false }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - 备注

    private var noteField: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("备注")
                .font(.subheadline.weight(.medium))
            TextField("可选备注", text: $noteText)
                .font(.subheadline)
                .padding(AppConstants.Spacing.md)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.input))
        }
    }

    // MARK: - 保存

    private func saveMeal() {
        isSaving = true

        // 压缩照片
        var compressedData: Data?
        if let imageData = selectedImageData,
           let uiImage = UIImage(data: imageData) {
            compressedData = uiImage.jpegData(compressionQuality: 0.6)
        }

        let record = MealRecord(
            carbLevel: carbLevel,
            mealDescription: mealDescription,
            photoData: compressedData,
            timestamp: selectedDate,
            note: noteText.isEmpty ? nil : noteText
        )

        modelContext.insert(record)
        HapticManager.success()
        isSaving = false
        dismiss()
    }
}

#Preview {
    MealPhotoView()
        .modelContainer(for: [MealRecord.self], inMemory: true)
}
