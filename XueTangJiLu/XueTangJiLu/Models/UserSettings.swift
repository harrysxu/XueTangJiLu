//
//  UserSettings.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import Foundation
import SwiftData

// MARK: - 提醒配置模型（需要对 Widget 可见，因此定义在此）

/// 单条提醒配置
struct ReminderConfig: Identifiable, Codable, Equatable {
    let id: String          // UUID 字符串
    var sceneTagId: String  // 引用 SceneTag.id
    var hour: Int           // 0-23
    var minute: Int         // 0-59
    var isEnabled: Bool

    /// 格式化的时间显示
    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }
    
    /// 从场景标签列表获取标签名称
    func label(from sceneTags: [SceneTag]) -> String {
        sceneTags.first(where: { $0.id == sceneTagId })?.label ?? String(localized: "meal.other")
    }
    
    /// 生成本地化的默认提醒配置列表
    static func localizedDefaults() -> [ReminderConfig] {
        return [
            ReminderConfig(id: UUID().uuidString, sceneTagId: MealContext.beforeBreakfast.rawValue, hour: 7, minute: 0, isEnabled: false),
            ReminderConfig(id: UUID().uuidString, sceneTagId: MealContext.afterBreakfast.rawValue, hour: 9, minute: 30, isEnabled: false),
            ReminderConfig(id: UUID().uuidString, sceneTagId: MealContext.beforeLunch.rawValue, hour: 11, minute: 30, isEnabled: false),
            ReminderConfig(id: UUID().uuidString, sceneTagId: MealContext.afterLunch.rawValue, hour: 14, minute: 0, isEnabled: false),
            ReminderConfig(id: UUID().uuidString, sceneTagId: MealContext.beforeDinner.rawValue, hour: 17, minute: 30, isEnabled: false),
            ReminderConfig(id: UUID().uuidString, sceneTagId: MealContext.afterDinner.rawValue, hour: 20, minute: 0, isEnabled: false),
            ReminderConfig(id: UUID().uuidString, sceneTagId: MealContext.bedtime.rawValue, hour: 22, minute: 0, isEnabled: false),
        ]
    }
}

// MARK: - 阈值配置

/// 阈值范围
struct ThresholdRange: Codable, Equatable, Sendable {
    var low: Double
    var high: Double
}

/// 统一阈值配置：分组默认 + 单标签覆盖
struct ThresholdConfig: Codable, Equatable, Sendable {
    /// 分组默认阈值 [ThresholdGroup.rawValue: ThresholdRange]
    var groupDefaults: [String: ThresholdRange]

    /// 单标签自定义覆盖 [SceneTag.id: ThresholdRange]
    /// 存在则优先使用，不存在则回退到所属分组默认
    var tagOverrides: [String: ThresholdRange]

    /// 默认配置
    static let defaults = ThresholdConfig(
        groupDefaults: [
            ThresholdGroup.fasting.rawValue:       ThresholdRange(low: 4.4, high: 7.2),
            ThresholdGroup.postprandial.rawValue:  ThresholdRange(low: 4.4, high: 10.0),
            ThresholdGroup.bedtime.rawValue:        ThresholdRange(low: 4.4, high: 7.8),
        ],
        tagOverrides: [:]
    )

    /// 获取分组默认阈值
    func groupRange(for group: ThresholdGroup) -> ThresholdRange {
        groupDefaults[group.rawValue] ?? ThresholdConfig.defaultGroupRange(for: group)
    }

    /// 硬编码默认值（兜底）
    private static func defaultGroupRange(for group: ThresholdGroup) -> ThresholdRange {
        switch group {
        case .fasting:       return ThresholdRange(low: 4.4, high: 7.2)
        case .postprandial:  return ThresholdRange(low: 4.4, high: 10.0)
        case .bedtime:       return ThresholdRange(low: 4.4, high: 7.8)
        }
    }
}

// MARK: - 场景标签模型

/// 场景标签（统一管理内置和自定义标签）
struct SceneTag: Identifiable, Codable, Equatable, Hashable {
    let id: String                     // 内置: MealContext.rawValue; 自定义: UUID
    var label: String                  // 显示名称
    var icon: String                   // SF Symbol 名称
    var thresholdGroupRawValue: String // 所属阈值分组 rawValue
    var isBuiltIn: Bool               // 是否内置标签
    var isVisible: Bool               // 是否可见
    var sortOrder: Int                // 排序序号
    
