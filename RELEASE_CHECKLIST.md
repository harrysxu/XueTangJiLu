# App 发布前检查清单

> 最后更新：2026-02-26

## ✅ 已完成项

### 1. 隐私权限配置
- [x] 添加 `NSPhotoLibraryUsageDescription` 到 Info.plist
- [x] 补充相机权限的英文和繁体中文本地化
- [x] 补充相册权限的三种语言本地化
- **文件位置：**
  - `Info.plist`
  - `Resources/en.lproj/InfoPlist.strings`
  - `Resources/zh-Hans.lproj/InfoPlist.strings`
  - `Resources/zh-Hant.lproj/InfoPlist.strings`

### 2. 本地化字符串完整性
- [x] 添加17个 factory_reset 相关的本地化key到中文文件
- [x] 修复繁体中文中的转义字符问题 (`meal.description_placeholder`)
- [x] 添加 `record.select_scene` 本地化key
- **影响文件：**
  - `Resources/zh-Hans.lproj/Localizable.strings`
  - `Resources/zh-Hant.lproj/Localizable.strings`
  - `Resources/en.lproj/Localizable.strings`

### 3. 代码质量优化
- [x] 实现 RecordInputView 中的"显示所有场景"功能
- [x] 创建 AppLogger 工具类用于日志管理
- [x] 为关键文件的 print 语句添加 `#if DEBUG` 条件编译
- **优化文件：**
  - `CloudKitSyncManager.swift`
  - `XueTangJiLuApp.swift`
  - `DataDeduplicationService.swift`
  - `FactoryResetView.swift`
  - `ContentView.swift`

### 4. Bundle 配置
- [x] 确认保持当前配置（com.xxl.XueTangJiLu）
- [x] 验证 Release 构建配置
  - PRODUCT_BUNDLE_IDENTIFIER: com.xxl.XueTangJiLu
  - MARKETING_VERSION: 1.0
  - CURRENT_PROJECT_VERSION: 1
  - DEVELOPMENT_TEAM: 3LSP26D33P
  - CODE_SIGN_STYLE: Automatic

### 5. 编译验证
- [x] 修复 AppLogger 编译错误
- [x] 成功编译 Debug 版本

## 📋 发布前必做检查

### Apple Developer 后台配置
- [ ] 登录 [Apple Developer](https://developer.apple.com)
- [ ] 验证 iCloud Container: `iCloud.com.xxl.XueTangJiLu` 已创建
- [ ] 验证 App Group: `group.com.xxl.XueTangJiLu` 已创建
- [ ] 确认 App ID 启用以下能力：
  - [ ] iCloud (CloudKit)
  - [ ] App Groups
  - [ ] HealthKit
  - [ ] Push Notifications
- [ ] 创建 Production Provisioning Profile

### CloudKit Dashboard 配置
- [ ] 登录 [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
- [ ] 选择容器: `iCloud.com.xxl.XueTangJiLu`
- [ ] 切换到 **Production** 环境
- [ ] 验证 Schema 已部署
- [ ] 检查 Indexes 配置正确

### App Store Connect 准备
- [ ] 创建 App 记录
- [ ] 准备应用图标 (1024x1024)
- [ ] 准备应用截图（各种设备尺寸）
- [ ] 准备应用描述（中文、英文）
- [ ] 准备关键词
- [ ] 准备隐私政策 URL
- [ ] 填写隐私问卷：
  - [ ] 收集的数据类型
  - [ ] 数据使用目的
  - [ ] HealthKit 数据说明

### 测试清单
- [ ] 在真机上测试（至少2台设备）
- [ ] 测试 iCloud 同步（多设备）
- [ ] 测试 HealthKit 读写权限
- [ ] 测试相机权限请求
- [ ] 测试相册权限请求
- [ ] 测试推送通知
- [ ] 测试 Widget 显示和刷新
- [ ] 测试三种语言切换（英文、简体中文、繁体中文）
- [ ] 测试数据导出（PDF、CSV）
- [ ] 测试工厂重置功能
- [ ] 测试网络中断时的行为
- [ ] 测试低电量模式

### 构建与提交
- [ ] Clean Build Folder (⇧⌘K)
- [ ] 使用 Release 配置 Archive
- [ ] 验证 Archive：
  - [ ] 无编译警告
  - [ ] 正确的版本号
  - [ ] 正确的 Bundle ID
  - [ ] 包含所有必需的 entitlements
- [ ] Validate App（通过 Xcode）
- [ ] Upload to App Store Connect
- [ ] 提交审核

### App Review 准备
- [ ] 准备审核说明（如有测试账号需求）
- [ ] 准备演示视频（可选）
- [ ] 确保免责声明清晰可见
- [ ] 准备回答常见问题

## ⚠️ 重要提醒

### 关于健康数据
- 应用声明为**非医疗设备**
- 数据仅供参考，不构成医疗建议
- 免责声明在首次启动时显示
- 统计页面有免责横幅

### 关于 iCloud 同步
- 中国大陆地区由云上贵州运营
- 需在隐私政策中说明
- 数据存储在用户私有数据库
- 开发者无法访问用户数据

### 关于数据迁移
- 当前版本 1.0 未实现 VersionedSchema
- 未来版本若需修改数据模型，需先实现迁移机制
- 建议在 2.0 版本前增加迁移支持

## 📱 支持的设备和系统

- **最低系统要求：** iOS 17.0
- **Widget 最低要求：** iOS 17.6（建议统一为 17.0）
- **支持设备：** iPhone、iPad
- **语言支持：** 英文、简体中文、繁体中文

## 🔧 已知问题

### 非阻塞性问题
1. Widget 和主应用的最低系统版本不一致（17.6 vs 17.0）
   - 建议：统一为 17.0 以扩大兼容性
2. CloudKitDiagnosticsView 有硬编码文案
   - 影响：仅诊断工具，不影响用户功能
3. QuickTestDataView 生成的测试数据未标记
   - 影响：仅 DEBUG 模式，不在 Release 版本中

## 📞 发布后监控

- [ ] 监控崩溃率（Crashlytics / Xcode Organizer）
- [ ] 监控 App Store 评分和评论
- [ ] 检查 CloudKit 使用量
- [ ] 检查 iCloud 存储使用情况
- [ ] 收集用户反馈

## 📚 相关文档

- [技术架构文档](docs/技术架构文档.md)
- [CloudKit 配置指南](docs/FINAL_FIX_GUIDE.md)（如果存在）
- [图标设计参考](docs/icon/)

---

**最后更新时间：** 2026年2月26日  
**准备人员：** AI Assistant  
**版本：** 1.0
