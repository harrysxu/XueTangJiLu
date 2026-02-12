# **极简主义血糖管理 iOS 应用深度研究与产品定义报告**

## **1\. 执行摘要**

在当前的移动健康（mHealth）市场中，糖尿病管理应用领域呈现出功能过度堆砌与用户核心需求脱节的显著矛盾。尽管市面上存在大量集成了饮食追踪、社交网络、辅导算法及电商功能的“超级应用”，但大量用户反馈表明，这些附加功能反而成为了日常管理的负担。本报告针对一位独立开发者提出的“极简控糖 iOS App”构想进行了详尽的可行性分析与产品定义。

分析显示，市场存在一个明确且未被充分满足的细分领域：针对“自我驱动型”糖尿病患者的纯工具类应用。这类用户不需要基础教育或社交激励，而是迫切需要一个能够在 3 秒内完成数据录入、且不仅限于简单记录，更能高效呈现核心趋势的数字化日志。

本报告将从市场痛点分析、产品需求定义（PRD）、独立开发者面临的监管限制（特别是苹果审核指南与中国 PIPL 法规）、技术架构选型以及品牌策略五个维度，提供一份详尽的执行蓝图。报告核心结论指出，通过利用苹果原生 HealthKit 框架作为底层数据库，结合 CloudKit 进行无感同步，独立开发者可以在极低维护成本下构建出符合医疗级审美、具备极高数据隐私安全性的极简应用，从而在红海市场中通过“做减法”通过差异化竞争胜出。

## **2\. 市场现状与需求深度分析**

### **2.1 当前市场的“功能臃肿”与用户疲劳**

糖尿病管理是一项终身任务，患者每天需要多次（部分 1 型患者甚至高达 10 次以上）与管理工具交互。因此，工具的效率直接影响患者的生活质量。然而，目前主流的糖尿病管理应用（如 MySugr, Glucose Buddy, OneTouch Reveal 等）普遍存在“功能臃肿”（Feature Bloat）现象。

根据对 App Store 用户评论及相关学术研究的分析，用户的不满主要集中在以下几个核心维度：

#### **2.1.1 认知负荷与操作延迟**

用户普遍反映，在低血糖或匆忙状态下，试图记录一个简单的血糖数值时，往往需要穿越复杂的层级菜单。许多应用在启动时会弹出“每日提示”、广告或社交动态，导致核心的“记录”功能被边缘化 1。对于每天需要频繁记录的用户而言，每次操作多消耗 5 秒钟，累积的挫败感是巨大的。研究显示，约 42% 的用户投诉与“复杂的数据记录”和“不直观的导航”有关 1。

#### **2.1.2 商业化干扰与广告焦虑**

“免费增值”（Freemium）模式导致大量应用在关键操作路径上插入广告。有用户直言，应用内充斥着长达一分钟的广告不仅令人反感，在需要快速记录健康数据时甚至可能带来危险 2。此外，许多应用试图向用户推销昂贵的辅导服务或测试试纸，这种持续的推销行为破坏了工具的纯粹性，使用户感觉自己是“商品”而非“患者”。

#### **2.1.3 隐私担忧与数据孤岛**

现有的大型平台通常要求用户注册账号，并将数据上传至厂商的私有云端。这引发了双重担忧：一是数据隐私，特别是健康数据被用于精准营销；二是数据主权，用户担心一旦厂商停止服务，自己的长期健康记录将无法导出。相比之下，基于本地存储或 iCloud 的方案更能获得隐私敏感型用户的信任 3。

### **2.2 目标用户画像：极简主义者与数据掌控者**

本应用的目标用户并非初诊的小白用户，而是具有一定病程经验的资深糖友。我们可以将其定义为“数据掌控型”用户（Data Controller）。

| 维度 | 典型特征 | 需求转化 |
| :---- | :---- | :---- |
| **病程阶段** | 确诊 1 年以上，熟悉自身血糖规律 | 不需要基础科普，反感初级教育弹窗 |
| **技术偏好** | iOS 生态深度用户，拥有 Apple Watch | 期望有小组件（Widget）和手表端快速入口 |
| **使用动机** | 监测趋势，向医生展示报表 | 核心需求是“录入快”和“报表清晰” |
| **审美诉求** | 偏好原生、干净、无干扰的界面 | 拒绝花哨的动画和高饱和度的促销色彩 |
| **隐私态度** | 高度敏感，不愿意注册第三方账号 | 偏好本地存储 \+ iCloud 同步 |

