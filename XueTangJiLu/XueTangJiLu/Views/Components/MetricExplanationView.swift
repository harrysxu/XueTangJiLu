//
//  MetricExplanationView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/19.
//

import SwiftUI

/// 指标解释说明组件 - 问号图标按钮
struct MetricExplanationView: View {
    let metricType: MetricType
    @State private var showingDetail = false
    
    private var explanation: MetricExplanation? {
        MetricExplanationLibrary.explanation(for: metricType)
    }
    
    var body: some View {
        if let explanation = explanation {
            Button {
                showingDetail = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingDetail) {
                MetricExplanationDetailView(explanation: explanation)
            }
        }
    }
}

// MARK: - 主题颜色系统

/// 指标类型的视觉主题
struct MetricTheme {
    let primaryColor: Color
    let gradientColors: [Color]
    let iconName: String
    
    static func theme(for metricType: MetricType) -> MetricTheme {
        switch metricType {
        case .averageGlucose:
            return MetricTheme(
                primaryColor: Color("BrandPrimary"),
                gradientColors: [Color("BrandPrimary"), Color("BrandGradientEnd")],
                iconName: "waveform.path.ecg"
            )
        case .estimatedA1C:
            return MetricTheme(
                primaryColor: Color.purple,
                gradientColors: [Color.purple, Color.purple.opacity(0.7)],
                iconName: "chart.line.uptrend.xyaxis"
            )
        case .timeInRange:
            return MetricTheme(
                primaryColor: Color("GlucoseNormal"),
                gradientColors: [Color("GlucoseNormal"), Color.green.opacity(0.7)],
                iconName: "target"
            )
        case .coefficientOfVariation:
            return MetricTheme(
                primaryColor: Color.blue,
                gradientColors: [Color.blue, Color.cyan.opacity(0.7)],
                iconName: "waveform"
            )
        case .timeAboveRange:
            return MetricTheme(
                primaryColor: Color("GlucoseHigh"),
                gradientColors: [Color("GlucoseHigh"), Color.orange.opacity(0.7)],
                iconName: "arrow.up.circle.fill"
            )
        case .timeBelowRange:
            return MetricTheme(
                primaryColor: Color("GlucoseLow"),
                gradientColors: [Color("GlucoseLow"), Color.red.opacity(0.7)],
                iconName: "arrow.down.circle.fill"
            )
        case .glucoseDistribution:
            return MetricTheme(
                primaryColor: Color("BrandPrimary"),
                gradientColors: [Color("BrandPrimary"), Color.purple.opacity(0.7)],
                iconName: "chart.bar.fill"
            )
        case .perTagTIR:
            return MetricTheme(
                primaryColor: Color.teal,
                gradientColors: [Color.teal, Color.cyan.opacity(0.7)],
                iconName: "list.bullet.clipboard"
            )
        case .mealPair:
            return MetricTheme(
                primaryColor: Color.orange,
                gradientColors: [Color.orange, Color.yellow.opacity(0.7)],
                iconName: "fork.knife"
            )
        case .tagDistribution:
            return MetricTheme(
                primaryColor: Color.indigo,
                gradientColors: [Color.indigo, Color.purple.opacity(0.7)],
                iconName: "chart.bar.doc.horizontal"
            )
        case .weeklyComparison:
            return MetricTheme(
                primaryColor: Color.mint,
                gradientColors: [Color.mint, Color.teal.opacity(0.7)],
                iconName: "calendar"
            )
        case .hourlyDistribution:
            return MetricTheme(
                primaryColor: Color.pink,
                gradientColors: [Color.pink, Color.orange.opacity(0.7)],
                iconName: "clock.fill"
            )
        case .dailyTrend:
            return MetricTheme(
                primaryColor: Color.cyan,
                gradientColors: [Color.cyan, Color.blue.opacity(0.7)],
                iconName: "calendar.badge.clock"
            )
        }
    }
}

// MARK: - 详细解释视图

/// 指标详细解释视图
struct MetricExplanationDetailView: View {
    let explanation: MetricExplanation
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimated = false
    
