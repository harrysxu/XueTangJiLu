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
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var records: [GlucoseRecord]
    @Query(sort: \MedicationRecord.timestamp, order: .reverse) private var medications: [MedicationRecord]
    @Query(sort: \MealRecord.timestamp, order: .reverse) private var meals: [MealRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var showRecordInput = false
    @State private var showMedicationInput = false
    @State private var showMealInput = false
    @State private var glucoseViewModel = GlucoseViewModel()
    @State private var medicationViewModel = MedicationViewModel()
    @State private var selectedRecordTypes: Set<RecordType> = [.glucose, .medication, .meal]
    @State private var selectedTimeRange: TimeRange = .all
    @State private var showCustomDateRange = false
    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var recordToEdit: GlucoseRecord? = nil
    @State private var medicationToEdit: MedicationRecord? = nil
    @State private var mealToEdit: MealRecord? = nil
    @State private var showMealPaywall = false
    
    enum RecordType: String, CaseIterable, Identifiable {
        case glucose = "血糖"
        case medication = "用药"
        case meal = "饮食"
        var id: String { rawValue }
        var localizedLabel: String {
            switch self {
            case .glucose: return String(localized: "log.type.glucose")
            case .medication: return String(localized: "log.type.medication")
            case .meal: return String(localized: "log.type.meal")
            }
        }
    }
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case today = "今天"
        case last7Days = "最近1周"
        case last30Days = "最近1月"
        case last90Days = "最近3月"
        case custom = "自定义"
        case all = "全部"
        var id: String { rawValue }
        var localizedLabel: String {
            switch self {
            case .today: return String(localized: "log.time.today")
            case .last7Days: return String(localized: "log.time.last_7")
            case .last30Days: return String(localized: "log.time.last_30")
            case .last90Days: return String(localized: "log.time.last_90")
            case .custom: return String(localized: "log.time.custom")
            case .all: return String(localized: "log.time.all")
            }
        }
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

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }
    
    /// 合并所有记录并应用筛选
    private var filteredTimelineItems: [TimelineItem] {
        // 根据记录类型筛选合并
        var allItems: [TimelineItem] = []
        if selectedRecordTypes.contains(.glucose) {
            allItems += records.map { .glucose($0) }
        }
        if selectedRecordTypes.contains(.medication) {
            allItems += medications.map { .medication($0) }
        }
        if selectedRecordTypes.contains(.meal) {
            allItems += meals.map { .meal($0) }
        }
        
        // 时间范围筛选
        let filtered = allItems.filter { item in
            timeRangeFilter(item.timestamp)
        }
        
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// 时间范围过滤器
    private func timeRangeFilter(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .today:
            return calendar.isDateInToday(date)
        case .last7Days:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
            return date >= weekAgo
        case .last30Days:
            guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return false }
            return date >= monthAgo
        case .last90Days:
            guard let threeMonthsAgo = calendar.date(byAdding: .day, value: -90, to: now) else { return false }
            return date >= threeMonthsAgo
        case .custom:
            let startOfCustomStart = calendar.startOfDay(for: customStartDate)
            let endOfCustomEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEndDate)) ?? customEndDate
            return date >= startOfCustomStart && date < endOfCustomEnd
        case .all:
            return true
        }
    }
    
    /// 按日期分组的时间轴（已筛选）
    private var groupedTimelineItems: [(String, [TimelineItem])] {
        let grouped = Dictionary(grouping: filteredTimelineItems) { item in
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
                // 统一时间轴内容
                unifiedTimeline
                
                // FAB 按钮 - 改为 Menu
                fabMenuButton
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterMenu
                }
            }
            .sheet(isPresented: $showRecordInput) {
                RecordInputView(viewModel: glucoseViewModel)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMedicationInput) {
                MedicationInputView(viewModel: medicationViewModel)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMealInput) {
                MealPhotoView(editingRecord: mealToEdit)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCustomDateRange) {
                CustomDateRangePickerView(
                    startDate: $customStartDate,
                    endDate: $customEndDate
                )
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
            .onChange(of: showMealInput) { oldValue, newValue in
                if !newValue {
                    mealToEdit = nil
                }
            }
            .sheet(isPresented: $showMealPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - 筛选菜单
    
    private var filterMenu: some View {
        Menu {
            // 记录类型筛选（包含"全部"）
            Button {
                selectedRecordTypes = [.glucose, .medication, .meal]
                selectedTimeRange = .all
            } label: {
                Label(
                    String(localized: "log.time.all"),
                    systemImage: (selectedRecordTypes.count == 3 && selectedTimeRange == .all) ? "checkmark.circle.fill" : "circle"
                )
            }
            
            Button {
                selectedRecordTypes = [.glucose]
            } label: {
                Label(
                    RecordType.glucose.localizedLabel,
                    systemImage: (selectedRecordTypes == [.glucose]) ? "checkmark.circle.fill" : "circle"
                )
            }
            
            Button {
                selectedRecordTypes = [.medication]
            } label: {
                Label(
                    RecordType.medication.localizedLabel,
                    systemImage: (selectedRecordTypes == [.medication]) ? "checkmark.circle.fill" : "circle"
                )
            }
            
            Button {
                selectedRecordTypes = [.meal]
            } label: {
                Label(
                    RecordType.meal.localizedLabel,
                    systemImage: (selectedRecordTypes == [.meal]) ? "checkmark.circle.fill" : "circle"
                )
            }
            
            Divider()
            
            // 时间范围筛选
            ForEach([TimeRange.today, .last7Days, .last30Days, .last90Days], id: \.self) { range in
                Button {
                    selectedTimeRange = range
                    // 如果选择了时间范围但没有选择记录类型，自动选择所有类型
                    if selectedRecordTypes.isEmpty {
                        selectedRecordTypes = [.glucose, .medication, .meal]
                    }
                } label: {
                    Label(
                        range.localizedLabel,
                        systemImage: selectedTimeRange == range ? "checkmark.circle.fill" : "circle"
                    )
                }
            }
            
            Button {
                selectedTimeRange = .custom
                showCustomDateRange = true
                // 如果选择了自定义时间但没有选择记录类型，自动选择所有类型
                if selectedRecordTypes.isEmpty {
                    selectedRecordTypes = [.glucose, .medication, .meal]
                }
            } label: {
                Label(
                    customDateRangeLabel,
                    systemImage: selectedTimeRange == .custom ? "checkmark.circle.fill" : "circle"
                )
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(isFilterActive ? Color.brandPrimary : .primary)
        }
        .accessibilityLabel(String(localized: "log.filter_records"))
    }
    
    /// 是否有激活的筛选条件
    private var isFilterActive: Bool {
        selectedRecordTypes.count < RecordType.allCases.count || selectedTimeRange != .all
    }
    
    /// 自定义日期范围标签
    private var customDateRangeLabel: String {
        if selectedTimeRange == .custom {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let start = formatter.string(from: customStartDate)
            let end = formatter.string(from: customEndDate)
            return String(format: String(localized: "log.custom_range"), start, end)
        } else {
            return TimeRange.custom.localizedLabel
        }
    }
    
    /// 空状态标题
    private var emptyStateTitle: String {
        if records.isEmpty && medications.isEmpty && meals.isEmpty {
            return String(localized: "empty.no_records")
        } else if isFilterActive {
            return String(localized: "log.empty.filtered")
        } else {
            return String(localized: "empty.no_records")
        }
    }
    
    /// 空状态副标题
    private var emptyStateSubtitle: String {
        if records.isEmpty && medications.isEmpty && meals.isEmpty {
            return String(localized: "log.empty.tap_add")
        } else if isFilterActive {
            return String(localized: "log.empty.hint")
        } else {
            return String(localized: "log.empty.tap_add")
        }
    }

    // MARK: - 统一时间轴

    private var unifiedTimeline: some View {
        Group {
            if filteredTimelineItems.isEmpty {
                ScrollView {
                    EmptyStateView(
                        icon: "line.3.horizontal.decrease.circle",
                        title: emptyStateTitle,
                        subtitle: emptyStateSubtitle
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
                .background(Color.pageBackground)
            } else {
                List {
                    ForEach(groupedTimelineItems, id: \.0) { sectionTitle, sectionItems in
                        Section {
                            ForEach(Array(sectionItems.enumerated()), id: \.element.id) { index, item in
                                VStack(spacing: 0) {
                                    Group {
                                        switch item {
                                        case .glucose(let record):
                                            Button(action: {
                                                recordToEdit = record
                                            }) {
                                                TimelineRowView(record: record, unit: unit, settings: settings)
                                            }
                                            .buttonStyle(.plain)
                                        case .medication(let record):
                                            Button(action: {
                                                medicationToEdit = record
                                            }) {
                                                MedicationRowView(record: record)
                                            }
                                            .buttonStyle(.plain)
                                        case .meal(let record):
                                            Button(action: {
                                                if FeatureManager.canAccessFeature(.mealPhotoTracking, isPremium: subscriptionManager.isPremiumUser) {
                                                    mealToEdit = record
                                                    showMealInput = true
                                                } else {
                                                    showMealPaywall = true
                                                }
                                            }) {
                                                MealRowView(record: record)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    
                                    if index < sectionItems.count - 1 {
                                        Divider()
                                            .padding(.horizontal, AppConstants.Spacing.lg)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        switch item {
                                        case .glucose(let record):
                                            glucoseViewModel.deleteRecord(record, modelContext: modelContext)
                                        case .medication(let record):
                                            medicationViewModel.deleteRecord(record, modelContext: modelContext)
                                        case .meal(let record):
                                            modelContext.delete(record)
                                        }
                                    } label: {
                                        Label(String(localized: "log.delete"), systemImage: "trash")
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowSeparator(.hidden)
                                .listRowBackground(
                                    // 根据位置决定圆角
                                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                                        .fill(Color.cardBackground)
                                )
                            }
                        } header: {
                            Text(sectionTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                                .padding(.bottom, AppConstants.Spacing.xs)
                        }
                        .listSectionSeparator(.hidden)
                    }
                    .listSectionSpacing(AppConstants.Spacing.md)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.pageBackground)
                .contentMargins(.top, AppConstants.Spacing.md, for: .scrollContent)
                .contentMargins(.bottom, 100, for: .scrollContent)
                .contentMargins(.horizontal, AppConstants.Spacing.lg, for: .scrollContent)
                .environment(\.defaultMinListRowHeight, 0)
            }
        }
    }

    // MARK: - FAB Menu

    private var fabMenuButton: some View {
        Menu {
            Button {
                HapticManager.light()
                glucoseViewModel.resetInput()
                showRecordInput = true
            } label: {
                Label(String(localized: "quick.glucose"), systemImage: "drop.fill")
            }
            
            Button {
                HapticManager.light()
                medicationViewModel.resetInput()
                showMedicationInput = true
            } label: {
                Label(String(localized: "quick.medication"), systemImage: "syringe.fill")
            }
            
            Button {
                HapticManager.light()
                if FeatureManager.canAccessFeature(.mealPhotoTracking, isPremium: subscriptionManager.isPremiumUser) {
                    showMealInput = true
                } else {
                    showMealPaywall = true
                }
            } label: {
                Label(String(localized: "meal.record"), systemImage: "fork.knife")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: AppConstants.Size.fabSize, height: AppConstants.Size.fabSize)
                .background(Color.brandPrimary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .padding(.bottom, AppConstants.Spacing.lg)
        .accessibilityLabel(String(localized: "log.add_record"))
    }
}


#Preview {
    LogView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self, MealRecord.self], inMemory: true)
        .environment(HealthKitManager())
        .environment(SubscriptionManager())
}