### **2.3 竞品缺口与机会点**

虽然市场上存在如 MySugr 这样的巨头，以及数以千计的血糖记录应用，但真正做到“极致简单”且“符合现代 iOS 设计规范”的产品极少。

* **巨头应用（MySugr, OneTouch）：** 功能极其强大，包含胰岛素计算、估算 A1C、挑战游戏等。缺点是启动慢，界面元素过多，且主要目的是为了卖试纸或订阅服务。  
* **老旧工具类应用：** App Store 中存在大量由个人开发者多年前开发的应用，界面仍停留在 iOS 6 拟物化时代或早期的扁平化设计，缺乏对暗黑模式（Dark Mode）、动态字体（Dynamic Type）和新图表框架（Swift Charts）的支持。  
* **通用健康应用（Apple Health）：** 苹果自带的健康应用虽然极简，但在数据录入上层级较深（需多次点击才能到达血糖录入界面），且缺乏针对糖尿病人的标签系统（如“餐前”、“餐后”）。

**结论：** 开发一款基于最新 iOS 技术栈（SwiftUI, Swift Charts），专注于“录入速度”和“数据可视化”，且完全无广告、无账号体系的极简应用，存在明确的市场机会。这不仅符合用户对“工具”回归本质的期待，也规避了与巨头在内容和服务上的直接竞争。

## **3\. 独立开发者的限制与风险控制**

作为一名独立开发者，在医疗健康领域开发应用面临着特殊的红线。理解并遵守这些规则是项目生存的前提。

### **3.1 苹果审核指南与“医疗器械”的界限**

苹果 App Store 审核指南第 1.4.1 条明确规定：“可能提供不准确数据或信息，或可能用于诊断或治疗患者的医疗应用，将受到更严格的审查” 5。

* **禁区（绝对避免）：**  
  * **胰岛素剂量计算器（Bolus Calculator）：** 如果应用根据用户的血糖和碳水摄入量推荐胰岛素注射剂量，它将被归类为 II 类医疗器械（SaMD）。这需要通过 FDA（美国）或 NMPA（中国）的严格认证，成本高昂且周期漫长，个人开发者几乎无法完成 6。  
  * **诊断性建议：** 应用不能提示“您可能患有酮症酸中毒，请立即就医”这类具有诊断性质的结论。  
  * **硬件依赖声明：** 不能声称利用手机自带传感器（如摄像头）测量血糖，除非有合规的外部硬件配合。  
* **安全区（合规策略）：**  
  * **定位为“数字日志”：** 应用的功能仅限于“记录”和“展示”用户自行输入的数据。所有数据的准确性由用户负责。  
  * **回顾性分析而非前瞻性建议：** 应用可以展示“过去 7 天的平均血糖是 X”，但不能建议“因为平均血糖高，建议您增加运动”。  
  * **免责声明：** 必须在应用内显著位置声明“本应用仅用于信息记录，不作为医疗诊断依据，做出医疗决定前请咨询医生”。

### **3.2 数据隐私与合规（PIPL 与 GDPR）**

考虑到目标市场可能包含中国（根据提问语言推测）及全球用户，数据合规至关重要。

* **中国个人信息保护法（PIPL）：**  
  * **数据本地化：** PIPL 规定关键基础设施运营者和处理大量个人信息的处理者，必须将数据存储在中国境内。对于独立开发者，自行搭建符合 PIPL 标准的服务器极其困难且昂贵。  
  * **解决方案：** 采用 **“本地优先 \+ iCloud 同步”** 的架构。应用不搭建任何私有后端服务器，数据仅存储在用户手机本地数据库（如 Realm 或 CoreData）中，并通过用户私有的 iCloud 账户进行同步。在这种架构下，开发者实际上并不“持有”用户数据，数据的主权完全归用户所有，且 iCloud 在中国由云上贵州运营，天然符合数据本地化要求 8。  
