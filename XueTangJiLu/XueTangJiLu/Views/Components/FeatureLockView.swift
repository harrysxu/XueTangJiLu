//
//  FeatureLockView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import SwiftUI

/// 功能锁定提示视图
struct FeatureLockView: View {
    let feature: Feature
    let message: String?
    @State private var showPaywall = false
    
    init(feature: Feature, message: String? = nil) {
        self.feature = feature
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text(feature.localizedName)
                .font(.headline)
            
            Text(message ?? FeatureManager.unlockPrompt(for: feature))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text(String(localized: "feature.button.unlock"))
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.sm)
                .background(.brandPrimary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .padding(AppConstants.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

/// 功能锁定横幅（小尺寸）
struct FeatureLockBanner: View {
    let feature: Feature
    @State private var showPaywall = false
    
    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "lock.fill")
                    .font(.caption)
                
                Text(FeatureManager.unlockPrompt(for: feature))
                    .font(.caption)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                    Text(String(localized: "feature.button.unlock_short"))
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(.horizontal, AppConstants.Spacing.md)
            .padding(.vertical, AppConstants.Spacing.sm)
            .background(Color.yellow.opacity(0.15))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.input))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

/// 功能锁定遮罩（覆盖在被锁定的内容上）
struct FeatureLockOverlay: View {
    let feature: Feature
    @State private var showPaywall = false
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
            
            // 锁定提示
            VStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                
                Text(feature.localizedName)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text(String(localized: "feature.button.unlock"))
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, AppConstants.Spacing.lg)
                    .padding(.vertical, AppConstants.Spacing.md)
                    .background(.white)
                    .foregroundStyle(.brandPrimary)
                    .clipShape(Capsule())
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

/// 功能锁定警告框
struct FeatureLockAlert: ViewModifier {
    @Binding var isPresented: Bool
    let feature: Feature
    @State private var showPaywall = false
    
    func body(content: Content) -> some View {
        content
            .alert(String(localized: "feature.alert.title"), isPresented: $isPresented) {
                Button(String(localized: "feature.button.unlock")) {
                    showPaywall = true
                }
                Button(String(localized: "common.cancel"), role: .cancel) {}
            } message: {
                Text(FeatureManager.unlockPrompt(for: feature))
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
    }
}

extension View {
    /// 添加功能锁定警告框
    func featureLockAlert(isPresented: Binding<Bool>, feature: Feature) -> some View {
        modifier(FeatureLockAlert(isPresented: isPresented, feature: feature))
    }
}

#Preview("Feature Lock View") {
    VStack(spacing: 20) {
        FeatureLockView(feature: .iCloudSync)
        
        FeatureLockBanner(feature: .pdfExport)
    }
    .padding()
    .background(Color.pageBackground)
}

#Preview("Feature Lock Overlay") {
    ZStack {
        // 模拟被锁定的内容
        VStack {
            Text("这是被锁定的高级功能")
            Text("需要升级才能查看")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cardBackground)
        
        FeatureLockOverlay(feature: .advancedCharts)
    }
}
