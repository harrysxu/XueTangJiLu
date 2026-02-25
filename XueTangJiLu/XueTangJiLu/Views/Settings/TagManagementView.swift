//
//  TagManagementView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/15.
//

import SwiftUI
import SwiftData

/// 标签管理页面 - 管理场景标签和备注标签
struct TagManagementView: View {
    @Query private var settingsArray: [UserSettings]
    @State private var showAddAnnotation = false
    @State private var newAnnotationLabel = ""
    @State private var editingAnnotation: AnnotationTag?
    @State private var showAddSceneTag = false
    @State private var editingSceneTag: SceneTag?
    @State private var editingThresholdTag: SceneTag?
    @State private var showAllSceneTags = false  // 是否显示全部场景标签

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var unit: GlucoseUnit { settings.preferredUnit }
    
    /// 显示的场景标签（简化模式只显示推荐标签）
    private var displayedSceneTags: [SceneTag] {
        let allTags = settings.sceneTags.sorted { $0.sortOrder < $1.sortOrder }
        
        // 如果设置为简化模式且未展开，只显示推荐标签
        if !settings.showProfessionalMetrics && !showAllSceneTags {
            return settings.recommendedSceneTags
        }
        
        return allTags
    }

    var body: some View {
        List {
            // Section 1: 场景标签
            sceneTagSection

            // Section 2: 备注标签
            annotationTagSection
        }
        .navigationTitle(String(localized: "tag_management"))
        .sheet(isPresented: $showAddSceneTag) {
            SceneTagEditSheet(settings: settings, existingTag: nil)
        }
        .sheet(item: $editingSceneTag) { tag in
            SceneTagEditSheet(settings: settings, existingTag: tag)
        }
        .sheet(item: $editingThresholdTag) { tag in
            SceneTagThresholdEditSheet(tag: tag, settings: settings, unit: settings.preferredUnit)
        }
        .alert(String(localized: "tag.add_alert_title"), isPresented: $showAddAnnotation) {
            TextField(String(localized: "tag.label_name"), text: $newAnnotationLabel)
            Button(String(localized: "cancel"), role: .cancel) {
                newAnnotationLabel = ""
            }
            Button(String(localized: "add")) {
                addAnnotationTag()
            }
        } message: {
            Text(String(localized: "tag.input_name"))
        }
        .alert(String(localized: "tag.edit_alert_title"), isPresented: .init(
            get: { editingAnnotation != nil },
            set: { if !$0 { editingAnnotation = nil; newAnnotationLabel = "" } }
        )) {
            TextField(String(localized: "tag.label_name"), text: $newAnnotationLabel)
            Button(String(localized: "cancel"), role: .cancel) {
                editingAnnotation = nil
                newAnnotationLabel = ""
            }
            Button(String(localized: "save")) {
                saveEditedAnnotation()
            }
        } message: {
            Text(String(localized: "tag.modify_name"))
        }
    }

    // MARK: - 场景标签管理（SceneTag）

