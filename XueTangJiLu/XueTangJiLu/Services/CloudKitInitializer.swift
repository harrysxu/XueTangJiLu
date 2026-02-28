//
//  CloudKitInitializer.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import CloudKit
import Foundation

/// CloudKit 初始化助手
/// 仅执行诊断检查，Zone 创建交由 CoreData+CloudKit 自动管理
class CloudKitInitializer {
    private let container: CKContainer
    private let containerIdentifier: String
    
    init(containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
        self.container = CKContainer(identifier: containerIdentifier)
    }
    
    /// 诊断 CloudKit 连接状态（只读，不做写入操作）
    /// - Returns: 诊断是否通过
    @discardableResult
    func initializeCloudKit() async -> Bool {
        #if DEBUG
        print("🔧 [CloudKit] 开始诊断检查...")
        print("   Container ID: \(containerIdentifier)")
        #endif
        
        do {
            let accountStatus = try await container.accountStatus()
            print("   - 账户状态: \(accountStatusDescription(accountStatus))")
            
            guard accountStatus == .available else {
                print("   ❌ iCloud 账户不可用")
                return false
            }
            
            do {
                let userRecordID = try await container.userRecordID()
                print("   ✓ 用户记录 ID: \(userRecordID.recordName)")
            } catch {
                print("   ⚠️ 无法获取用户记录 ID: \(error.localizedDescription)")
            }
            
            let database = container.privateCloudDatabase
            let zoneReady = await checkDefaultZone(database: database)
            
            print(zoneReady
                  ? "✅ [CloudKit] 诊断通过"
                  : "ℹ️ [CloudKit] Zone 尚未就绪，CoreData 将自动创建")
            
            return zoneReady
            
        } catch {
            print("❌ [CloudKit] 诊断失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 只读检查默认 Zone 是否存在（不执行创建操作，避免与 CoreData 竞争）
    private func checkDefaultZone(database: CKDatabase) async -> Bool {
        let zoneName = "com.apple.coredata.cloudkit.zone"
        let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
        
        print("   🔍 检查 Zone: \(zoneName)")
        
        do {
            let zone = try await database.recordZone(for: zoneID)
            print("   ✓ Zone 已存在: \(zone.zoneID.zoneName)")
            return true
            
        } catch let error as CKError {
            if error.code == .zoneNotFound || error.code == .unknownItem {
                print("   ℹ️ Zone 尚未创建，CoreData+CloudKit 将在首次同步时自动创建")
            } else if error.code == .serverRejectedRequest {
                print("   ❌ 服务器拒绝请求 (CKError \(error.code.rawValue))")
                print("   🔴 请检查 Apple Developer 配置：")
                print("      1. https://developer.apple.com → Identifiers → 确认 iCloud + CloudKit 已启用")
                print("      2. 确认 Container: \(containerIdentifier) 已关联到 App ID")
                print("      3. https://icloud.developer.apple.com/dashboard/ → 确认 Schema 已部署")
            } else {
                print("   ⚠️ 检查 Zone 时出错: \(error.localizedDescription) (代码: \(error.code.rawValue))")
            }
            return false
            
        } catch {
            print("   ⚠️ 检查 Zone 时出现未知错误: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 账户状态描述
    private func accountStatusDescription(_ status: CKAccountStatus) -> String {
        switch status {
        case .available:
            return "可用 ✓"
        case .noAccount:
            return "未登录 iCloud"
        case .restricted:
            return "受限制（可能是家长控制）"
        case .couldNotDetermine:
            return "无法确定"
        case .temporarilyUnavailable:
            return "暂时不可用"
        @unknown default:
            return "未知状态"
        }
    }
}