    // 提醒配置（默认关闭）
    var reminderEnabled: Bool = false  // 是否启用提醒
    var reminderHour: Int = 12         // 提醒小时 (0-23)
    var reminderMinute: Int = 0        // 提醒分钟 (0-59)

    /// 所属阈值分组
    var thresholdGroup: ThresholdGroup {
        ThresholdGroup(rawValue: thresholdGroupRawValue) ?? .fasting
    }

    /// 对应的内置 MealContext（仅内置标签有值，用于 HealthKit 映射）
    var builtInMealContext: MealContext? {
        guard isBuiltIn else { return nil }
        return MealContext(rawValue: id)
    }
    
    /// 格式化的提醒时间显示
    var reminderTimeString: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    /// 从 MealContext 创建内置标签
    static func fromMealContext(_ context: MealContext, label: String? = nil, isVisible: Bool = true, sortOrder: Int) -> SceneTag {
        SceneTag(
            id: context.rawValue,
            label: label ?? context.defaultDisplayName,
            icon: context.iconName,
            thresholdGroupRawValue: context.thresholdGroup.rawValue,
            isBuiltIn: true,
            isVisible: isVisible,
            sortOrder: sortOrder
        )
    }

    /// 生成默认内置标签列表
    static var builtInDefaults: [SceneTag] {
        MealContext.allCases.enumerated().map { index, context in
            SceneTag.fromMealContext(context, sortOrder: index)
        }
    }
    
    /// 生成本地化的默认内置标签列表
    static func localizedBuiltInDefaults() -> [SceneTag] {
        MealContext.allCases.enumerated().map { index, context in
            SceneTag(
                id: context.rawValue,
                label: context.localizedDisplayName,
                icon: context.iconName,
                thresholdGroupRawValue: context.thresholdGroup.rawValue,
                isBuiltIn: true,
                isVisible: true,
                sortOrder: index
            )
        }
    }
}

// MARK: - 自定义备注标签

/// 备注标签（运动后、压力大等附加标记）
struct AnnotationTag: Identifiable, Codable, Equatable {
    let id: String
    var label: String
    var icon: String        // SF Symbol name
    var isBuiltIn: Bool
    var isVisible: Bool
    var sortOrder: Int

    /// 内置默认备注标签
    static let defaults: [AnnotationTag] = [
        AnnotationTag(id: "exercise",  label: "运动后", icon: "figure.run",        isBuiltIn: true, isVisible: true, sortOrder: 0),
        AnnotationTag(id: "stress",    label: "压力大", icon: "brain.head.profile", isBuiltIn: true, isVisible: true, sortOrder: 1),
        AnnotationTag(id: "sick",      label: "生病",   icon: "medical.thermometer", isBuiltIn: true, isVisible: true, sortOrder: 2),
        AnnotationTag(id: "travel",    label: "旅行",   icon: "airplane",           isBuiltIn: true, isVisible: true, sortOrder: 3),
        AnnotationTag(id: "snack",     label: "加餐",   icon: "cup.and.saucer",     isBuiltIn: true, isVisible: true, sortOrder: 4),
        AnnotationTag(id: "alcohol",   label: "饮酒",   icon: "wineglass",          isBuiltIn: true, isVisible: true, sortOrder: 5),
    ]
    
    /// 生成本地化的默认备注标签
    static func localizedDefaults() -> [AnnotationTag] {
        return [
            AnnotationTag(id: "exercise",  label: String(localized: "note.exercise"), icon: "figure.run",        isBuiltIn: true, isVisible: true, sortOrder: 0),
            AnnotationTag(id: "stress",    label: String(localized: "note.stress"),   icon: "brain.head.profile", isBuiltIn: true, isVisible: true, sortOrder: 1),
            AnnotationTag(id: "sick",      label: String(localized: "note.sick"),     icon: "medical.thermometer", isBuiltIn: true, isVisible: true, sortOrder: 2),
            AnnotationTag(id: "travel",    label: String(localized: "note.travel"),   icon: "airplane",           isBuiltIn: true, isVisible: true, sortOrder: 3),
            AnnotationTag(id: "snack",     label: String(localized: "note.snack"),    icon: "cup.and.saucer",     isBuiltIn: true, isVisible: true, sortOrder: 4),
            AnnotationTag(id: "alcohol",   label: String(localized: "note.alcohol"),  icon: "wineglass",          isBuiltIn: true, isVisible: true, sortOrder: 5),
        ]
    }
}