    private var sceneTagSection: some View {
        Section {
            ForEach(displayedSceneTags) { tag in
                sceneTagRow(tag)
            }
            .onMove(perform: moveSceneTags)
            
            // 简化模式下显示"显示全部标签"按钮
            if !settings.showProfessionalMetrics && !showAllSceneTags {
                Button(action: { 
                    withAnimation {
                        showAllSceneTags = true 
                    }
                }) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text(String(localized: "tag.show_all"))
                            .font(.subheadline)
                            .foregroundStyle(Color.brandPrimary)
                        Spacer()
                        Text(String(localized: "tag.hidden_count", defaultValue: "\(settings.sceneTags.count - displayedSceneTags.count) 个隐藏"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if !settings.showProfessionalMetrics && showAllSceneTags {
                // 收起按钮
                Button(action: { 
                    withAnimation {
                        showAllSceneTags = false 
                    }
                }) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "chevron.up.circle.fill")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text(String(localized: "tag.show_recommended"))
                            .font(.subheadline)
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }

            // 添加自定义标签按钮（仅专业模式或已展开时显示）
            if settings.showProfessionalMetrics || showAllSceneTags {
                Button(action: { showAddSceneTag = true }) {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28)
                        Text(String(localized: "tag.add_scene"))
                            .font(.subheadline)
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }
        } header: {
            Text(String(localized: "tag.scene_tags"))
        } footer: {
            let footerText: String
            if !settings.showProfessionalMetrics && !showAllSceneTags {
                footerText = String(localized: "tag.scene_footer_collapsed")
            } else {
                footerText = String(localized: "tag.scene_footer_expanded")
            }
            return Text(footerText)
        }
    }

    private func sceneTagRow(_ tag: SceneTag) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: tag.icon)
                .font(.body)
                .foregroundStyle(tag.isVisible ? Color.brandPrimary : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(tag.label)
                        .font(.subheadline)
                        .foregroundStyle(tag.isVisible ? .primary : .secondary)
                    if !tag.isBuiltIn {
                        Text(String(localized: "tag.custom"))
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                // 阈值范围（可点击编辑）
                thresholdLabel(for: tag)
                    .onTapGesture {
                        editingThresholdTag = tag
                    }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { tag.isVisible },
                set: { newValue in
                    toggleSceneTag(tag, visible: newValue)
                }
            ))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingSceneTag = tag
        }
        .swipeActions(edge: .trailing) {
            if !tag.isBuiltIn {
                Button(role: .destructive) {
                    deleteSceneTag(tag)
                } label: {
                    Label(String(localized: "tag.delete"), systemImage: "trash")
                }
            }
        }
    }

    // MARK: - 备注标签管理

    private var annotationTagSection: some View {
        Section {
            let tags = settings.annotationTags.sorted { $0.sortOrder < $1.sortOrder }
            ForEach(tags) { tag in
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: tag.icon)
                        .font(.body)
                        .foregroundStyle(tag.isVisible ? Color.brandPrimary : .secondary)
                        .frame(width: 28)

                    Text(tag.label)
                        .font(.subheadline)
                        .foregroundStyle(tag.isVisible ? .primary : .secondary)

                    if tag.isBuiltIn {
                        Text(String(localized: "tag.builtin"))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.quaternarySystemFill))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { tag.isVisible },
                        set: { newValue in
                            toggleAnnotationTag(tag, visible: newValue)
                        }
                    ))
                }
                .swipeActions(edge: .trailing) {
                    if !tag.isBuiltIn {
                        Button(role: .destructive) {
                            deleteAnnotationTag(tag)
                        } label: {
                            Label(String(localized: "tag.delete"), systemImage: "trash")
                        }
                    }
                    Button {
                        editingAnnotation = tag
                        newAnnotationLabel = tag.label
                    } label: {
                        Label(String(localized: "tag.edit"), systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
            .onMove(perform: moveAnnotationTags)

            Button(action: { showAddAnnotation = true }) {
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 28)
                    Text(String(localized: "tag.add_annotation"))
                        .font(.subheadline)
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        } header: {
            Text(String(localized: "tag.annotation_tags"))
        } footer: {
            Text(String(localized: "tag.annotation_footer"))
        }
    }

    // MARK: - 场景标签操作

    private func toggleSceneTag(_ tag: SceneTag, visible: Bool) {
        var tags = settings.sceneTags
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[index].isVisible = visible
            settings.sceneTags = tags
        }
    }

    private func moveSceneTags(from source: IndexSet, to destination: Int) {
        var tags = settings.sceneTags.sorted { $0.sortOrder < $1.sortOrder }
        tags.move(fromOffsets: source, toOffset: destination)
        for (i, _) in tags.enumerated() {
            tags[i].sortOrder = i
        }
        settings.sceneTags = tags
    }

    private func deleteSceneTag(_ tag: SceneTag) {
        guard !tag.isBuiltIn else { return }
        var tags = settings.sceneTags
        tags.removeAll { $0.id == tag.id }
        settings.sceneTags = tags
    }

    // MARK: - 阈值标签辅助

    private func thresholdLabel(for tag: SceneTag) -> some View {
        let range = settings.thresholdRange(for: tag.id)
        let unit = settings.preferredUnit
        let lowStr = GlucoseUnitConverter.displayString(mmolLValue: range.low, in: unit)
        let highStr = GlucoseUnitConverter.displayString(mmolLValue: range.high, in: unit)

        return Text("\(lowStr) - \(highStr) \(unit.rawValue)")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }

    // MARK: - 备注标签操作

    private func toggleAnnotationTag(_ tag: AnnotationTag, visible: Bool) {
        var tags = settings.annotationTags
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[index].isVisible = visible
            settings.annotationTags = tags
        }
    }

    private func moveAnnotationTags(from source: IndexSet, to destination: Int) {
        var tags = settings.annotationTags.sorted { $0.sortOrder < $1.sortOrder }
        tags.move(fromOffsets: source, toOffset: destination)
        for (i, _) in tags.enumerated() {
            tags[i].sortOrder = i
        }
        settings.annotationTags = tags
    }

    private func addAnnotationTag() {
        guard !newAnnotationLabel.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var tags = settings.annotationTags
        let maxOrder = tags.map(\.sortOrder).max() ?? -1
        let newTag = AnnotationTag(
            id: UUID().uuidString,
            label: newAnnotationLabel.trimmingCharacters(in: .whitespaces),
            icon: "tag.fill",
            isBuiltIn: false,
            isVisible: true,
            sortOrder: maxOrder + 1
        )
        tags.append(newTag)
        settings.annotationTags = tags
        newAnnotationLabel = ""
    }

    private func deleteAnnotationTag(_ tag: AnnotationTag) {
        var tags = settings.annotationTags
        tags.removeAll { $0.id == tag.id }
        settings.annotationTags = tags
    }

    private func saveEditedAnnotation() {
        guard let editing = editingAnnotation,
              !newAnnotationLabel.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var tags = settings.annotationTags
        if let index = tags.firstIndex(where: { $0.id == editing.id }) {
            tags[index].label = newAnnotationLabel.trimmingCharacters(in: .whitespaces)
            settings.annotationTags = tags
        }
        editingAnnotation = nil
        newAnnotationLabel = ""
    }
}

