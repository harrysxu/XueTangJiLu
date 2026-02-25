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
                healthKitStep.tag(3)
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
                Text(String(localized: "onboarding.welcome"))
                    .font(.title)
                    .fontWeight(.bold)

                Text(String(localized: "onboarding.slogan"))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Text(String(localized: "onboarding.disclaimer"))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.Spacing.section)

            Spacer()

            onboardingButton(String(localized: "onboarding.start")) {
                viewModel.nextStep()
            }
        }
    }

    // MARK: - 第 2 步：单位选择

    private var unitSelectionStep: some View {
        VStack(spacing: AppConstants.Spacing.xl) {
            Spacer()

            VStack(spacing: AppConstants.Spacing.sm) {
                Text(String(localized: "onboarding.unit.title"))
                    .font(.title2)
                    .fontWeight(.bold)

                Text(String(localized: "onboarding.unit.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: AppConstants.Spacing.md) {
                unitCard(unit: .mmolL, subtitle: String(localized: "onboarding.unit.mmol_region"))
                unitCard(unit: .mgdL, subtitle: String(localized: "onboarding.unit.mgdl_region"))
            }
            .padding(.horizontal, AppConstants.Spacing.xxl)

            Spacer()

            onboardingButton(String(localized: "onboarding.next")) {
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
                Text(String(localized: "onboarding.edu.title"))
                    .font(.title2)
                    .fontWeight(.bold)

                Text(String(localized: "onboarding.edu.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
                educationItem(
                    icon: "target",
                    title: String(localized: "onboarding.edu.tir_title"),
                    description: String(localized: "onboarding.edu.tir_desc")
                )

                educationItem(
                    icon: "waveform.path.ecg",
                    title: String(localized: "onboarding.edu.cv_title"),
                    description: String(localized: "onboarding.edu.cv_desc")
                )
            }
            .padding(AppConstants.Spacing.lg)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
            .padding(.horizontal, AppConstants.Spacing.xxl)

            Spacer()

            onboardingButton(String(localized: "onboarding.next")) {
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

    // MARK: - 第 4 步：HealthKit 授权

    private var healthKitStep: some View {
        VStack(spacing: AppConstants.Spacing.xl) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            VStack(spacing: AppConstants.Spacing.sm) {
                Text(String(localized: "onboarding.health.title"))
                    .font(.title2)
                    .fontWeight(.bold)

                Text(String(localized: "onboarding.health.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                benefitRow(icon: "checkmark.shield", text: String(localized: "onboarding.health.benefit1"))
                benefitRow(icon: "arrow.triangle.2.circlepath", text: String(localized: "onboarding.health.benefit2"))
                benefitRow(icon: "heart.text.square", text: String(localized: "onboarding.health.benefit3"))
            }
            .padding(AppConstants.Spacing.lg)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
            .padding(.horizontal, AppConstants.Spacing.xxl)

            Spacer()

            // 连接按钮
            onboardingButton(String(localized: "onboarding.health.connect")) {
                Task {
                    try? await healthKitManager.requestAuthorization()
                    completeOnboarding(healthKitEnabled: true)
                }
            }

            // 跳过按钮
            Button(action: {
                completeOnboarding(healthKitEnabled: false)
            }) {
                Text(String(localized: "onboarding.health.skip"))
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
        targetSettings.hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
        .environment(HealthKitManager())
}