// MARK: - 显示模式

/// 显示模式（大众化改造核心配置）
enum DisplayMode: String, Codable, CaseIterable {
    case simplified = "simple"      // 大众用户：隐藏专业指标和复杂图表
    case professional = "professional"   // 高级用户：显示所有功能
    
    /// 显示名称（保持兼容性）
    var displayName: String {
        switch self {
        case .simplified:   return "简化模式"
        case .professional: return "专业模式"
        }
    }
    
    /// 本地化的显示名称
    var localizedDisplayName: String {
        switch self {
        case .simplified:   return String(localized: "display_mode.simple")
        case .professional: return String(localized: "display_mode.professional")
        }
    }
    
    var description: String {
        switch self {
        case .simplified:
            return "适合日常记录使用，隐藏部分专业指标"
        case .professional:
            return "显示完整的统计分析功能，适合深度分析"
        }
    }
    
    /// 本地化的描述
    var localizedDescription: String {
        switch self {
        case .simplified:
            return String(localized: "display_mode.simple.desc")
        case .professional:
            return String(localized: "display_mode.professional.desc")
        }
    }
}

/// 用户设置模型
@Model
final class UserSettings {

    /// 首选血糖单位
    var preferredUnitRawValue: String = GlucoseUnit.systemDefault.rawValue

    /// 是否已完成引导
    var hasCompletedOnboarding: Bool = false

    /// 是否启用 HealthKit 同步
    var healthKitSyncEnabled: Bool = false

    // MARK: - 提醒设置

    /// 提醒配置 JSON 数据
    var remindersData: Data?

    /// 久未记录提醒间隔（小时），0 表示关闭
    var inactivityReminderHours: Int = 0

    // MARK: - 标签配置

    /// 自定义备注标签 JSON
    var annotationTagsData: Data?

    /// 阈值配置 JSON（分组默认 + 单标签覆盖）
    var thresholdConfigData: Data?

    /// 场景标签列表 JSON
    var sceneTagsData: Data?
    
    // MARK: - 大众化配置
    
    /// 是否已显示免责声明
    var hasSeenDisclaimer: Bool = false
    
    /// 显示模式（简化/专业）
    var displayModeRawValue: String = DisplayMode.simplified.rawValue

    // MARK: - 计算属性

    var preferredUnit: GlucoseUnit {
        get { GlucoseUnit(rawValue: preferredUnitRawValue) ?? .mmolL }
        set { preferredUnitRawValue = newValue.rawValue }
    }
    
    /// 显示模式
    var displayMode: DisplayMode {
        get { DisplayMode(rawValue: displayModeRawValue) ?? .simplified }
        set { displayModeRawValue = newValue.rawValue }
    }
    
    /// 是否显示专业指标（根据显示模式判断）
    var showProfessionalMetrics: Bool {
        displayMode == .professional
    }

    /// 获取提醒配置列表
    var reminderConfigs: [ReminderConfig] {
        guard let data = remindersData,
              let decoded = try? JSONDecoder().decode([ReminderConfig].self, from: data) else {
            return ReminderConfig.localizedDefaults()
        }
        return decoded
    }

    // MARK: - 场景标签

    /// 获取场景标签列表
    var sceneTags: [SceneTag] {
        get {
            if let data = sceneTagsData,
               let decoded = try? JSONDecoder().decode([SceneTag].self, from: data),
               !decoded.isEmpty {
                return decoded
            }
            return SceneTag.builtInDefaults
        }
        set {
            sceneTagsData = try? JSONEncoder().encode(newValue)
        }
    }

    /// 获取可见的场景标签（按 sortOrder 排列）
    var visibleSceneTags: [SceneTag] {
        sceneTags.filter(\.isVisible).sorted { $0.sortOrder < $1.sortOrder }
    }

    /// 根据 tag ID 查找场景标签
    func sceneTag(for tagId: String) -> SceneTag? {
        sceneTags.first { $0.id == tagId }
    }

    /// 根据 tag ID 获取显示名称
    func displayName(for tagId: String) -> String {
        sceneTag(for: tagId)?.label ?? String(localized: "meal.other")
    }

    /// 根据 tag ID 获取图标名称
    func iconName(for tagId: String) -> String {
        sceneTag(for: tagId)?.icon ?? "clock"
    }

