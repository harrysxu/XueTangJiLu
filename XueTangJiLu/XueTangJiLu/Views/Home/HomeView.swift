//
//  HomeView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData

/// 首页 - 记录流
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKitManager
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var records: [GlucoseRecord]
    @Query(sort: \MedicationRecord.timestamp, order: .reverse) private var medications: [MedicationRecord]
    @Query(sort: \MealRecord.timestamp, order: .reverse) private var meals: [MealRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var showRecordInput = false
    @State private var glucoseViewModel = GlucoseViewModel()
    @State private var showDisclaimer = false
    @State private var recordToEdit: GlucoseRecord? = nil
    @State private var medicationViewModel = MedicationViewModel()
    @State private var medicationToEdit: MedicationRecord? = nil
    @State private var mealToEdit: MealRecord? = nil
    @State private var showMedicationInput = false
    @State private var showMealInput = false

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }

    /// 最新一条记录
    private var latestRecord: GlucoseRecord? {
        records.first
    }

    /// 今日记录
    private var todayRecords: [GlucoseRecord] {
        records.filter { $0.timestamp.isToday }
    }
    
    /// 合并的时间轴项目
    private enum TimelineItem: Identifiable {
        case glucose(GlucoseRecord)
        case medication(MedicationRecord)
        case meal(MealRecord)
        
        var id: String {
            switch self {
            case .glucose(let record):
                return "glucose-\(record.id)"
            case .medication(let record):
                return "medication-\(record.id)"
            case .meal(let record):
                return "meal-\(record.id)"
            }
        }
        
        var timestamp: Date {
            switch self {
            case .glucose(let record):
                return record.timestamp
            case .medication(let record):
                return record.timestamp
            case .meal(let record):
                return record.timestamp
            }
        }
    }

    /// 按日期分组的记录
    private var groupedRecords: [(String, [TimelineItem])] {
        // 合并所有记录
        var allItems: [TimelineItem] = []
        allItems += records.map { .glucose($0) }
        allItems += medications.map { .medication($0) }
        allItems += meals.map { .meal($0) }
        
        // 按日期分组
        let grouped = Dictionary(grouping: allItems) { item in
            item.timestamp.startOfDay
        }
        
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date, items) in
                (date.sectionTitle, items.sorted { $0.timestamp > $1.timestamp })
            }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // 今日总结卡片
                        DailySummaryCard(
                            todayRecords: todayRecords,
                            allRecords: records,
                            settings: settings
                        )
                        .padding(.top)
                        
                        if records.isEmpty {
                            EmptyStateView(
                                icon: "drop",
                                title: String(localized: "home.empty.title"),
                                subtitle: String(localized: "home.empty.subtitle")
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else {
                            // 最新血糖 Hero 区域
                            latestGlucoseSection

                            // 今日概要
                            todaySummarySection

                            // 时间轴列表
                            timelineSection
                        }
                    }
                    // 底部留白，避免 FAB 遮挡
                    .padding(.bottom, 100)
                }

                // 浮动录入按钮 (FAB)
                fabButton
            }
            .navigationTitle(String(localized: "home.title"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showRecordInput) {
                RecordInputView(viewModel: glucoseViewModel)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMedicationInput) {
                MedicationInputView(viewModel: medicationViewModel)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMealInput) {
                MealPhotoView()
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $mealToEdit) { record in
                MealPhotoView(editingRecord: record)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showDisclaimer) {
                DisclaimerView {
                    settings.hasSeenDisclaimer = true
                }
            }
            .onChange(of: recordToEdit) { oldValue, newValue in
                if let record = newValue {
                    glucoseViewModel.loadRecordForEditing(record, unit: unit)
                    showRecordInput = true
                }
            }
            .onChange(of: showRecordInput) { oldValue, newValue in
                if !newValue {
                    recordToEdit = nil
                }
            }
            .onChange(of: medicationToEdit) { oldValue, newValue in
                if let record = newValue {
                    medicationViewModel.loadRecordForEditing(record)
                    showMedicationInput = true
                }
            }
            .onChange(of: showMedicationInput) { oldValue, newValue in
                if !newValue {
                    medicationToEdit = nil
                }
            }
            .onAppear {
                // 首次启动显示免责声明
                if !settings.hasSeenDisclaimer {
                    showDisclaimer = true
                }
            }
        }
    }

    // MARK: - 最新血糖区域

    private var latestGlucoseSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            if let latest = latestRecord {
                Text(String(localized: "home.latest_glucose"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                GlucoseValueBadge(
                    value: latest.value,
                    unit: unit,
                    level: latest.glucoseLevel(with: settings),
                    style: .hero
                )
                .accessibilityIdentifier("latestGlucoseValue")

                HStack(spacing: AppConstants.Spacing.xs) {
                    Image(systemName: settings.iconName(for: latest.sceneTagId))
                        .font(.caption2)
                    Text(settings.displayName(for: latest.sceneTagId))
                        .font(.footnote)
                    Text("·")
                        .font(.footnote)
                    Text(latest.timestamp.relativeDescription)
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(latestAccessibilityLabel)
    }

    private var latestAccessibilityLabel: String {
        guard let latest = latestRecord else { return String(localized: "home.no_records_a11y") }
        return String(localized: "home.latest_a11y \(latest.displayValue(in: unit)) \(unit.rawValue) \(latest.glucoseLevel(with: settings).description) \(settings.displayName(for: latest.sceneTagId))")
    }

    // MARK: - 今日概要

    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text(String(localized: "home.today_summary"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppConstants.Spacing.lg)

            HStack(spacing: AppConstants.Spacing.sm) {
                StatCardView(
                    title: String(localized: "home.stat.count"),
                    value: "\(todayRecords.count)",
                    subtitle: String(localized: "home.stat.today")
                )

                StatCardView(
                    title: String(localized: "home.stat.average"),
                    value: todayAverage,
                    subtitle: unit.rawValue,
                    tintColor: todayAverageColor
                )

                StatCardView(
                    title: String(localized: "home.stat.tir"),
                    value: todayTIR,
                    subtitle: "TIR"
                )
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
        }
        .padding(.bottom, AppConstants.Spacing.xl)
    }

    private var todayAverage: String {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: todayRecords) else {
            return "--"
        }
        return GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)
    }

    private var todayAverageColor: Color? {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: todayRecords) else {
            return nil
        }
        return Color.forGlucoseValue(avg)
    }

    private var todayTIR: String {
        guard !todayRecords.isEmpty else { return "--" }
        let tir = GlucoseCalculator.contextualTimeInRange(
            records: todayRecords,
            settings: settings
        )
        return "\(Int(tir))%"
    }

    // MARK: - 时间轴

    private var timelineSection: some View {
        ForEach(groupedRecords, id: \.0) { sectionTitle, sectionRecords in
            Section {
                ForEach(sectionRecords) { item in
                    switch item {
                    case .glucose(let record):
                        Button(action: {
                            recordToEdit = record
                        }) {
                            TimelineRowView(record: record, unit: unit, settings: settings)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                glucoseViewModel.deleteRecord(record, modelContext: modelContext)
                            } label: {
                                Label(String(localized: "common.delete"), systemImage: "trash")
                            }
                        }
                    case .medication(let record):
                        Button(action: {
                            medicationToEdit = record
                        }) {
                            MedicationRowView(record: record)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                medicationViewModel.deleteRecord(record, modelContext: modelContext)
                            } label: {
                                Label(String(localized: "common.delete"), systemImage: "trash")
                            }
                        }
                    case .meal(let record):
                        Button(action: {
                            mealToEdit = record
                        }) {
                            MealRowView(record: record)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(record)
                            } label: {
                                Label(String(localized: "common.delete"), systemImage: "trash")
                            }
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

    // MARK: - 浮动录入按钮

    private var fabButton: some View {
        Button(action: {
            HapticManager.light()
            glucoseViewModel.resetInput()
            showRecordInput = true
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
        .accessibilityIdentifier("addRecord")
        .accessibilityLabel(String(localized: "home.add_record.a11y"))
        .accessibilityHint(String(localized: "home.add_record.hint"))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self, MealRecord.self], inMemory: true)
        .environment(HealthKitManager())
}