// MARK: - 场景标签编辑 Sheet（新增 / 编辑）

struct SceneTagEditSheet: View {
    let settings: UserSettings
    let existingTag: SceneTag?
    @Environment(\.dismiss) private var dismiss

    @State private var label: String
    @State private var icon: String
    @State private var selectedGroup: ThresholdGroup

    private var isEditing: Bool { existingTag != nil }

    private static let availableIcons = [
        "sunrise", "sun.max", "sunset", "moon.zzz", "bed.double", "clock",
        "cup.and.saucer", "fork.knife", "leaf", "figure.run", "heart",
        "star", "bolt", "drop", "pills", "cross.case",
        "moon.stars", "cloud.sun", "snowflake", "flame",
        "tag.fill", "bookmark.fill", "bell.fill", "flag.fill"
    ]

    init(settings: UserSettings, existingTag: SceneTag?) {
        self.settings = settings
        self.existingTag = existingTag
        _label = State(initialValue: existingTag?.label ?? "")
        _icon = State(initialValue: existingTag?.icon ?? "tag.fill")
        _selectedGroup = State(initialValue: existingTag?.thresholdGroup ?? .fasting)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "tag.tag_info")) {
                    TextField(String(localized: "tag.label_name"), text: $label)

                    Picker(String(localized: "tag.select_group"), selection: $selectedGroup) {
                        ForEach(ThresholdGroup.allCases) { group in
                            Text(group.localizedDisplayName).tag(group)
                        }
                    }
                }

                Section(String(localized: "tag.select_icon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(Self.availableIcons, id: \.self) { iconName in
                            Button {
                                icon = iconName
                            } label: {
                                Image(systemName: iconName)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(icon == iconName ? .white : Color.brandPrimary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(icon == iconName ? Color.brandPrimary : Color.brandPrimary.opacity(0.1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, AppConstants.Spacing.sm)
                }

                if isEditing, let tag = existingTag, tag.isBuiltIn {
                    Section {
                        Button(String(localized: "tag.restore_default")) {
                            if let context = MealContext(rawValue: tag.id) {
                                label = context.defaultDisplayName
                            }
                        }
                        .foregroundStyle(.orange)
                    }
                }

                Section {
                    Text(selectedGroup.localizedAdaRecommendation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(String(localized: "tag.group_description"))
                } footer: {
                    Text(String(localized: "tag.group_footer"))
                }
            }
            .navigationTitle(isEditing ? String(localized: "tag.edit_scene") : String(localized: "tag.add_scene_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) {
                        saveTag()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveTag() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)
        guard !trimmedLabel.isEmpty else { return }

        var tags = settings.sceneTags

        if let existing = existingTag {
            // 编辑已有标签
            if let index = tags.firstIndex(where: { $0.id == existing.id }) {
                tags[index].label = trimmedLabel
                tags[index].icon = icon
                tags[index].thresholdGroupRawValue = selectedGroup.rawValue
            }
        } else {
            // 新增自定义标签
            let maxOrder = tags.map(\.sortOrder).max() ?? -1
            let newTag = SceneTag(
                id: UUID().uuidString,
                label: trimmedLabel,
                icon: icon,
                thresholdGroupRawValue: selectedGroup.rawValue,
                isBuiltIn: false,
                isVisible: true,
                sortOrder: maxOrder + 1
            )
            tags.append(newTag)
        }

        settings.sceneTags = tags
    }
}

// MARK: - 场景标签阈值编辑 Sheet

struct SceneTagThresholdEditSheet: View {
    let tag: SceneTag
    let settings: UserSettings
    let unit: GlucoseUnit
    @Environment(\.dismiss) private var dismiss

    @State private var lowValue: Double
    @State private var highValue: Double

    init(tag: SceneTag, settings: UserSettings, unit: GlucoseUnit) {
        self.tag = tag
        self.settings = settings
        self.unit = unit

        let range = settings.thresholdRange(for: tag.id)
        _lowValue = State(initialValue: range.low)
        _highValue = State(initialValue: range.high)
    }

    var body: some View {
        NavigationStack {
            Form {
                // 标签信息
                Section {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: tag.icon)
                            .font(.title3)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 32)
                        Text(tag.label)
                            .font(.headline)
                    }
                }

                // 阈值范围
                Section(String(localized: "tag.target_range")) {
                    HStack {
                        Text(String(localized: "tag.lower_limit"))
                        Spacer()
                        Text(GlucoseUnitConverter.displayString(mmolLValue: lowValue, in: unit))
                            .foregroundStyle(.secondary)
                            .font(.body.monospacedDigit())
                        Stepper("", value: $lowValue, in: 2.0...6.0, step: 0.1)
                            .labelsHidden()
                    }
                    HStack {
                        Text(String(localized: "tag.upper_limit"))
                        Spacer()
                        Text(GlucoseUnitConverter.displayString(mmolLValue: highValue, in: unit))
                            .foregroundStyle(.secondary)
                            .font(.body.monospacedDigit())
                        Stepper("", value: $highValue, in: 4.0...15.0, step: 0.1)
                            .labelsHidden()
                    }
                }

                // ADA 参考
                Section {
                    Text(tag.thresholdGroup.localizedAdaRecommendation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(String(localized: "tag.reference_advice"))
                }
            }
            .navigationTitle(String(localized: "tag.edit_threshold"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) {
                        settings.setThreshold(for: tag.id, low: lowValue, high: highValue)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    NavigationStack {
        TagManagementView()
    }
    .modelContainer(for: [UserSettings.self], inMemory: true)
}