    /// 根据 tag ID 获取所属 ThresholdGroup
    func thresholdGroup(for tagId: String) -> ThresholdGroup {
        sceneTag(for: tagId)?.thresholdGroup ?? .fasting
    }

    /// 根据 tag ID 获取阈值范围（优先查 tagOverrides，回退到分组硬编码默认值兜底）
    func thresholdRange(for tagId: String) -> (low: Double, high: Double) {
        let config = thresholdConfig
        if let tagRange = config.tagOverrides[tagId] {
            return (tagRange.low, tagRange.high)
        }
        // 兜底：按 ThresholdGroup 硬编码默认值（向后兼容未迁移的标签）
        let group = thresholdGroup(for: tagId)
        let r = config.groupRange(for: group)
        return (r.low, r.high)
    }

    /// 设置某个标签的阈值
    func setThreshold(for tagId: String, low: Double, high: Double) {
        var config = thresholdConfig
        config.tagOverrides[tagId] = ThresholdRange(low: low, high: high)
        thresholdConfig = config
    }

    // MARK: - 备注标签

    /// 获取备注标签列表
    var annotationTags: [AnnotationTag] {
        get {
            guard let data = annotationTagsData,
                  let decoded = try? JSONDecoder().decode([AnnotationTag].self, from: data) else {
                return AnnotationTag.defaults
            }
            return decoded
        }
        set {
            annotationTagsData = try? JSONEncoder().encode(newValue)
        }
    }

