//
//  LogView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData

/// 记录 Tab - 统一记录入口 + 时间线历史
struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKitManager
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var records: [GlucoseRecord]
    @Query(sort: \MedicationRecord.timestamp, order: .reverse) private var medications: [MedicationRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var showRecordInput = false
    @State private var showMedicationInput = false
    @State private var glucoseViewModel = GlucoseViewModel()
    @State private var medicationViewModel = MedicationViewModel()
    @State private var selectedSegment: RecordSegment = .glucose

    enum RecordSegment: String, CaseIterable {
        case glucose = "血糖"
        case medication = "用药"
    }

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    /// 按日期分组的血糖记录
    private var groupedRecords: [(String, [GlucoseRecord])] {
        let grouped = Dictionary(grouping: records) { record in
            record.timestamp.startOfDay
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date, records) in
                (date.sectionTitle, records.sorted { $0.timestamp > $1.timestamp })
            }
    }

    /// 按日期分组的用药记录
    private var groupedMedications: [(String, [MedicationRecord])] {
        let grouped = Dictionary(grouping: medications) { record in
            record.timestamp.startOfDay
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date, records) in
                (date.sectionTitle, records.sorted { $0.timestamp > $1.timestamp })
            }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部分段选择器
                Picker("记录类型", selection: $selectedSegment) {
                    ForEach(RecordSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.top, AppConstants.Spacing.sm)

                // 内容区域
                ZStack(alignment: .bottom) {
                    switch selectedSegment {
                    case .glucose:
                        glucoseTimeline
                    case .medication:
                        medicationTimeline
                    }

                    // FAB 按钮
                    fabButton
                }
            }
            .navigationTitle("记录")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showRecordInput) {
                RecordInputView(viewModel: $glucoseViewModel)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMedicationInput) {
                MedicationInputView(viewModel: $medicationViewModel)
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 血糖时间线

    private var glucoseTimeline: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if records.isEmpty {
                    EmptyStateView(
                        icon: "drop",
                        title: "还没有血糖记录",
                        subtitle: "点击下方 \"+\" 开始记录"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(groupedRecords, id: \.0) { sectionTitle, sectionRecords in
                        Section {
                            ForEach(sectionRecords) { record in
                                TimelineRowView(record: record, unit: unit)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            glucoseViewModel.deleteRecord(record, modelContext: modelContext)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            Text(sectionTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, AppConstants.Spacing.lg)
                                .padding(.top, AppConstants.Spacing.lg)
                                .padding(.bottom, AppConstants.Spacing.xs)
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - 用药时间线

    private var medicationTimeline: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if medications.isEmpty {
                    EmptyStateView(
                        icon: "syringe",
                        title: "还没有用药记录",
                        subtitle: "点击下方 \"+\" 开始记录用药"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(groupedMedications, id: \.0) { sectionTitle, sectionRecords in
                        Section {
                            ForEach(sectionRecords) { record in
                                MedicationRowView(record: record)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            medicationViewModel.deleteRecord(record, modelContext: modelContext)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            Text(sectionTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, AppConstants.Spacing.lg)
                                .padding(.top, AppConstants.Spacing.lg)
                                .padding(.bottom, AppConstants.Spacing.xs)
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button(action: {
            HapticManager.light()
            switch selectedSegment {
            case .glucose:
                glucoseViewModel.resetInput()
                showRecordInput = true
            case .medication:
                medicationViewModel.resetInput()
                showMedicationInput = true
            }
        }) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: AppConstants.Size.fabSize, height: AppConstants.Size.fabSize)
                .background(Color.brandPrimary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .padding(.bottom, AppConstants.Spacing.lg)
        .accessibilityLabel(selectedSegment == .glucose ? "添加血糖记录" : "添加用药记录")
    }
}

// MARK: - 用药行视图

struct MedicationRowView: View {
    let record: MedicationRecord

    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            // 左侧：图标
            Image(systemName: record.medicationType.iconName)
                .font(.body)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 32, height: 32)
                .background(Color.brandPrimary.opacity(0.12))
                .clipShape(Circle())

            // 中间：类型 + 名称
            VStack(alignment: .leading, spacing: 2) {
                Text(record.medicationType.displayName)
                    .font(.subheadline)
                if !record.name.isEmpty {
                    Text(record.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 右侧：时间 + 剂量
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.displayDosage)
                    .font(.glucoseCallout)
                    .foregroundStyle(.primary)
                Text(record.timestamp, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, AppConstants.Spacing.sm)
        .padding(.horizontal, AppConstants.Spacing.lg)
    }
}

#Preview {
    LogView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self], inMemory: true)
        .environment(HealthKitManager())
}