* **GDPR（欧盟）：**  
  * 虽然 iCloud 架构在很大程度上规避了数据处理者的责任，但仍需在应用内提供清晰的隐私政策，明确告知“本应用不收集任何数据到开发者服务器”。  
  * 必须提供“数据导出”和“数据删除”功能，满足用户的被遗忘权 9。

### **3.3 商业化限制**

作为工具类应用，独立开发者较难通过广告变现（会破坏极简体验）。

* **推荐模式：** **买断制（Lifetime）** 或 **极低价格的订阅制（Tips jar）**。  
* **策略：** 基础记录功能完全免费，以积累用户口碑；高级图表（如 A1C 估算趋势、PDF 导出报告）可作为一次性内购解锁点。这符合极简主义用户对“拥有”而非“租赁”软件的偏好。

## **4\. 产品需求文档（PRD）：极简控糖 App**

基于上述分析，本章节详细定义产品的功能与设计规范。核心理念是 **“少即是多”（Less is More）**，但在关键体验上做加法。

### **4.1 产品愿景**

做 iOS 平台上最快、最纯粹的血糖记录工具，让控糖回归数据本质。

### **4.2 核心功能需求**

#### **4.2.1 极速录入系统（The 3-Second Rule）**

这是产品的核心竞争力。目标是让用户在 3 秒内完成一次记录。

* **冷启动直达：** 应用打开后不展示 Dashboard 概览，而是直接弹起数字键盘进入录入状态（或将录入框置于首屏最显著位置）。  
* **定制化数字键盘：**  
  * 不使用系统自带键盘（为了避免弹起动画的延迟和非必要按键的干扰）。  
  * 设计一个占据屏幕下半部分的超大按钮定制键盘 10。  
  * **键位布局：** 0-9 数字键，一个超大的“小数点”键（这对记录血糖至关重要），以及一个“保存”键。  
  * **智能单位适配：** 根据用户系统语言或首次设置，自动适配 mmol/L 或 mg/dL。支持输入 5.5 自动识别为 mmol/L，输入 100 自动识别为 mg/dL 的智能逻辑（需在设置中提供开关以防误判）11。  
* **场景标签（Tag）自动化：**  
  * 系统根据当前时间自动预选标签。例如：06:00-09:00 默认为“早餐前”；11:00-13:00 默认为“午餐前”。用户仅需在例外情况手动修改，减少点击次数 12。

#### **4.2.2 数据存储与同步**

* **HealthKit 集成（核心）：**  
  * 应用作为 Apple Health 数据库的“高级视图”。所有血糖数据写入时同步至 Apple Health，读取时从 Apple Health 获取。  
  * **优势：** 用户删除应用后数据不丢失（保留在健康 App 中）；可与其他应用（如运动 App）数据打通；无需开发者维护服务器。  
* **本地数据库冗余：**  
  * 虽然依赖 HealthKit，但为了标签（早餐前/后）和备注（吃了火锅）等 HealthKit 可能支持不完善的元数据，建议使用 **SwiftData** 或 **Realm** 作为本地主存，并将核心数值同步给 HealthKit 13。

#### **4.2.3 数据可视化（极简图表）**

* **“河流”视图（The Stream）：** 首页为一个无限下拉的时间轴列表，左侧为时间，右侧为数值。数值背景色根据高低动态变化（红/黄/绿）。  
* **趋势概览：**  
  * 不展示复杂的饼图或雷达图。  
  * 仅展示一条 **平滑曲线图（Line Chart）**，显示最近 7 天或 14 天的血糖波动。  
  * 使用 **Swift Charts** 框架实现，支持长按查看具体数值 15。  
* **关键指标卡片：** 仅展示三个核心数据：  
  * 当前平均值（eAG）。  
  * 达标率（Time in Range, TIR）。  
  * 预估 A1C（糖化血红蛋白）。

#### **4.2.4 数据导出与分享**

* **功能：** 生成 PDF 格式的医生报告。  
* **内容：** 表格化的数据清单，异常高低值的标红高亮。  
* **交互：** 点击“分享”按钮，调用 iOS 系统分享表单，直接发送给微信好友或通过邮件发送 17。