    /// 获取可见的备注标签（按排序顺序）
    var visibleAnnotationTags: [AnnotationTag] {
        annotationTags.filter(\.isVisible).sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // MARK: - 本地化默认标签初始化
    
    /// 初始化本地化的默认标签（仅在首次启动时调用一次）
    func initializeLocalizedDefaultTagsIfNeeded() {
        // 如果已经有持久化的标签数据，则不需要初始化
        if sceneTagsData != nil && annotationTagsData != nil {
            return
        }
        
        // 生成并持久化本地化的场景标签
        if sceneTagsData == nil {
            let localizedSceneTags = SceneTag.localizedBuiltInDefaults()
            sceneTagsData = try? JSONEncoder().encode(localizedSceneTags)
        }
        
        // 生成并持久化本地化的备注标签
        if annotationTagsData == nil {
            let localizedAnnotationTags = AnnotationTag.localizedDefaults()
            annotationTagsData = try? JSONEncoder().encode(localizedAnnotationTags)
        }
    }

    // MARK: - 阈值配置

    /// 阈值配置（分组默认 + 单标签覆盖）
    nonisolated var thresholdConfig: ThresholdConfig {
        get {
            MainActor.assumeIsolated {
                guard let data = thresholdConfigData,
                      let decoded = try? JSONDecoder().decode(ThresholdConfig.self, from: data) else {
                    return ThresholdConfig.defaults
                }
                return decoded
            }
        }
        set {
            MainActor.assumeIsolated {
                thresholdConfigData = try? JSONEncoder().encode(newValue)
            }
        }
    }

    /// 所有标签阈值的包络范围（取所有标签 low 最小值和 high 最大值）
    /// 用于"全部"视图下趋势图的目标区间显示
    var thresholdEnvelope: (low: Double, high: Double) {
        let allRanges = sceneTags.map { thresholdRange(for: $0.id) }
        let low = allRanges.map(\.low).min() ?? 4.4
        let high = allRanges.map(\.high).max() ?? 10.0
        return (low, high)
    }

    // MARK: - iCloud 同步去重
    
    /// 最后修改时间（用于冲突解决）
    var lastModified: Date = Date.now
    
    /// 设备标识符（用于多设备冲突检测）
    var deviceIdentifier: String?

    var customizationScore: Int {
        var score = 0
        if hasCompletedOnboarding { score += 10 }
        if remindersData != nil { score += 5 }
        if sceneTagsData != nil { score += 4 }
        if annotationTagsData != nil { score += 3 }
        if thresholdConfigData != nil { score += 3 }
        if healthKitSyncEnabled { score += 2 }
        // 比较 thresholdConfigData 是否存在且不是默认值
        if let data = thresholdConfigData,
           let config = try? JSONDecoder().decode(ThresholdConfig.self, from: data),
           config != ThresholdConfig.defaults {
            score += 3
        }
        return score
    }
    
    nonisolated func customizationScoreValue() -> Int {
        var score = 0
        if hasCompletedOnboarding { score += 10 }
        if remindersData != nil { score += 5 }
        if sceneTagsData != nil { score += 4 }
        if annotationTagsData != nil { score += 3 }
        if thresholdConfigData != nil { score += 3 }
        if healthKitSyncEnabled { score += 2 }
        return score
    }

    func mergeNonDefaults(from other: UserSettings) {
        // 引导完成状态：任一设备完成即视为完成
        if other.hasCompletedOnboarding { hasCompletedOnboarding = true }
        
        // HealthKit 同步：任一设备启用即启用
        if other.healthKitSyncEnabled { healthKitSyncEnabled = true }
        
        // 提醒配置：优先使用最新修改的
        if remindersData == nil && other.remindersData != nil {
            remindersData = other.remindersData
        } else if remindersData != nil && other.remindersData != nil {
            // 如果两边都有，使用最后修改时间判断
            if other.lastModified > lastModified {
                remindersData = other.remindersData
            }
        }
        // 场景标签：合并去重
        if sceneTagsData == nil && other.sceneTagsData != nil {
            sceneTagsData = other.sceneTagsData
        } else if sceneTagsData != nil && other.sceneTagsData != nil {
            let myTags = sceneTags
            let otherTags = other.sceneTags
            let myIds = Set(myTags.map(\.id))
            let newTags = otherTags.filter { !myIds.contains($0.id) }
            if !newTags.isEmpty {
                var merged = myTags
                let maxOrder = merged.map(\.sortOrder).max() ?? -1
                for (i, tag) in newTags.enumerated() {
                    var t = tag
                    t.sortOrder = maxOrder + 1 + i
                    merged.append(t)
                }
                sceneTags = merged
            }
        }
        // 备注标签：合并去重
        if annotationTagsData == nil && other.annotationTagsData != nil {
            annotationTagsData = other.annotationTagsData
        } else if annotationTagsData != nil && other.annotationTagsData != nil {
            let myTags = annotationTags
            let otherTags = other.annotationTags
            let myIds = Set(myTags.map(\.id))
            let newTags = otherTags.filter { !myIds.contains($0.id) }
            if !newTags.isEmpty {
                var merged = myTags
                let maxOrder = merged.map(\.sortOrder).max() ?? -1
                for (i, tag) in newTags.enumerated() {
                    var t = tag
                    t.sortOrder = maxOrder + 1 + i
                    merged.append(t)
                }
                annotationTags = merged
            }
        }
        // 阈值配置
        if thresholdConfigData == nil && other.thresholdConfigData != nil {
            thresholdConfigData = other.thresholdConfigData
        } else if thresholdConfigData != nil && other.thresholdConfigData != nil {
            var myConfig = thresholdConfig
            let otherConfig = other.thresholdConfig
            for (key, value) in otherConfig.tagOverrides where myConfig.tagOverrides[key] == nil {
                myConfig.tagOverrides[key] = value
            }
            thresholdConfig = myConfig
        }
    }

    static func deduplicate(_ allSettings: [UserSettings]) -> (keep: UserSettings, toDelete: [UserSettings]) {
        guard allSettings.count > 1 else {
            return (allSettings.first ?? UserSettings(), [])
        }
        
        // 先按自定义分数排序，分数相同则按最后修改时间
        let sorted = allSettings.sorted { s1, s2 in
            if s1.customizationScore != s2.customizationScore {
                return s1.customizationScore > s2.customizationScore
            }
            return s1.lastModified > s2.lastModified
        }
        
        let keep = sorted[0]
        let duplicates = Array(sorted.dropFirst())
        
        // 合并其他设置的数据
        for dup in duplicates {
            keep.mergeNonDefaults(from: dup)
        }
        
        // 更新最后修改时间
        keep.lastModified = Date.now
        
        return (keep, duplicates)
    }

    init() {}
}

// MARK: - UserSettings 扩展

extension UserSettings {
    
    /// 推荐的核心场景标签（固定5个，仅返回可见标签）
    var recommendedSceneTags: [SceneTag] {
        let allTags = sceneTags
        return allTags.filter { tag in
            tag.isVisible &&
            ["fasting", "breakfast_after", "lunch_after", 
             "dinner_after", "bedtime"].contains(tag.id)
        }.sorted { $0.sortOrder < $1.sortOrder }
    }
}
