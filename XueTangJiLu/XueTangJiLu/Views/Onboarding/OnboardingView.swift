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
                welcomeStep
                    .tag(0)
                unitSelectionStep
                    .tag(1)
                healthKitStep
                    .tag(2)
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

            Button(action: {
                HapticManager.light()
                viewModel.nextStep()
            }) {
                Text("开始使用")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConstants.Size.saveButtonHeight)
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
            }
            .padding(.horizontal, AppConstants.Spacing.xxl)
            .padding(.bottom, AppConstants.Spacing.section)
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

            Button(action: {
                HapticManager.light()
                viewModel.nextStep()
            }) {
                Text("下一步")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConstants.Size.saveButtonHeight)
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
            }
            .padding(.horizontal, AppConstants.Spacing.xxl)
            .padding(.bottom, AppConstants.Spacing.section)
        }
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

    // MARK: - 第 3 步：HealthKit 授权

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

                Text("连接 Apple Health 后，\n您的血糖数据将自动备份到系统"健康"应用中。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // 好处列表
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
            Button(action: {
                Task {
                    try? await healthKitManager.requestAuthorization()
                    completeOnboarding(healthKitEnabled: true)
                }
            }) {
                Text("连接 Health")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConstants.Size.saveButtonHeight)
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
            }
            .padding(.horizontal, AppConstants.Spacing.xxl)

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
        targetSettings.hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
        .environment(HealthKitManager())
}
