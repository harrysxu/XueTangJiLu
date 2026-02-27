//
//  StoreManager.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import Foundation
import StoreKit
import SwiftUI

/// StoreKit 2 购买管理器
@MainActor
@Observable
class StoreManager {
    
    // MARK: - Properties
    
    /// 可购买的产品列表
    var products: [Product] = []
    
    /// 已购买的产品 ID 集合
    var purchasedProductIDs: Set<String> = []
    
    /// 当前订阅的最新过期日期
    var latestExpirationDate: Date?
    
    /// 加载状态
    var isLoading = false
    
    /// 购买状态
    var isPurchasing = false
    
    /// 错误信息
    var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// 产品 ID 列表
    private let productIDs = IAPProduct.allCases.map { $0.rawValue }
    
    /// 交易监听任务
    @ObservationIgnored
    private var transactionListener: Task<Void, Error>?
    
    // MARK: - Initialization
    
    init() {
        // 启动交易监听器
        transactionListener = listenForTransactions()
        
        // 启动时加载产品和更新购买状态
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// 加载产品信息
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 从 App Store 获取产品信息
            let storeProducts = try await Product.products(for: productIDs)
            
            // 按照自定义顺序排序：年订阅 -> 季订阅 -> 月订阅 -> 买断
            products = storeProducts.sorted { product1, product2 in
                guard let iap1 = IAPProduct(rawValue: product1.id),
                      let iap2 = IAPProduct(rawValue: product2.id) else {
                    return false
                }
                
                let order: [IAPProduct] = [.yearly, .quarterly, .monthly, .lifetime]
                guard let index1 = order.firstIndex(of: iap1),
                      let index2 = order.firstIndex(of: iap2) else {
                    return false
                }
                
                return index1 < index2
            }
            
            #if DEBUG
            print("✅ 成功加载 \(products.count) 个产品")
            for product in products {
                print("  - \(product.displayName): \(product.displayPrice)")
            }
            #endif
            
        } catch {
            errorMessage = String(localized: "store.error.load_failed")
            #if DEBUG
            print("❌ 加载产品失败: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    /// 购买产品
    func purchase(_ product: Product) async throws {
        isPurchasing = true
        errorMessage = nil
        
        defer {
            isPurchasing = false
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 验证交易
                let transaction = try checkVerified(verification)
                
                // 更新购买状态
                await updatePurchasedProducts()
                
                // 完成交易
                await transaction.finish()
                
                #if DEBUG
                print("✅ 购买成功: \(product.displayName)")
                #endif
                
            case .userCancelled:
                #if DEBUG
                print("⚠️ 用户取消购买")
                #endif
                
            case .pending:
                #if DEBUG
                print("⏳ 购买待处理（需要家长批准）")
                #endif
                errorMessage = String(localized: "store.error.pending")
                
            @unknown default:
                break
            }
            
        } catch StoreError.failedVerification {
            errorMessage = String(localized: "store.error.verification_failed")
            throw StoreError.failedVerification
        } catch {
            errorMessage = String(localized: "store.error.purchase_failed")
            #if DEBUG
            print("❌ 购买失败: \(error)")
            #endif
            throw error
        }
    }
    
    /// 恢复购买
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            
            #if DEBUG
            print("✅ 成功恢复购买")
            #endif
            
        } catch {
            errorMessage = String(localized: "store.error.restore_failed")
            #if DEBUG
            print("❌ 恢复购买失败: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    /// 检查是否已购买某个产品
    func isPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    /// 检查用户是否是付费用户
    func isPremiumUser() -> Bool {
        return !purchasedProductIDs.isEmpty
    }
    
    /// 获取当前订阅类型
    func currentSubscriptionType() -> SubscriptionType? {
        if purchasedProductIDs.contains(IAPProduct.lifetime.rawValue) {
            return .lifetime
        } else if purchasedProductIDs.contains(IAPProduct.yearly.rawValue) {
            return .yearly
        } else if purchasedProductIDs.contains(IAPProduct.quarterly.rawValue) {
            return .quarterly
        } else if purchasedProductIDs.contains(IAPProduct.monthly.rawValue) {
            return .monthly
        }
        return nil
    }
    
    // MARK: - Private Methods
    
    /// 更新已购买的产品
    func updatePurchasedProducts() async {
        var newPurchasedIDs = Set<String>()
        var newExpirationDate: Date?
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                newPurchasedIDs.insert(transaction.productID)
                
                if let expiry = transaction.expirationDate {
                    if let current = newExpirationDate {
                        newExpirationDate = max(current, expiry)
                    } else {
                        newExpirationDate = expiry
                    }
                }
            }
        }
        
        purchasedProductIDs = newPurchasedIDs
        latestExpirationDate = newExpirationDate
        
        #if DEBUG
        if !purchasedProductIDs.isEmpty {
            print("📦 已购买产品: \(purchasedProductIDs)")
            if let expiry = latestExpirationDate {
                print("📅 订阅过期时间: \(expiry)")
            }
        }
        #endif
    }
    
    /// 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            // 监听交易更新
            for await result in Transaction.updates {
                guard let self = self else { return }
                
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // 更新购买状态
                    await self.updatePurchasedProducts()
                    
                    // 完成交易
                    await transaction.finish()
                    
                    #if DEBUG
                    print("🔄 交易更新: \(transaction.productID)")
                    #endif
                    
                } catch {
                    #if DEBUG
                    print("❌ 交易验证失败: \(error)")
                    #endif
                }
            }
        }
    }
    
    /// 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Store Errors

enum StoreError: LocalizedError {
    case failedVerification
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return String(localized: "store.error.verification_failed")
        }
    }
}