    private var theme: MetricTheme {
        MetricTheme.theme(for: explanation.type)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    
                    VStack(spacing: AppConstants.Spacing.lg) {
                        if let formula = explanation.formula {
                            formulaCard(content: formula)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        
                        if let standard = explanation.referenceStandard {
                            sectionCard(
                                icon: "ruler",
                                iconColor: theme.primaryColor,
                                title: String(localized: "metric.reference_standard"),
                                content: standard
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                        
                        sectionCard(
                            icon: "heart.text.square",
                            iconColor: theme.primaryColor,
                            title: String(localized: "metric.clinical_significance"),
                            content: explanation.clinicalSignificance
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        
                        sectionCard(
                            icon: "lightbulb.fill",
                            iconColor: theme.primaryColor,
                            title: String(localized: "metric.practical_use"),
                            content: explanation.practicalUse
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        
                        if !explanation.references.isEmpty {
                            referencesCard
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        
                        disclaimerCard
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    .padding(AppConstants.Spacing.lg)
                    .padding(.top, AppConstants.Spacing.xxl)
                }
            }
            .background(Color.pageBackground)
            .ignoresSafeArea(edges: .top)
            
            closeButton
                .padding(AppConstants.Spacing.lg)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimated = true
            }
        }
    }
    
    // MARK: - Hero 区域
    
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 220)
            
            VStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: theme.iconName)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
                    .symbolRenderingMode(.hierarchical)
                    .scaleEffect(isAnimated ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isAnimated)
                
                Text(explanation.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(explanation.briefDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppConstants.Spacing.xl)
            }
            .padding(.bottom, AppConstants.Spacing.xl)
            .opacity(isAnimated ? 1.0 : 0)
            .offset(y: isAnimated ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isAnimated)
        }
    }
    
    // MARK: - 公式卡片（特殊样式）
    
    private func formulaCard(content: String) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack(spacing: AppConstants.Spacing.sm) {
                Image(systemName: "function")
                    .font(.title3)
                    .foregroundStyle(theme.primaryColor)
                    .frame(width: 28)
                
                Text("metric.formula", tableName: "Localizable")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Text(content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(AppConstants.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.primaryColor.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(theme.primaryColor.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(18)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(Color.cardBackground)
                
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(theme.primaryColor)
                    .frame(width: 4)
            }
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 内容卡片
    
    private func sectionCard(icon: String, iconColor: Color, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack(spacing: AppConstants.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(Color.cardBackground)
                
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(iconColor)
                    .frame(width: 4)
            }
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 参考文献
    
    private var referencesCard: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack(spacing: AppConstants.Spacing.sm) {
                Image(systemName: "book.closed")
                    .font(.title3)
                    .foregroundStyle(theme.primaryColor)
                    .frame(width: 28)
                
                Text("pdf.references_title", tableName: "Localizable")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                ForEach(Array(explanation.references.enumerated()), id: \.offset) { index, ref in
                    HStack(alignment: .top, spacing: 6) {
                        Text("[\(index + 1)]")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .trailing)
                        
                        Text(ref)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(Color.cardBackground)
                
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .fill(theme.primaryColor)
                    .frame(width: 4)
            }
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 免责声明
    
    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: AppConstants.Spacing.md) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
            
            Text("metric.disclaimer", tableName: "Localizable")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(AppConstants.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 关闭按钮
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(Color.black.opacity(0.2))
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("按钮") {
    VStack(spacing: AppConstants.Spacing.lg) {
        HStack {
            Text("平均血糖")
                .font(.headline)
            MetricExplanationView(metricType: .averageGlucose)
        }
        
        HStack {
            Text("估算糖化")
                .font(.headline)
            MetricExplanationView(metricType: .estimatedA1C)
        }
        
        HStack {
            Text("达标率")
                .font(.headline)
            MetricExplanationView(metricType: .timeInRange)
        }
    }
    .padding()
}

#Preview("平均血糖") {
    MetricExplanationDetailView(
        explanation: MetricExplanationLibrary.explanation(for: .averageGlucose)!
    )
}

#Preview("估算糖化") {
    MetricExplanationDetailView(
        explanation: MetricExplanationLibrary.explanation(for: .estimatedA1C)!
    )
}

#Preview("达标率") {
    MetricExplanationDetailView(
        explanation: MetricExplanationLibrary.explanation(for: .timeInRange)!
    )
}

#Preview("波动系数") {
    MetricExplanationDetailView(
        explanation: MetricExplanationLibrary.explanation(for: .coefficientOfVariation)!
    )
}

#Preview("餐前餐后配对") {
    MetricExplanationDetailView(
        explanation: MetricExplanationLibrary.explanation(for: .mealPair)!
    )
}

#Preview {
    VStack {
        MetricExplanationView(metricType: .estimatedA1C)
        MetricExplanationView(metricType: .coefficientOfVariation)
        MetricExplanationView(metricType: .timeInRange)
    }
    .padding()
}

#Preview("Detail View") {
    MetricExplanationDetailView(
        explanation: MetricExplanationLibrary.explanation(for: .estimatedA1C)!
    )
}