### **4.3 UI/UX 设计规范**

#### **4.3.1 色彩体系：医疗级暗黑模式**

考虑到糖尿病患者可能并发视网膜病变，以及夜间测血糖的场景，UI 必须支持深色模式，且对比度需达到 WCAG AAA 标准。

| 语义 | 建议色值 (Hex) | 设计心理学依据 |
| :---- | :---- | :---- |
| **背景色** | \#000000 (纯黑) | OLED 屏幕省电，极致的沉浸感，夜间不刺眼 18。 |
| **一级文字** | \#FFFFFF (纯白) | 最高对比度，确保数字清晰可读。 |
| **二级文字** | \#8E8E93 (系统灰) | 用于日期、辅助说明，降低视觉干扰。 |
| **正常血糖** | \#30D158 (薄荷绿) | 传递安全、健康、无需干预的信号。 |
| **偏高预警** | \#FFD60A (向日葵黄) | 警示，醒目但不引起恐慌（避免使用刺眼的纯红）。 |
| **严重异常** | \#FF453A (番茄红) | 紧急状态，需要立即引起注意（如低血糖 \<3.9 mmol/L）。 |
| **品牌色** | \#0A84FF (系统蓝) | 科技感，冷静，专业，用于按钮和交互元素。 |

#### **4.3.2 字体与排版**

* **字体：** 必须使用 iOS 原生字体 **San Francisco (SF Pro)**。特别是数字部分，使用 SF Pro Rounded 变体，会给医疗数据带来一种更“柔和”、“不冰冷”的感觉 19。  
* **字号：**  
  * 核心读数（列表中的血糖值）：至少 **24pt \- 32pt**，加粗（Bold）。  
  * 日期标签：**15pt**，常规（Regular）。  
* **动态字体支持：** 必须支持 iOS 系统的动态字体设置。如果用户在系统中调大了字体，App 内的布局不能错乱，而是自适应调整。

#### **4.3.3 交互设计细节**

* **触觉反馈（Haptics）：** 在数字键盘点击、保存成功、删除条目时，加入轻微的触觉反馈（Taptic Engine），增强“确认感”，这对指尖触觉可能迟钝的糖尿病患者非常友好 20。  
* **无障碍（Accessibility）：** 完美支持 VoiceOver。每个按钮都必须有清晰的 accessibilityLabel（例如，“添加血糖记录按钮”而不仅仅是“加号”）。

### **4.4 小组件与生态扩展**

* **桌面小组件（Widget）：**  
  * **小号：** 仅显示最近一次读数和距离现在的时间（例如“5.6 • 20分钟前”）。  
  * **中号：** 显示最近读数 \+ 简易周趋势折线图。  
* **锁屏小组件：** 圆形进度条，显示今日达标率。  
* **Siri 捷径（Shortcuts）：** 支持“Hey Siri，记录血糖”，通过语音直接录入，解放双手。

## **5\. 技术架构与实现方案**

本节为独立开发者提供具体的技术选型建议，核心原则是“降低维护成本”和“利用原生能力”。

### **5.1 技术栈选型**

* **开发语言：** **Swift 5/6**。  
* **UI 框架：** **SwiftUI**。  
  * *理由：* SwiftUI 开发效率极高，代码量比 UIKit 少 40% 以上，且天然支持暗黑模式和动态字体。对于列表类、图表类应用，SwiftUI 是最佳选择 21。  
* **图表库：** **Swift Charts** (iOS 16+)。  
  * *理由：* 苹果官方框架，不仅性能最好，而且自动支持无障碍（VoiceOver 可以朗读图表数据的趋势），这是第三方库（如 Charts）难以做到的 15。  
* **数据层：** **SwiftData** (iOS 17+) 或 **CoreData** \+ **CloudKit**。  
  * *理由：* 开启 CloudKit 选项后，苹果会自动处理数据的云端同步。开发者不需要写一行后端代码，也不需要购买 AWS/阿里云服务器，极大地降低了成本和运维压力 14。

### **5.2 核心代码逻辑架构**

