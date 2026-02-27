//
//  StatisticsView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/14.
//

import SwiftUI
import SwiftData

/// 统计 Tab - 趋势图表 + 数据统计
struct StatisticsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \GlucoseRecord.timestamp, order: .reverse) private var allRecords: [GlucoseRecord]
    @Query private var settingsArray: [UserSettings]
    @State private var chartViewModel = ChartViewModel()
    @State private var showCustomDatePicker = false

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit {
        settings.preferredUnit
    }
    
    /// 根据付费状态过滤历史数据
    private var displayRecords: [GlucoseRecord] {
        if let daysLimit = FeatureManager.historyDaysLimit(isPremium: subscriptionManager.isPremiumUser) {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysLimit, to: .now)!
            return allRecords.filter { $0.timestamp >= cutoffDate }
        }
        return allRecords
    }

    private var rangeRecords: [GlucoseRecord] {
        chartViewModel.filteredRecords(from: displayRecords, settings: settings)
    }

    private var dataPoints: [ChartDataPoint] {
        chartViewModel.dataPoints(from: displayRecords, settings: settings)
    }

    /// 当前筛选的有效阈值
    private var effectiveRange: (low: Double, high: Double) {
        chartViewModel.effectiveThresholdRange(settings: settings)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppConstants.Spacing.xl) {
                        // 历史数据限制提示
                        if !subscriptionManager.isPremiumUser, 
                           let daysLimit = FeatureManager.historyDaysLimit(isPremium: false) {
                            LimitationBanner(limitationType: .historyDays(days: daysLimit))
                                .padding(.top)
                        }
                        
                        if allRecords.isEmpty {
                            EmptyStateView(
                                icon: "chart.bar.xaxis",
                                title: String(localized: "empty.no_trends"),
                                subtitle: String(localized: "empty.trends_hint")
                            )
                            .padding(.top, 60)
                        } else {
                            // 免责声明横幅
                            DisclaimerBanner()
                                .padding(.top)
                            
                            // 时间范围选择器
                            timeRangePicker

                            // 场景标签筛选器
                            tagFilterPicker

                            // 趋势折线图（使用动态阈值）
                            TrendLineChart(
                                dataPoints: dataPoints,
                                targetLow: effectiveRange.low,
                                targetHigh: effectiveRange.high,
                                unit: unit,
                                selectedPoint: $chartViewModel.selectedPoint
                            )

                            // 指标卡片
                            metricsGrid

                            // TAR / TBR 卡片
                            tarTbrCard

                            if FeatureManager.canAccessFeature(.advancedCharts, isPremium: subscriptionManager.isPremiumUser) {
                                perTagTIRChart
                                mealPairChart
                                weeklyComparison
                                singleSceneHourlyDistribution
                                singleSceneDailyTrend
                                tagDistributionChart
                            } else {
                                FeatureLockView(feature: .advancedCharts)
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.vertical, AppConstants.Spacing.lg)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - 时间范围选择器

    private var timeRangePicker: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            Picker(String(localized: "statistics.time_range"), selection: $chartViewModel.selectedRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.localizedDisplayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: chartViewModel.selectedRange) { _, newValue in
                if newValue == .custom {
                    showCustomDatePicker = true
                }
            }
            
            // 自定义日期范围显示
            if chartViewModel.selectedRange == .custom {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.brandPrimary)
                    
                    Text("\(chartViewModel.customStartDate.shortDateString) - \(chartViewModel.customEndDate.shortDateString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button {
                        showCustomDatePicker = true
                    } label: {
                        Text(String(localized: "record.modify"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brandPrimary.opacity(0.08))
                )
            }
        }
        .sheet(isPresented: $showCustomDatePicker) {
            CustomDateRangePickerView(
                startDate: $chartViewModel.customStartDate,
                endDate: $chartViewModel.customEndDate
            )
        }
    }

    // MARK: - 场景标签筛选器

    private var tagFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.sm) {
                tagFilterChip(label: String(localized: "statistics.filter_all"), filter: .all)

                ForEach(settings.visibleSceneTags) { tag in
                    tagFilterChip(label: tag.label, filter: .tag(tag.id))
                }
            }
        }
    }

    private func tagFilterChip(label: String, filter: TagFilter) -> some View {
        let isSelected = chartViewModel.selectedTagFilter == filter
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                chartViewModel.selectedTagFilter = filter
            }
        } label: {
            Text(label)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        isSelected
                            ? Color("BrandPrimary").opacity(0.15)
                            : Color(.tertiarySystemGroupedBackground)
                    )
                )
                .foregroundStyle(
                    isSelected ? Color("BrandPrimary") : .secondary
                )
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color("BrandPrimary").opacity(0.3) : .clear,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 指标网格

    private var metricsGrid: some View {
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Spacing.md) {
            metricCardWithExplanation(
                title: String(localized: "statistics.average"),
                value: averageGlucose,
                subtitle: unit.rawValue,
                tintColor: averageColor,
                metricType: .averageGlucose
            )

            metricCardWithExplanation(
                title: String(localized: "statistics.tir"),
                value: tirValue,
                subtitle: "TIR",
                tintColor: tirColor,
                metricType: .timeInRange
            )

            StatCardView(
                title: String(localized: "statistics.minmax"),
                value: minMaxValue,
                subtitle: unit.rawValue
            )

            StatCardView(
                title: String(localized: "statistics.records"),
                value: "\(rangeRecords.count)",
                subtitle: String(format: String(localized: "statistics.records_near"), chartViewModel.selectedRange.localizedDisplayName)
            )
            
            metricCardWithExplanation(
                title: String(localized: "statistics.eA1C"),
                value: eA1CValue,
                subtitle: "eA1C",
                tintColor: eA1CColor,
                metricType: .estimatedA1C
            )

            metricCardWithExplanation(
                title: String(localized: "statistics.cv.label"),
                value: cvValue,
                subtitle: "CV%",
                tintColor: cvColor,
                metricType: .coefficientOfVariation
            )
        }
    }
    
    /// 带解释说明的指标卡片
    private func metricCardWithExplanation(
        title: String,
        value: String,
        subtitle: String?,
        tintColor: Color?,
        metricType: MetricType
    ) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            HStack(spacing: 4) {
                if let subtitle {
                    Text("\(title) (\(subtitle))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                MetricExplanationView(metricType: metricType)
            }

            Text(value)
                .font(.glucoseMetric)
                .foregroundStyle(tintColor ?? .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppConstants.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value) \(subtitle ?? "")")
    }

    // MARK: - TAR / TBR 卡片

    private var tarTbrCard: some View {
        Group {
            if !rangeRecords.isEmpty {
                let isAll = chartViewModel.selectedTagFilter == .all
                let range = effectiveRange
                let tar = isAll
                    ? GlucoseCalculator.contextualTimeAboveRange(records: rangeRecords, settings: settings)
                    : GlucoseCalculator.timeAboveRange(records: rangeRecords, high: range.high)
                let tbr = isAll
                    ? GlucoseCalculator.contextualTimeBelowRange(records: rangeRecords, settings: settings)
                    : GlucoseCalculator.timeBelowRange(records: rangeRecords, low: range.low)
                let tir = isAll
                    ? GlucoseCalculator.contextualTimeInRange(records: rangeRecords, settings: settings)
                    : GlucoseCalculator.timeInRange(records: rangeRecords, low: range.low, high: range.high)

                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    HStack {
                        Text(String(localized: "statistics.glucose_distribution"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        MetricExplanationView(metricType: .glucoseDistribution)
                        
                        Spacer()
                    }

                    // 堆叠进度条
                    GeometryReader { geo in
                        HStack(spacing: 1) {
                            if tbr > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color("GlucoseLow"))
                                    .frame(width: max(4, geo.size.width * tbr / 100))
                            }
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color("GlucoseNormal"))
                                .frame(width: max(4, geo.size.width * tir / 100))
                            if tar > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color("GlucoseHigh"))
                                    .frame(width: max(4, geo.size.width * tar / 100))
                            }
                        }
                    }
                    .frame(height: 12)

                    // 数值标签
                    HStack {
                        tarTbrLabel(
                            title: String(localized: "statistics.below_range"),
                            value: "\(Int(tbr))%",
                            color: Color("GlucoseLow")
                        )
                        Spacer()
                        tarTbrLabel(
                            title: String(localized: "statistics.in_range"),
                            value: "\(Int(tir))%",
                            color: Color("GlucoseNormal")
                        )
                        Spacer()
                        tarTbrLabel(
                            title: String(localized: "statistics.above_range"),
                            value: "\(Int(tar))%",
                            color: Color("GlucoseHigh")
                        )
                    }
                }
                .padding(AppConstants.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.cardBackground)
                )
            }
        }
    }

    private func tarTbrLabel(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(value)
                    .font(.glucoseCallout)
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 按标签 TIR 对比图

    private var perTagTIRChart: some View {
        let byTag = Dictionary(grouping: rangeRecords) { $0.sceneTagId }

        var tagTIRs: [(id: String, name: String, tir: Double, count: Int)] = []
        for (tagId, tagRecords) in byTag {
            // 至少需要3条记录才有统计意义
            guard tagRecords.count >= 3 else { continue }
            let range = settings.thresholdRange(for: tagId)
            let inRange = tagRecords.filter { $0.value >= range.low && $0.value <= range.high }
            let tir = Double(inRange.count) / Double(tagRecords.count) * 100.0
            let name = settings.displayName(for: tagId)
            tagTIRs.append((tagId, name, tir, tagRecords.count))
        }

        let sorted = tagTIRs.sorted { $0.tir > $1.tir }

        return Group {
            if chartViewModel.selectedTagFilter == .all && sorted.count >= 2 {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    HStack {
                        Text(String(localized: "statistics.per_tag_tir"))
                            .font(.subheadline.weight(.semibold))
                        
                        MetricExplanationView(metricType: .perTagTIR)
                        
                        Spacer()
                    }

                    VStack(spacing: AppConstants.Spacing.sm) {
                        ForEach(sorted, id: \.id) { item in
                            HStack(spacing: AppConstants.Spacing.sm) {
                                Text(item.name)
                                    .font(.caption)
                                    .frame(width: 50, alignment: .trailing)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(.systemGray5))
                                            .frame(height: 14)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(item.tir >= AppConstants.tirGoodThreshold
                                                  ? Color("GlucoseNormal")
                                                  : (item.tir >= 50 ? Color("GlucoseHigh") : Color("GlucoseVeryHigh")))
                                            .frame(width: max(4, geo.size.width * item.tir / 100), height: 14)
                                    }
                                }
                                .frame(height: 14)

                                Text("\(Int(item.tir))%")
                                    .font(.caption.monospacedDigit().weight(.medium))
                                    .frame(width: 40, alignment: .trailing)
                                    .foregroundStyle(item.tir >= AppConstants.tirGoodThreshold ? Color("GlucoseNormal") : Color("GlucoseHigh"))
                            }
                        }
                    }
                }
                .padding(AppConstants.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.cardBackground)
                )
            }
        }
    }

    // MARK: - 餐前餐后配对图

    private var mealPairChart: some View {
        let fastingRecords = rangeRecords.filter { $0.thresholdGroup(from: settings) == .fasting }
        let postprandialRecords = rangeRecords.filter { $0.thresholdGroup(from: settings) == .postprandial }

        let calendar = Calendar.current
        var pairs: [(date: Date, preName: String, preValue: Double, postName: String, postValue: Double, spike: Double)] = []

        for postRec in postprandialRecords {
            // 单场景模式下，只显示与选中场景相关的配对
            if case .tag(let selectedTagId) = chartViewModel.selectedTagFilter {
                // 如果选中的是餐后标签，则配对必须包含该餐后标签
                if postRec.sceneTagId != selectedTagId {
                    continue
                }
            }
            
            let sameDayFasting = fastingRecords.filter {
                calendar.isDate($0.timestamp, inSameDayAs: postRec.timestamp)
                && $0.timestamp < postRec.timestamp
                && postRec.timestamp.timeIntervalSince($0.timestamp) <= 4 * 3600
            }
            if let closest = sameDayFasting.max(by: { $0.timestamp < $1.timestamp }) {
                // 单场景模式下，如果选中的是餐前标签，配对必须包含该餐前标签
                if case .tag(let selectedTagId) = chartViewModel.selectedTagFilter {
                    let selectedGroup = settings.thresholdGroup(for: selectedTagId)
                    if selectedGroup == .fasting && closest.sceneTagId != selectedTagId {
                        continue
                    }
                }
                
                let spike = postRec.value - closest.value
                pairs.append((
                    date: postRec.timestamp,
                    preName: settings.displayName(for: closest.sceneTagId),
                    preValue: closest.value,
                    postName: settings.displayName(for: postRec.sceneTagId),
                    postValue: postRec.value,
                    spike: spike
                ))
            }
        }

        let sortedPairs = pairs.sorted { $0.date > $1.date }.prefix(10)

        return Group {
            if sortedPairs.count >= 2 {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    HStack {
                        Text(String(localized: "statistics.meal_pair"))
                            .font(.subheadline.weight(.semibold))
                        
                        MetricExplanationView(metricType: .mealPair)
                        
                        Spacer()
                        Text(String(localized: "statistics.spike_hint"))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    VStack(spacing: AppConstants.Spacing.sm) {
                        ForEach(Array(sortedPairs.enumerated()), id: \.offset) { _, pair in
                            HStack(spacing: AppConstants.Spacing.sm) {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(pair.date.shortDateString)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text(pair.postName)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 56, alignment: .trailing)

                                mealPairDumbbell(preValue: pair.preValue, postValue: pair.postValue, spike: pair.spike)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("+\(String(format: "%.1f", pair.spike))")
                                        .font(.caption.monospacedDigit().weight(.medium))
                                        .foregroundStyle(pair.spike > 3.0 ? Color("GlucoseVeryHigh") : Color("GlucoseNormal"))
                                    Text(unit.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(width: 50, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(AppConstants.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.cardBackground)
                )
            }
        }
    }

    /// 哑铃图：展示餐前到餐后的血糖变化
    private func mealPairDumbbell(preValue: Double, postValue: Double, spike: Double) -> some View {
        GeometryReader { geo in
            let minVal = max(2.0, min(preValue, postValue) - 1.0)
            let maxVal = max(preValue, postValue) + 1.0
            let range = maxVal - minVal
            let preX = (preValue - minVal) / range * geo.size.width
            let postX = (postValue - minVal) / range * geo.size.width

            ZStack(alignment: .leading) {
                // 连接线
                Path { path in
                    path.move(to: CGPoint(x: preX, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: postX, y: geo.size.height / 2))
                }
                .stroke(spike > 3.0 ? Color("GlucoseVeryHigh").opacity(0.5) : Color("GlucoseNormal").opacity(0.5), lineWidth: 2)

                // 餐前点
                Circle()
                    .fill(Color("GlucoseNormal"))
                    .frame(width: 8, height: 8)
                    .position(x: preX, y: geo.size.height / 2)

                // 餐前数值
                Text(String(format: "%.1f", preValue))
                    .font(.system(size: 8).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .position(x: preX, y: geo.size.height / 2 - 10)

                // 餐后点
                Circle()
                    .fill(spike > 3.0 ? Color("GlucoseVeryHigh") : Color("GlucoseHigh"))
                    .frame(width: 8, height: 8)
                    .position(x: postX, y: geo.size.height / 2)

                // 餐后数值
                Text(String(format: "%.1f", postValue))
                    .font(.system(size: 8).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .position(x: postX, y: geo.size.height / 2 - 10)
            }
        }
        .frame(height: 28)
    }

    // MARK: - 各场景血糖分布图（箱线图）

    private var tagDistributionChart: some View {
        struct TagStats: Identifiable {
            let id: String
            let name: String
            let icon: String
            let median: Double
            let q1: Double
            let q3: Double
            let min: Double
            let max: Double
            let count: Int
            let rangeLow: Double
            let rangeHigh: Double
        }

        let byTag = Dictionary(grouping: rangeRecords) { $0.sceneTagId }

        var stats: [TagStats] = []
        for (tagId, tagRecords) in byTag {
            // 至少需要3条记录才能生成有意义的箱线图
            guard tagRecords.count >= 3 else { continue }

            let sorted = tagRecords.map(\.value).sorted()
            let count = sorted.count
            
            // 计算中位数
            let median = count % 2 == 0
                ? (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
                : sorted[count / 2]
            
            // 计算四分位数 (使用更准确的方法)
            let q1Index = max(0, count / 4)
            let q3Index = min(count - 1, count * 3 / 4)
            let q1 = sorted[q1Index]
            let q3 = sorted[q3Index]

            let tag = settings.sceneTag(for: tagId)
            let range = settings.thresholdRange(for: tagId)

            stats.append(TagStats(
                id: tagId,
                name: tag?.label ?? tagId,
                icon: tag?.icon ?? "clock",
                median: median,
                q1: q1,
                q3: q3,
                min: sorted.first ?? 0,
                max: sorted.last ?? 0,
                count: count,
                rangeLow: range.low,
                rangeHigh: range.high
            ))
        }

        let sortedStats = stats.sorted { $0.median > $1.median }

        let globalMin = max(2.0, (sortedStats.map(\.min).min() ?? 2.0) - 0.5)
        let globalMax = (sortedStats.map(\.max).max() ?? 15.0) + 0.5
        let valueRange = globalMax - globalMin

        return Group {
            if chartViewModel.selectedTagFilter == .all && sortedStats.count >= 2 {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    HStack {
                        Text(String(localized: "statistics.tag_distribution"))
                            .font(.subheadline.weight(.semibold))
                        
                        MetricExplanationView(metricType: .tagDistribution)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: AppConstants.Spacing.lg) {
                        boxPlotLegendItem(label: String(localized: "statistics.box_typical"), style: .median)
                        boxPlotLegendItem(label: String(localized: "statistics.box_range"), style: .box)
                        boxPlotLegendItem(label: String(localized: "statistics.box_target"), style: .target)
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("BrandPrimary").opacity(0.05))
                    )

                    VStack(spacing: AppConstants.Spacing.lg) {
                        ForEach(sortedStats) { tagStat in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: AppConstants.Spacing.sm) {
                                    VStack(spacing: 2) {
                                        Image(systemName: tagStat.icon)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(tagStat.name)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 44)

                                    GeometryReader { geo in
                                        // 该标签自己的目标范围背景
                                        let targetLeft = (tagStat.rangeLow - globalMin) / valueRange * geo.size.width
                                        let targetRight = (tagStat.rangeHigh - globalMin) / valueRange * geo.size.width

                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color("GlucoseNormal").opacity(0.12))
                                            .frame(width: max(0, targetRight - targetLeft), height: 24)
                                            .offset(x: targetLeft)

                                        // 须线（min -> max）
                                        let minX = (tagStat.min - globalMin) / valueRange * geo.size.width
                                        let maxX = (tagStat.max - globalMin) / valueRange * geo.size.width
                                        Path { path in
                                            path.move(to: CGPoint(x: minX, y: geo.size.height / 2))
                                            path.addLine(to: CGPoint(x: maxX, y: geo.size.height / 2))
                                        }
                                        .stroke(Color(.systemGray3), lineWidth: 1)

                                        // 箱体（Q1 -> Q3）
                                        let q1X = (tagStat.q1 - globalMin) / valueRange * geo.size.width
                                        let q3X = (tagStat.q3 - globalMin) / valueRange * geo.size.width
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color("BrandPrimary").opacity(0.3))
                                            .frame(width: max(4, q3X - q1X), height: 16)
                                            .offset(x: q1X, y: (geo.size.height - 16) / 2)

                                        // 中位数线
                                        let medX = (tagStat.median - globalMin) / valueRange * geo.size.width
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(Color("BrandPrimary"))
                                            .frame(width: 3, height: 20)
                                            .offset(x: medX - 1.5, y: (geo.size.height - 20) / 2)
                                    }
                                    .frame(height: 24)

                                    VStack(alignment: .trailing, spacing: 0) {
                                        Text(String(format: "%.1f", tagStat.median))
                                            .font(.caption.monospacedDigit().weight(.medium))
                                            .foregroundStyle(tagStat.median >= tagStat.rangeLow && tagStat.median <= tagStat.rangeHigh ? Color("GlucoseNormal") : Color("GlucoseHigh"))
                                        Text(String(format: String(localized: "statistics.records_count"), tagStat.count))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .frame(width: 45, alignment: .trailing)
                                }
                                
                                // 数值范围说明
                                HStack(spacing: 4) {
                                    Spacer().frame(width: 44)
                                    Text(String(format: String(localized: "statistics.range_label"), String(format: "%.1f", tagStat.min), String(format: "%.1f", tagStat.max), unit.rawValue))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(AppConstants.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.cardBackground)
                )
            }
        }
    }

    private enum BoxPlotLegendStyle { case median, box, target }

    private func boxPlotLegendItem(label: String, style: BoxPlotLegendStyle) -> some View {
        HStack(spacing: 4) {
            switch style {
            case .median:
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color("BrandPrimary"))
                    .frame(width: 2, height: 10)
            case .box:
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("BrandPrimary").opacity(0.25))
                    .frame(width: 12, height: 10)
            case .target:
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("GlucoseNormal").opacity(0.08))
                    .frame(width: 12, height: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color("GlucoseNormal").opacity(0.3), lineWidth: 0.5)
                    )
            }
            Text(label)
        }
    }

    // MARK: - 周对比

    private var weeklyComparison: some View {
        // 根据标签筛选获取本周和上周的记录
        let allThisWeek = allRecords.filter { $0.timestamp >= Date.daysAgo(7) }
        let allLastWeek = allRecords.filter { $0.timestamp >= Date.daysAgo(14) && $0.timestamp < Date.daysAgo(7) }
        
        // 应用标签筛选
        let thisWeek: [GlucoseRecord]
        let lastWeek: [GlucoseRecord]
        
        switch chartViewModel.selectedTagFilter {
        case .all:
            thisWeek = allThisWeek
            lastWeek = allLastWeek
        case .tag(let tagId):
            thisWeek = allThisWeek.filter { $0.sceneTagId == tagId }
            lastWeek = allLastWeek.filter { $0.sceneTagId == tagId }
        case .group(let group):
            thisWeek = allThisWeek.filter { $0.thresholdGroup(from: settings) == group }
            lastWeek = allLastWeek.filter { $0.thresholdGroup(from: settings) == group }
        }

        let thisAvg = GlucoseCalculator.estimatedAverageGlucose(records: thisWeek)
        let lastAvg = GlucoseCalculator.estimatedAverageGlucose(records: lastWeek)

        return Group {
            if let tAvg = thisAvg, let lAvg = lastAvg {
                weeklyComparisonContent(thisAvg: tAvg, lastAvg: lAvg, thisWeek: thisWeek, lastWeek: lastWeek)
            }
        }
    }
    
    private func weeklyComparisonContent(thisAvg: Double, lastAvg: Double, thisWeek: [GlucoseRecord], lastWeek: [GlucoseRecord]) -> some View {
        let thisTIR: Double
        let lastTIR: Double
        
        if chartViewModel.selectedTagFilter == .all {
            thisTIR = GlucoseCalculator.contextualTimeInRange(records: thisWeek, settings: settings)
            lastTIR = GlucoseCalculator.contextualTimeInRange(records: lastWeek, settings: settings)
        } else {
            let range = effectiveRange
            thisTIR = GlucoseCalculator.timeInRange(records: thisWeek, low: range.low, high: range.high)
            lastTIR = GlucoseCalculator.timeInRange(records: lastWeek, low: range.low, high: range.high)
        }
        
        let avgDiff = thisAvg - lastAvg
        let tirDiff = thisTIR - lastTIR
        
        return VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack {
                Text(String(localized: "statistics.weekly"))
                    .font(.subheadline.weight(.semibold))
                
                MetricExplanationView(metricType: .weeklyComparison)
                
                Spacer()
            }

            HStack(spacing: AppConstants.Spacing.md) {
                // 平均血糖对比
                comparisonColumn(
                    title: String(localized: "statistics.average"),
                    thisWeekValue: GlucoseUnitConverter.displayString(mmolLValue: thisAvg, in: unit),
                    lastWeekValue: GlucoseUnitConverter.displayString(mmolLValue: lastAvg, in: unit),
                    thisWeekSubtitle: String(localized: "statistics.this_week"),
                    lastWeekSubtitle: String(localized: "statistics.last_week"),
                    diff: avgDiff,
                    diffUnit: unit.rawValue,
                    isGoodWhenLower: true
                )
                
                Divider()
                    .frame(height: 60)
                
                // 达标率对比
                comparisonColumn(
                    title: String(localized: "statistics.tir_comparison"),
                    thisWeekValue: "\(Int(thisTIR))%",
                    lastWeekValue: "\(Int(lastTIR))%",
                    thisWeekSubtitle: String(localized: "statistics.this_week"),
                    lastWeekSubtitle: String(localized: "statistics.last_week"),
                    diff: tirDiff,
                    diffUnit: "%",
                    isGoodWhenLower: false
                )
            }
        }
        .padding(AppConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }
    
    /// 周对比列
    private func comparisonColumn(
        title: String,
        thisWeekValue: String,
        lastWeekValue: String,
        thisWeekSubtitle: String,
        lastWeekSubtitle: String,
        diff: Double,
        diffUnit: String,
        isGoodWhenLower: Bool
    ) -> some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: AppConstants.Spacing.xs) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(thisWeekValue)
                        .font(.glucoseCallout)
                    Text(thisWeekSubtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(lastWeekValue)
                        .font(.glucoseCallout)
                        .foregroundStyle(.secondary)
                    Text(lastWeekSubtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // 差值显示
            if abs(diff) > 0.01 {
                let isImprovement = isGoodWhenLower ? (diff < 0) : (diff > 0)
                let color = isImprovement ? Color("GlucoseNormal") : Color("GlucoseHigh")
                let prefix = diff > 0 ? "+" : ""
                let arrow = isImprovement ? "arrow.down.right" : "arrow.up.right"
                
                HStack(spacing: 2) {
                    Image(systemName: arrow)
                        .font(.caption2)
                    Text("\(prefix)\(String(format: "%.1f", diff))\(diffUnit)")
                        .font(.caption.monospacedDigit())
                }
                .foregroundStyle(color)
            } else {
                Text(String(localized: "statistics.flat"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }


    // MARK: - 单场景专属：时段分布热力图

    private var singleSceneHourlyDistribution: some View {
        Group {
            if case .tag(let tagId) = chartViewModel.selectedTagFilter {
                if rangeRecords.count < 3 {
                    // 空状态提示
                    emptyStateCard(
                        icon: "clock.badge.questionmark",
                        title: String(format: String(localized: "statistics.hourly_distribution"), settings.displayName(for: tagId)),
                        message: String(localized: "statistics.insufficient_records_hourly")
                    )
                } else {
                    hourlyDistributionContent(for: tagId)
                }
            }
        }
    }
    
    private func emptyStateCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppConstants.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }
    
    private func hourlyDistributionContent(for tagId: String) -> some View {
        let tagName = settings.displayName(for: tagId)
        let calendar = Calendar.current
        
        // 按小时分组统计
        var hourlyStats: [Int: (count: Int, avg: Double, values: [Double])] = [:]
        for record in rangeRecords {
            let hour = calendar.component(.hour, from: record.timestamp)
            if var stat = hourlyStats[hour] {
                stat.values.append(record.value)
                stat.count += 1
                stat.avg = stat.values.reduce(0, +) / Double(stat.values.count)
                hourlyStats[hour] = stat
            } else {
                hourlyStats[hour] = (count: 1, avg: record.value, values: [record.value])
            }
        }
        
        let range = settings.thresholdRange(for: tagId)
        
        return VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack {
                Text(String(format: String(localized: "statistics.hourly_distribution"), tagName))
                    .font(.subheadline.weight(.semibold))
                
                MetricExplanationView(metricType: .hourlyDistribution)
                
                Spacer()
            }
            
            // 24小时热力图
            VStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { col in
                            let hour = row * 4 + col
                            let stat = hourlyStats[hour]
                            let hasData = stat != nil
                            let avg = stat?.avg ?? 0
                            let level: GlucoseLevel = hasData ? GlucoseLevel.from(value: avg, low: range.low, high: range.high) : .normal
                            
                            VStack(spacing: 2) {
                                Text(String(format: "%02d", hour))
                                    .font(.system(size: 10).monospacedDigit())
                                    .foregroundStyle(hasData ? .primary : .tertiary)
                                
                                if hasData {
                                    Text(String(format: "%.1f", avg))
                                        .font(.system(size: 9).monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    Text("(\(stat!.count))")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.tertiary)
                                } else {
                                    Text("-")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(hasData ? Color.forGlucoseLevel(level).opacity(0.15) : Color(.systemGray6))
                            )
                        }
                    }
                }
            }
        }
        .padding(AppConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }

    // MARK: - 单场景专属：日期趋势表格

    private var singleSceneDailyTrend: some View {
        Group {
            if case .tag(let tagId) = chartViewModel.selectedTagFilter {
                if rangeRecords.count < 3 {
                    // 空状态提示
                    emptyStateCard(
                        icon: "calendar.badge.clock",
                        title: String(format: String(localized: "statistics.daily_trend"), settings.displayName(for: tagId)),
                        message: String(localized: "statistics.insufficient_records_daily")
                    )
                } else {
                    dailyTrendContent(for: tagId)
                }
            }
        }
    }
    
    private func dailyTrendContent(for tagId: String) -> some View {
        let tagName = settings.displayName(for: tagId)
        let calendar = Calendar.current
        let range = settings.thresholdRange(for: tagId)
        
        // 按日期分组统计
        var dailyStats: [(date: Date, avg: Double, min: Double, max: Double, count: Int, inRange: Int)] = []
        let grouped = Dictionary(grouping: rangeRecords) { record in
            calendar.startOfDay(for: record.timestamp)
        }
        
        for (date, records) in grouped.sorted(by: { $0.key > $1.key }).prefix(14) {
            let values = records.map(\.value)
            let avg = values.reduce(0, +) / Double(values.count)
            let min = values.min() ?? 0
            let max = values.max() ?? 0
            let inRangeCount = records.filter { $0.value >= range.low && $0.value <= range.high }.count
            dailyStats.append((date: date, avg: avg, min: min, max: max, count: values.count, inRange: inRangeCount))
        }
        
        return VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack {
                Text(String(format: String(localized: "statistics.daily_trend"), tagName))
                    .font(.subheadline.weight(.semibold))
                
                MetricExplanationView(metricType: .dailyTrend)
                
                Spacer()
            }
            
            VStack(spacing: 6) {
                // 表头
                HStack(spacing: 8) {
                    Text(String(localized: "statistics.date"))
                        .font(.caption.weight(.medium))
                        .frame(width: 60, alignment: .leading)
                    Text(String(localized: "statistics.avg"))
                        .font(.caption.weight(.medium))
                        .frame(width: 40, alignment: .trailing)
                    Text(String(localized: "statistics.range"))
                        .font(.caption.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(String(localized: "statistics.count"))
                        .font(.caption.weight(.medium))
                        .frame(width: 30, alignment: .trailing)
                    Text(String(localized: "statistics.in_range_short"))
                        .font(.caption.weight(.medium))
                        .frame(width: 40, alignment: .trailing)
                }
                .foregroundStyle(.secondary)
                
                Divider()
                
                // 数据行
                ForEach(dailyStats, id: \.date) { stat in
                    HStack(spacing: 8) {
                        Text(stat.date.shortDateString)
                            .font(.caption2)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(String(format: "%.1f", stat.avg))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(stat.avg >= range.low && stat.avg <= range.high ? Color("GlucoseNormal") : Color("GlucoseHigh"))
                            .frame(width: 40, alignment: .trailing)
                        
                        Text("\(String(format: "%.1f", stat.min)) - \(String(format: "%.1f", stat.max))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("\(stat.count)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                            .frame(width: 30, alignment: .trailing)
                        
                        let tir = Double(stat.inRange) / Double(stat.count) * 100
                        Text("\(Int(tir))%")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(tir >= AppConstants.tirGoodThreshold ? Color("GlucoseNormal") : Color("GlucoseHigh"))
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(AppConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                .fill(Color.cardBackground)
        )
    }

    // MARK: - 计算属性

    private var averageGlucose: String {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) else { return "--" }
        return GlucoseUnitConverter.displayString(mmolLValue: avg, in: unit)
    }

    private var eA1CValue: String {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) else { return "--" }
        let a1c = GlucoseCalculator.estimatedA1C(averageGlucoseMmolL: avg)
        return String(format: "%.1f%%", a1c)
    }

    private var eA1CColor: Color? {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) else { return nil }
        let a1c = GlucoseCalculator.estimatedA1C(averageGlucoseMmolL: avg)
        if a1c < 7.0 {
            return Color("GlucoseNormal")
        } else if a1c < 8.0 {
            return Color("GlucoseHigh")
        } else {
            return Color("GlucoseVeryHigh")
        }
    }

    private var minMaxValue: String {
        guard !rangeRecords.isEmpty else { return "--" }
        let values = rangeRecords.map(\.value)
        guard let minVal = values.min(), let maxVal = values.max() else { return "--" }
        let minStr = GlucoseUnitConverter.displayString(mmolLValue: minVal, in: unit)
        let maxStr = GlucoseUnitConverter.displayString(mmolLValue: maxVal, in: unit)
        return "\(maxStr) / \(minStr)"
    }

    private var averageColor: Color? {
        guard let avg = GlucoseCalculator.estimatedAverageGlucose(records: rangeRecords) else { return nil }
        let range = effectiveRange
        let level: GlucoseLevel
        switch avg {
        case ..<range.low:                    level = .low
        case range.low..<range.high:          level = .normal
        case range.high..<(range.high + 3.0): level = .high
        default:                              level = .veryHigh
        }
        return Color.forGlucoseLevel(level)
    }

    private var cvValue: String {
        guard let cv = GlucoseCalculator.coefficientOfVariation(records: rangeRecords) else { return "--" }
        return String(format: "%.1f%%", cv)
    }

    private var cvColor: Color? {
        guard let cv = GlucoseCalculator.coefficientOfVariation(records: rangeRecords) else { return nil }
        return cv < AppConstants.cvStableThreshold ? Color("GlucoseNormal") : Color("GlucoseHigh")
    }

    private var tirValue: String {
        guard !rangeRecords.isEmpty else { return "--" }
        let tir: Double
        if chartViewModel.selectedTagFilter == .all {
            tir = GlucoseCalculator.contextualTimeInRange(records: rangeRecords, settings: settings)
        } else {
            let range = effectiveRange
            tir = GlucoseCalculator.timeInRange(records: rangeRecords, low: range.low, high: range.high)
        }
        return "\(Int(tir))%"
    }

    private var tirColor: Color? {
        guard !rangeRecords.isEmpty else { return nil }
        let tir: Double
        if chartViewModel.selectedTagFilter == .all {
            tir = GlucoseCalculator.contextualTimeInRange(records: rangeRecords, settings: settings)
        } else {
            let range = effectiveRange
            tir = GlucoseCalculator.timeInRange(records: rangeRecords, low: range.low, high: range.high)
        }
        return tir >= AppConstants.tirGoodThreshold ? Color("GlucoseNormal") : Color("GlucoseHigh")
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [GlucoseRecord.self, UserSettings.self, MedicationRecord.self], inMemory: true)
        .environment(SubscriptionManager())
}
