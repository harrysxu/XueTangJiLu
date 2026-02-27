//
//  CloudKitInitializer.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import CloudKit
import Foundation

/// CloudKit 初始化助手
/// 用于手动初始化 CloudKit Zone，解决 "Server Rejected Request" 错误
class CloudKitInitializer {
    private let container: CKContainer
    private let containerIdentifier: String
    
    init(containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
        self.container = CKContainer(identifier: containerIdentifier)
    }
    
    /// 手动初始化 CloudKit
    /// - Returns: 初始化是否成功
    @discardableResult
    func initializeCloudKit() async -> Bool {
        #if DEBUG
        print("🔧 [CloudKit] 开始手动初始化...")
        print("   Container ID: \(containerIdentifier)")
        #endif
        
        do {
            // 1. 检查账户状态
            let accountStatus = try await container.accountStatus()
            print("   - 账户状态: \(accountStatusDescription(accountStatus))")
            
            guard accountStatus == .available else {
                print("   ❌ iCloud 账户不可用")
                return false
            }
            
            // 2. 获取用户记录 ID
            do {
                let userRecordID = try await container.userRecordID()
                print("   ✓ 用户记录 ID: \(userRecordID.recordName)")
            } catch {
                print("   ⚠️ 无法获取用户记录 ID: \(error.localizedDescription)")
            }
            
            // 3. 获取私有数据库
            let database = container.privateCloudDatabase
            
            // 4. 检查并创建默认 Zone
            let success = await checkAndCreateDefaultZone(database: database)
            
            if success {
                print("✅ [CloudKit] 初始化完成")
            } else {
                print("⚠️ [CloudKit] 初始化未完全成功")
            }
            
            return success
            
        } catch {
            print("❌ [CloudKit] 初始化失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 检查并创建默认 Zone
    private func checkAndCreateDefaultZone(database: CKDatabase) async -> Bool {
        // SwiftData/CoreData 使用的 Zone 名称
        let zoneName = "com.apple.coredata.cloudkit.zone"
        let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
        
        print("   🔍 检查 Zone: \(zoneName)")
        
        do {
            // 尝试获取 Zone
            let zone = try await database.recordZone(for: zoneID)
            print("   ✓ Zone 已存在: \(zone.zoneID.zoneName)")
            return true
            
        } catch let error as CKError {
            
            if error.code == .zoneNotFound || error.code == .unknownItem {
                // Zone 不存在，尝试创建
                print("   ℹ️ Zone 不存在，尝试创建...")
                return await createZone(database: database, zoneID: zoneID)
                
            } else if error.code == .serverRejectedRequest {
                // 服务器拒绝请求
                print("")
                print("   ❌ 服务器拒绝请求 (CKError \(error.code.rawValue))")
                print("")
                print("   🔴 这是 Apple Developer 配置问题！")
                print("")
                print("   📋 必须检查以下配置（约需 10 分钟）:")
                print("")
                print("   第 1 步：检查 App ID 配置")
                print("      1. 访问 https://developer.apple.com")
                print("      2. Certificates, Identifiers & Profiles → Identifiers")
                print("      3. 找到你的 App ID → 点击进入")
                print("      4. 检查 'iCloud' 能力是否已勾选")
                print("      5. 点击 'CloudKit' 旁边的 'Edit' 或 'Configure'")
                print("      6. ✅ 确认列表中包含: \(containerIdentifier)")
                print("      7. ❌ 如果不存在 → 点击 'Add Container' → 输入 Container ID")
                print("      8. 检查 'App Groups' 也已正确配置")
                print("      9. 点击 'Save' 保存所有更改")
                print("")
                print("   第 2 步：初始化 CloudKit Dashboard")
                print("      1. 访问 https://icloud.developer.apple.com/dashboard/")
                print("      2. 选择 Container: \(containerIdentifier)")
                print("      3. 切换到 'Production' 环境（不要选 Development！）")
                print("      4. 查看 Schema 和 Data 确认可以访问")
                print("")
                print("   第 3 步：重新安装应用")
                print("      1. 完全删除设备上的应用")
                print("      2. Xcode: Product → Clean Build Folder (⇧⌘K)")
                print("      3. 重新构建并安装")
                print("")
                print("   📚 详细指南：查看项目中的 FINAL_FIX_GUIDE.md")
                print("")
                return false
                
            } else {
                print("   ⚠️ 检查 Zone 时出错: \(error.localizedDescription)")
                print("   错误代码: \(error.code.rawValue)")
                return false
            }
            
        } catch {
            print("   ⚠️ 检查 Zone 时出现未知错误: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 创建 Zone
    private func createZone(database: CKDatabase, zoneID: CKRecordZone.ID) async -> Bool {
        let zone = CKRecordZone(zoneID: zoneID)
        
        do {
            let createdZone = try await database.save(zone)
            print("   ✅ 成功创建 Zone: \(createdZone.zoneID.zoneName)")
            return true
            
        } catch let error as CKError {
            
            if error.code == .serverRejectedRequest {
                print("   ❌ 服务器拒绝创建 Zone (CKError \(error.code.rawValue))")
                print("   ")
                print("   🔴 这是 Apple Developer 配置问题！")
                print("   ")
                print("   📋 请按以下步骤检查:")
                print("      1. 访问 https://developer.apple.com")
                print("      2. Certificates, Identifiers & Profiles → Identifiers")
                print("      3. 找到你的 App ID")
                print("      4. 检查 iCloud 能力是否启用")
                print("      5. 检查 CloudKit Containers 列表")
                print("      6. 确认包含: \(containerIdentifier)")
                print("      ")
                print("   然后访问 https://icloud.developer.apple.com/dashboard/")
                print("      1. 选择 Container: \(containerIdentifier)")
                print("      2. 切换到 Production 环境")
                print("      3. 检查 Schema 是否已部署")
                print("   ")
                
            } else if error.code == .zoneNotFound {
                print("   ⚠️ Zone 创建后无法找到（这很罕见）")
                
            } else {
                print("   ❌ 创建 Zone 失败: \(error.localizedDescription)")
                print("   错误代码: \(error.code.rawValue)")
            }
            
            return false
            
        } catch {
            print("   ❌ 创建 Zone 时出现未知错误: \(error.localizedDescription)")
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