#### **5.2.1 HealthKit 管理器 (HealthKitManager)**

这是应用与苹果健康数据库交互的桥梁。

Swift

import HealthKit

class HealthKitManager: ObservableObject {  
    let healthStore \= HKHealthStore()  
      
    // 权限请求  
    func requestAuthorization() {  
        let types \= Set()  
        healthStore.requestAuthorization(toShare: types, read: types) { success, error in  
            // 处理结果  
        }  
    }  
      
    // 保存血糖  
    func saveGlucose(value: Double, unit: HKUnit, date: Date, context: String) {  
        let type \= HKQuantityType.quantityType(forIdentifier:.bloodGlucose)\!  
        let quantity \= HKQuantity(unit: unit, doubleValue: value)  
          
        // 元数据：记录是餐前还是餐后  
        let metadata: \=  
          
        let sample \= HKQuantitySample(type: type, quantity: quantity, start: date, end: date, metadata: metadata)  
          
        healthStore.save(sample) { success, error in  
            // 处理保存回调  
        }  
    }  
}

#### **5.2.2 极简键盘视图 (MinimalKeypad)**

使用 LazyVGrid 构建自定义键盘，而非使用 TextField 的系统键盘。

Swift

struct MinimalKeypad: View {  
    let action: (String) \-\> Void  
    let columns \= \[GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())\]  
      
    var body: some View {  
        LazyVGrid(columns: columns, spacing: 15) {  
            ForEach(1...9, id: \\.self) { num in  
                Button(action: { action("\\(num)") }) {  
                    Text("\\(num)")  
                       .font(.system(size: 28, weight:.medium, design:.rounded))  
                       .frame(height: 60)  
                       .background(Color(.systemGray6))  
                       .cornerRadius(12)  
                }  
            }  
            // 处理 0 和 小数点  
            Button(action: { action(".") }) { Text(".")... }  
            Button(action: { action("0") }) { Text("0")... }  
            Button(action: { action("delete") }) { Image(systemName: "delete.left")... }  
        }  
    }  
}

### **5.3 数据隐私合规实现**

在 Info.plist 中必须配置 NSHealthShareUsageDescription 和 NSHealthUpdateUsageDescription，文案需亲切且明确：“App 需要访问您的健康数据，以便将血糖记录同步到系统的‘健康’应用中，确保存储安全。”

## **6\. App 名称与品牌策略**

极简应用的名称需要传达出“轻量”、“纯净”和“专业”的感觉，避免过于医疗化或沉重。

### **6.1 命名建议**

| 名称方案 | 英文名 | 推荐理由 |
| :---- | :---- | :---- |
| **方案一（极简风）** | **简糖** | **SimplySugar** |
| **方案二（工具风）** | **糖记** | **SugarLog** |
| **方案三（禅意风）** | **清糖** | **PureGluc** |
| **方案四（状态风）** | **稳糖** | **Steady** |

**推荐选择：** 中文名 **“简糖”**，英文名 **“SugarSimple”**。

* *可用性检查：* 需在 App Store Connect 中搜索确认未被占用（目前“简糖”类名称较多，可考虑 **“简糖日记”** 或 **“简糖 Note”** 以增加独特性）。

### **6.2 应用简介（ASO 优化）**

**标题：** 简糖 Note \- 极简血糖记录助手

**副标题：** 秒级录入，无广告，Apple Health 同步

**描述文案：**

厌倦了复杂的控糖应用？“简糖 Note”为您做减法。

我们深知，对于控糖人士而言，坚持记录比什么都重要。因此，我们移除了所有多余的社交干扰、广告弹窗和繁琐的教程，只为您保留最纯粹的记录体验。

**核心特色：**

* **3秒录入：** 独创大按钮数字键盘，打开即记，一步到位。  
* **纯净无广：** 永久无广告，不打扰您的每一次记录。  
* **数据安全：** 基于 Apple Health 和 iCloud 开发，数据仅存储在您的手机和 iCloud 中，开发者无法查看。  
* **清晰图表：** 自动生成 7 日/ 30 日趋势曲线，一眼看懂血糖波动。  
* **隐私至上：** 无需注册账号，无需手机号，即下即用。

