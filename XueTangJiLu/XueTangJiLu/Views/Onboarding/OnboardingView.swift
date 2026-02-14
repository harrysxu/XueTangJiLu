//
//  OnboardingView.swift
//  XueTangJiLu
//
//  Created by 徐晓龙 on 2026/2/12.
//

import SwiftUI
import SwiftData

/// 首次启动引导页
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKitManager
    @Query private var settingsArray: [UserSettings]
    @State private var viewModel = OnboardingViewModel()

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    var body: some View {
        VStack {
            // 进度指示器
            HStack(spacing: AppConstants.Spacing.sm) {
                ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= viewModel.currentStep ? Color.brandPrimary : Color(.systemGray4))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, AppConstants.Spacing.xxl)
            .padding(.top, AppConstants.Spacing.lg)

            Spacer()

            // 步骤内容
            TabView(selection: $viewModel.currentStep) {
                welcomeStep.tag(0)
                unitSelectionStep.tag(1)
                educationStep.tag(2)
                goalSettingStep.tag(3)
                healthKitStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth, value: viewModel.currentStep)

            Spacer()
        }
    }

    // MARK: - 第 1 步：欢迎

    private var welcomeStep: some View {
        VStack(spacing: AppConstants.Spacing.xl) {
            Spacer()

            Image(systemName: "drop.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.brandPrimary)

            VStack(spacing: AppConstants.Spacing.sm) {
                Text("学糖记录")
                    .font(.title)
                    .fontWeight(.bold)

                Text("让控糖回归简单")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Text("本应用仅用于个人健康数据记录，不提供任何医疗诊断或治疗建议。请在做出任何医疗决定前咨询您的医生。")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.Spacing.section)

            Spacer()

            onboardingButton("开始使用") {
                viewModel.nextStep()
            }
        }
    }

    // MARK: - 第 2 步：单位选择

    private var unitSelectionStep: some View {
        VStack(spacing: AppConstants.Spacing.xl) {
            Spacer()

            VStack(spacing: AppConstants.Spacing.sm) {
                Text("选择您的血糖单位")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("可随时在设置中更改")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: AppConstants.Spacing.md) {
                unitCard(unit: .mmolL, subtitle: "中国/欧洲常用")
                unitCard(unit: .mgdL, subtitle: "美国/日本常用")
            }
            .padding(.horizontal, AppConstants.Spacing.xxl)

            Spacer()

            onboardingButton("下一步") {
                viewModel.nextStep()
            }
        }
    }

    // MARK: - 第 3 步：科普教育

    private var educationStep: some View {
        VStack(spacing: AppConstants.Spacing.xl) {
            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.brandPrimary)

            VStack(spacing: AppConstants.Spacing.sm) {
                Text("了解关键指标")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("帮助您更好地理解血糖数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
                educationItem(
                    icon: "target",
                    title: "TIR（达标率）",
                    description: "血糖在目标范围内的时间比例。目标 > 70% 为良好。"
                )

                educationItem(
                    icon: "percent",
                    title: "A1C（糖化血红蛋白）",
                    description: "反映 2-3 个月平均血糖水平。一般目标 < 7%。"
                )

                educationItem(
                    icon: "waveform.path.ecg",
                    title: "CV%（波动系数）",
                    description: "衡量血糖波动程度。< 36% 认为稳定。"
                )
            }
            .padding(AppConstants.Spacing.lg)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
            .padding(.horizontal, AppConstants.Spacing.xxl)

            Spacer()

            onboardingButton("下一步") {
                viewModel.nextStep()
            }
        }
    }

    private func educationItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 第 4 步：目标设置

    private var goalSettingStep: some View {
        VStack(spacing: AppConstants.Spacing.xl) {
            Spacer()

            Image(systemName: "flag.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color("GlucoseNormal"))

            VStack(spacing: AppConstants.Spacing.sm) {
                Text("设定您的控糖目标")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("可随时在设置中调整")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: AppConstants.Spacing.lg) {
                // A1C 目标
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    Text("A1C 目标")
                        .font(.subheadline.weight(.medium))

                    HStack {
                        Text(String(format: "%.1f%%", viewModel.targetA1C))
                            .font(.glucoseHero)
                            .foregroundStyle(Color.brandPrimary)

                        Spacer()

                        Stepper("", value: $viewModel.targetA1C, in: 5.0...10.0, step: 0.5)
                            .labelsHidden()
                    }

                    Text("一般建议 < 7.0%，具体请遵医嘱")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                // 每日记录目标
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    Text("每日记录目标")
                        .font(.subheadline.weight(.medium))

                    HStack {
                        Text("\(viewModel.dailyRecordGoal) 次")
                            .font(.glucoseHero)
                            .foregroundStyle(Color.brandPrimary)

                        Spacer()

                        Stepper("", value: $viewModel.dailyRecordGoal, in: 1...10)
                            .labelsHidden()
                    }

                    Text("建议每天至少测 4 次（三餐前 + 睡前）")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(AppConstants.Spacing.lg)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
            .padding(.horizontal, AppConstants.Spacing.xxl)

            Spacer()

            onboardingButton("下一步") {
                viewModel.nextStep()
            }
        }
    }

    // MARK: - 第 5 步：HealthKit 授权

    private var healthKitStep: some View {
        VStack(spacing: AppConstants.Spacing.xl) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            VStack(spacing: AppConstants.Spacing.sm) {
                Text("健康数据同步")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("连接 Apple Health 后，\n您的血糖数据将自动备份到系统\u{201C}健康\u{201D}应用中。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                benefitRow(icon: "checkmark.shield", text: "数据备份更安全")
                benefitRow(icon: "arrow.triangle.2.circlepath", text: "删除 App 数据不丢失")
                benefitRow(icon: "heart.text.square", text: "与其他健康数据联动查看")
            }
            .padding(AppConstants.Spacing.lg)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
            .padding(.horizontal, AppConstants.Spacing.xxl)

            Spacer()

            // 连接按钮
            onboardingButton("连接 Health") {
                Task {
                    try? await healthKitManager.requestAuthorization()
                    completeOnboarding(healthKitEnabled: true)
                }
            }

            // 跳过按钮
            Button(action: {
                completeOnboarding(healthKitEnabled: false)
            }) {
                Text("稍后再说")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, AppConstants.Spacing.section)
        }
    }

    // MARK: - 公共组件

    private func onboardingButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.Size.saveButtonHeight)
                .background(Color.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
        }
        .padding(.horizontal, AppConstants.Spacing.xxl)
        .padding(.bottom, title == "连接 Health" ? 0 : AppConstants.Spacing.section)
    }

    private func unitCard(unit: GlucoseUnit, subtitle: String) -> some View {
        Button(action: {
            HapticManager.selection()
            viewModel.selectedUnit = unit
        }) {
            VStack(spacing: AppConstants.Spacing.xs) {
                Text(unit.rawValue)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppConstants.Spacing.xl)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .stroke(
                        viewModel.selectedUnit == unit ? Color.brandPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - 完成引导

    private func completeOnboarding(healthKitEnabled: Bool) {
        HapticManager.success()

        let targetSettings: UserSettings
        if let existing = settingsArray.first {
            targetSettings = existing
        } else {
            targetSettings = UserSettings()
            modelContext.insert(targetSettings)
        }

        targetSettings.preferredUnit = viewModel.selectedUnit
        targetSettings.healthKitSyncEnabled = healthKitEnabled
        targetSettings.targetA1C = viewModel.targetA1C
        targetSettings.dailyRecordGoal = viewModel.dailyRecordGoal
        targetSettings.hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
        .environment(HealthKitManager())
}
