//
//  PaywallView.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import SwiftUI
import StoreKit

/// 订阅页面 - Paywall
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    
    @State private var selectedProduct: Product?
    @State private var showError = false
    @State private var showRestoreSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    headerSection
                    featuresSection
                    
                    if storeManager.isLoading && storeManager.products.isEmpty {
                        ProgressView()
                            .padding(.vertical, AppConstants.Spacing.xl)
                    } else if storeManager.products.isEmpty {
                        loadFailedSection
                    } else {
                        productsSection
                        purchaseButton
                    }
                    
                    footerSection
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.xl)
            }
            .background(Color.pageBackground)
            .navigationTitle(String(localized: "subscription.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                if storeManager.products.isEmpty {
                    await storeManager.loadProducts()
                }
                autoSelectRecommended()
            }
            .alert(String(localized: "store.error.title"), isPresented: $showError) {
                Button(String(localized: "common.ok"), role: .cancel) {}
            } message: {
                if let error = storeManager.errorMessage {
                    Text(error)
                }
            }
            .alert(String(localized: "store.restore.success"), isPresented: $showRestoreSuccess) {
                Button(String(localized: "common.ok"), role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(String(localized: "store.restore.success.message"))
            }
        }
    }
    
    private func autoSelectRecommended() {
        if selectedProduct == nil {
            selectedProduct = storeManager.products.first {
                IAPProduct(rawValue: $0.id)?.isRecommended == true
            } ?? storeManager.products.first
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.brandPrimary, .brandPrimary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .brandPrimary.opacity(0.3), radius: 10)
            
            Text(String(localized: "subscription.header.title"))
                .font(.title.bold())
            
            Text(String(localized: "subscription.header.subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppConstants.Spacing.lg)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            ForEach(FeatureManager.premiumFeatures(), id: \.self) { feature in
                FeatureRow(feature: feature)
            }
        }
        .padding(AppConstants.Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
    }
    
    // MARK: - Load Failed Section
    
    private var loadFailedSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text(String(localized: "store.error.load_failed"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                Task { await storeManager.loadProducts() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(String(localized: "store.button.retry"))
                }
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.sm)
                .background(.brandPrimary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, AppConstants.Spacing.xl)
    }
    
    // MARK: - Products Section
    
    private var productsSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            ForEach(storeManager.products, id: \.id) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    onTap: {
                        selectedProduct = product
                    }
                )
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            Button {
                Task {
                    await purchaseSelectedProduct()
                }
            } label: {
                HStack {
                    if storeManager.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(String(localized: "subscription.button.subscribe"))
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.Size.saveButtonHeight)
                .background(
                    LinearGradient(
                        colors: [.brandPrimary, .brandPrimary.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.buttonLarge))
            }
            .disabled(selectedProduct == nil || storeManager.isPurchasing)
            .opacity(selectedProduct == nil ? 0.6 : 1.0)
            
            if selectedProduct != nil {
                Text(String(localized: "subscription.button.price_info"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                HStack {
                    if storeManager.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(String(localized: "subscription.button.restore"))
                        .font(.subheadline)
                }
            }
            .disabled(storeManager.isLoading)
            
            HStack(spacing: AppConstants.Spacing.lg) {
                Link(String(localized: "subscription.link.privacy"), destination: URL(string: AppConstants.privacyPolicyURL)!)
                Text("•")
                Link(String(localized: "subscription.link.terms"), destination: URL(string: AppConstants.termsOfServiceURL)!)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, AppConstants.Spacing.md)
    }
    
    // MARK: - Actions
    
    private func purchaseSelectedProduct() async {
        guard let product = selectedProduct else { return }
        
        do {
            try await storeManager.purchase(product)
            
            // 更新订阅状态
            subscriptionManager.updateSubscriptionStatus(from: storeManager)
            
            // 购买成功，关闭页面
            dismiss()
            
        } catch {
            showError = true
        }
    }
    
    private func restorePurchases() async {
        await storeManager.restorePurchases()
        
        // 更新订阅状态
        subscriptionManager.updateSubscriptionStatus(from: storeManager)
        
        if subscriptionManager.isPremiumUser {
            showRestoreSuccess = true
        } else {
            showError = true
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let feature: Feature
    
    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundStyle(.brandPrimary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.localizedName)
                    .font(.subheadline.weight(.medium))
                
                Text(feature.detailedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void
    
    private var iapProduct: IAPProduct? {
        IAPProduct(rawValue: product.id)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // 图标
                Image(systemName: iapProduct?.icon ?? "star")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .brandPrimary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        
                        if iapProduct?.isRecommended == true {
                            Text(String(localized: "subscription.label.recommended"))
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.yellow)
                                .foregroundStyle(.black)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(iapProduct?.durationDescription ?? "")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3.weight(.bold))
                    
                    if let iap = iapProduct, iap.isSubscription {
                        if iap.monthCount > 1 {
                            let monthly = product.price / Decimal(iap.monthCount)
                            let formatted = monthly.formatted(product.priceFormatStyle)
                            Text(String(format: String(localized: "subscription.label.per_month"), formatted))
                                .font(.caption2)
                                .foregroundStyle(isSelected ? .white.opacity(0.8) : .brandPrimary)
                        } else {
                            Text(String(localized: "subscription.label.per_period"))
                                .font(.caption2)
                                .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        }
                    }
                }
            }
            .padding(AppConstants.Spacing.lg)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [.brandPrimary, .brandPrimary.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color.cardBackground, Color.cardBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                    .stroke(isSelected ? Color.clear : Color.brandPrimary.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(
                color: isSelected ? .brandPrimary.opacity(0.4) : .clear,
                radius: 10,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager())
        .environment(SubscriptionManager())
}