让控糖回归生活，从一次简单的记录开始。

## **7\. 结论与建议**

开发一款“极简控糖 App”不仅是对用户痛点的精准回应，也是独立开发者在巨头林立的医疗健康赛道中突围的最佳策略。

**关键成功要素总结：**

1. **克制：** 坚决抵制增加“社区”、“商城”、“资讯”等功能的诱惑。保持工具的纯粹性是留住核心用户的关键。  
2. **原生：** 充分利用 Apple 的 HealthKit 和 Swift Charts，这不仅降低了开发成本，还保证了应用拥有 iOS 系统级的流畅度和无障碍体验。  
3. **隐私：** 将“无账号体系”、“本地存储”作为核心卖点，在隐私日益受关注的今天，这是建立用户信任的最强护城河。  
4. **设计：** 投入精力打磨暗黑模式下的色彩对比和字体排版，让应用在视觉上呈现出专业、冷静的高级感。

通过执行本报告中的策略，您将能够构建出一款既符合监管要求，又深受用户喜爱的“小而美”的精品应用。

#### **引用的著作**

1. What are the perceptions and experiences of adults using mobile applications for self-management in diabetes? A systematic review \- PubMed Central, 访问时间为 一月 24, 2026， [https://pmc.ncbi.nlm.nih.gov/articles/PMC11751966/](https://pmc.ncbi.nlm.nih.gov/articles/PMC11751966/)  
2. LifePulse :smartlife app \- App Store, 访问时间为 一月 24, 2026， [https://apps.apple.com/us/app/lifepulse-smartlife-app/id6618141389](https://apps.apple.com/us/app/lifepulse-smartlife-app/id6618141389)  
3. Mobile Health App Developers: FTC Best Practices | Federal Trade Commission, 访问时间为 一月 24, 2026， [https://www.ftc.gov/business-guidance/resources/mobile-health-app-developers-ftc-best-practices](https://www.ftc.gov/business-guidance/resources/mobile-health-app-developers-ftc-best-practices)  
4. Consider implementing a SwiftData Custom Store (new in iOS18) for Realm \#8627 \- GitHub, 访问时间为 一月 24, 2026， [https://github.com/realm/realm-swift/issues/8627](https://github.com/realm/realm-swift/issues/8627)  
5. App Review Guidelines \- Apple Developer, 访问时间为 一月 24, 2026， [https://developer.apple.com/app-store/review/guidelines/](https://developer.apple.com/app-store/review/guidelines/)  
6. Is There an App for That? The Pros and Cons of Diabetes Smartphone Apps and How to Integrate Them Into Clinical Practice, 访问时间为 一月 24, 2026， [https://diabetesjournals.org/spectrum/article-pdf/32/3/231/505935/231.pdf](https://diabetesjournals.org/spectrum/article-pdf/32/3/231/505935/231.pdf)  
7. App Store Optimization: Scaling Medical Apps \- Tapadoo, 访问时间为 一月 24, 2026， [https://tapadoo.com/blog/posts/app-store-optimization-scaling-medical-apps/](https://tapadoo.com/blog/posts/app-store-optimization-scaling-medical-apps/)  
8. Legal \- iCloud GCBD \- Apple, 访问时间为 一月 24, 2026， [https://www.apple.com/legal/internet-services/icloud/en/gcbd-terms.html](https://www.apple.com/legal/internet-services/icloud/en/gcbd-terms.html)  
9. HIPAA and GDPR Compliance for Health App Developers » LLIF.org, 访问时间为 一月 24, 2026， [https://llif.org/2025/01/31/hipaa-gdpr-compliance-health-apps/](https://llif.org/2025/01/31/hipaa-gdpr-compliance-health-apps/)  
10. Advanced SwiftUI TextField \- Formatting and Validation \- Fatbobman's Blog, 访问时间为 一月 24, 2026， [https://fatbobman.com/en/posts/textfield-1/](https://fatbobman.com/en/posts/textfield-1/)  
11. bloodGlucose | Apple Developer Documentation, 访问时间为 一月 24, 2026， [https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/bloodglucose](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/bloodglucose)  
12. When to check your blood sugar level | Kaiser Permanente, 访问时间为 一月 24, 2026， [https://healthy.kaiserpermanente.org/health-wellness/healtharticle.when-to-check-your-blood-sugar-level](https://healthy.kaiserpermanente.org/health-wellness/healtharticle.when-to-check-your-blood-sugar-level)  
13. Realm in iOS — A Modern Alternative to Core Data | by Shweta Chaturvedi | Medium, 访问时间为 一月 24, 2026， [https://medium.com/@shweta.trrev/realm-in-ios-a-modern-alternative-to-core-data-02b0acaedca7](https://medium.com/@shweta.trrev/realm-in-ios-a-modern-alternative-to-core-data-02b0acaedca7)  
14. SwiftData \+ CloudKit in Production: How to Build Reliable iCloud Sync in Your iOS App, 访问时间为 一月 24, 2026， [https://medium.com/@shrader.gavin/swiftdata-cloudkit-in-production-how-to-build-reliable-icloud-sync-in-your-ios-app-055b2dd06e4c](https://medium.com/@shrader.gavin/swiftdata-cloudkit-in-production-how-to-build-reliable-icloud-sync-in-your-ios-app-055b2dd06e4c)  
15. SwiftUI Charts: Visualize Your Data Beautifully with Apple's Native API \- Commit Studio, 访问时间为 一月 24, 2026， [https://commitstudiogs.medium.com/swiftui-charts-visualize-your-data-beautifully-with-apples-native-api-8015a7f01039](https://commitstudiogs.medium.com/swiftui-charts-visualize-your-data-beautifully-with-apples-native-api-8015a7f01039)  
16. Visualizing Data with Swift Charts \- Base11 Studios, 访问时间为 一月 24, 2026， [https://base11studios.com/ios/swift/swiftui/charts/2023/04/06/pretty-swiftui-line-charts/](https://base11studios.com/ios/swift/swiftui/charts/2023/04/06/pretty-swiftui-line-charts/)  
17. App Design Features Important for Diabetes Self-management as Determined by the Self-Determination Theory on Motivation: Content Analysis of Survey Responses From Adults Requiring Insulin Therapy, 访问时间为 一月 24, 2026， [https://diabetes.jmir.org/2023/1/e38592](https://diabetes.jmir.org/2023/1/e38592)  
18. Dark theme \- Material Design, 访问时间为 一月 24, 2026， [https://m2.material.io/design/color/dark-theme.html](https://m2.material.io/design/color/dark-theme.html)  
19. Improving the Typography of a Fitness App \- Pimp my Type, 访问时间为 一月 24, 2026， [https://pimpmytype.com/review-fitness-app/](https://pimpmytype.com/review-fitness-app/)  
20. Entering data | Apple Developer Documentation, 访问时间为 一月 24, 2026， [https://developer.apple.com/design/human-interface-guidelines/entering-data](https://developer.apple.com/design/human-interface-guidelines/entering-data)  
21. Reading data from HealthKit in a SwiftUI app \- Create with Swift, 访问时间为 一月 24, 2026， [https://www.createwithswift.com/reading-data-from-healthkit-in-a-swiftui-app/](https://www.createwithswift.com/reading-data-from-healthkit-in-a-swiftui-app/)  
22. Built a free iOS fitness app using SwiftUI \+ HealthKit \+ Firebase : r/iOSProgramming \- Reddit, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/iOSProgramming/comments/1kjau13/built\_a\_free\_ios\_fitness\_app\_using\_swiftui/](https://www.reddit.com/r/iOSProgramming/comments/1kjau13/built_a_free_ios_fitness_app_using_swiftui/)  
23. Swift Charts | Apple Developer Documentation, 访问时间为 一月 24, 2026， [https://developer.apple.com/documentation/Charts](https://developer.apple.com/documentation/Charts)  
24. Database for offline first app : r/iOSProgramming \- Reddit, 访问时间为 一月 24, 2026， [https://www.reddit.com/r/iOSProgramming/comments/secmvh/database\_for\_offline\_first\_app/](https://www.reddit.com/r/iOSProgramming/comments/secmvh/database_for_offline_first_app/)