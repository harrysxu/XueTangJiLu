# 极简控糖 App（XueTangJiLu）UI/UX 设计文档

> **版本：** v1.0  
> **日期：** 2026-02-12  
> **作者：** 设计团队  
> **状态：** 初始草案

---

## 目录

1. [设计理念与原则](#1-设计理念与原则)
2. [设计系统（Design System）](#2-设计系统design-system)
3. [信息架构与导航](#3-信息架构与导航)
4. [各页面详细设计](#4-各页面详细设计)
5. [组件库定义](#5-组件库定义)
6. [动效与交互规范](#6-动效与交互规范)
7. [Widget 设计](#7-widget-设计)
8. [无障碍设计](#8-无障碍设计)
9. [页面线框图与布局](#9-页面线框图与布局)

---

## 1. 设计理念与原则

### 1.1 设计灵感来源

| 参考应用 | 借鉴要素 | 取舍说明 |
|:---------|:---------|:---------|
| **Apple Health** | 信息架构层级、卡片式数据展示、系统级视觉语言 | 借鉴整体视觉风格，但简化层级深度 |
| **Apple Fitness** | 圆环进度指示、动态色彩系统 | 借鉴 TIR 达标率的圆环展示方式 |
| **Gentler Streak** | 卡片式布局、数据可视化、健康指标展示 | 借鉴卡片组合排版，但去除社交元素 |
| **Calm / Balance** | 极简静谧美学、大量留白、柔和动效 | 借鉴整体氛围营造，传递安心感 |
| **mySugr** | 血糖仪表盘理念、快速录入 | 仅借鉴录入效率理念，去除所有臃肿功能 |
| **Activas** | Progressive Disclosure、关联指标卡片 | 借鉴渐进披露的信息展示策略 |

### 1.2 核心设计原则

#### 原则一：3 秒法则（Speed First）

> "对于每天需要频繁记录的用户而言，每次操作多消耗 5 秒钟，累积的挫败感是巨大的。"

- 应用打开到完成一次录入，全程不超过 **3 秒**
- 录入路径：打开 App → 点击 "+" → 输入数字 → 点击保存
- 最短路径仅需 **3 次点击**（点击 "+"、输入数字、保存）

#### 原则二：信息密度克制（Less is More）

- 每屏展示不超过 **3 个核心信息块**
- 数据不堆砌，而是分层呈现：先看概览，按需深入
- 去除一切装饰性元素，每个像素都有功能意义

#### 原则三：渐进披露（Progressive Disclosure）

- 首页只展示最新读数 + 今日概要 + 时间轴
- 趋势页按需展示 7/14/30 天图表
- 详情页点击才展开备注、编辑功能

#### 原则四：情感化设计（Calm Technology）

- 通过色彩传递血糖状态，**绿色 = 安心**，而非冰冷的数字堆砌
- 正常血糖时界面呈现平静氛围；异常时温和提醒，不制造恐慌
- 触觉反馈增强"确认感"，给予用户操作安全感

#### 原则五：无障碍优先（Accessibility First）

- 考虑糖尿病并发视网膜病变的用户：高对比度、大字体
- 考虑末梢神经病变的用户：大按钮、触觉反馈
- 完整支持 VoiceOver、Dynamic Type、Reduce Motion

---

## 2. 设计系统（Design System）

### 2.1 色彩体系

#### 语义色彩（核心功能色）

| 语义 | Light Mode | Dark Mode | 用途 |
|:-----|:-----------|:----------|:-----|
| **正常血糖** | `#34C759` (System Green) | `#30D158` (薄荷绿) | 3.9-7.0 mmol/L 范围内的数值 |
| **偏高预警** | `#FF9500` (System Orange) | `#FFD60A` (向日葵黄) | 7.0-10.0 mmol/L 范围的数值 |
| **严重异常** | `#FF3B30` (System Red) | `#FF453A` (番茄红) | <3.9 或 >10.0 mmol/L 的数值 |
| **品牌主色** | `#007AFF` (System Blue) | `#0A84FF` (明亮蓝) | CTA 按钮、链接、交互元素 |

#### 中性色彩

| 语义 | Light Mode | Dark Mode | 用途 |
|:-----|:-----------|:----------|:-----|
| **主背景** | `#FFFFFF` | `#000000` | 页面主背景（纯黑 OLED 省电） |
| **次级背景** | `#F2F2F7` (systemGroupedBackground) | `#1C1C1E` | 卡片背景、分组区域 |
| **三级背景** | `#FFFFFF` (secondarySystemGroupedBackground) | `#2C2C2E` | 卡片内嵌区域 |
| **一级文字** | `#000000` | `#FFFFFF` | 标题、核心数值 |
| **二级文字** | `#3C3C43` (60% opacity) | `#EBEBF5` (60% opacity) | 副标题、辅助说明 |
| **三级文字** | `#3C3C43` (30% opacity) | `#EBEBF5` (30% opacity) | 占位文字、时间戳 |
| **分割线** | `#C6C6C8` (18% opacity) | `#545458` (24% opacity) | 列表分割线 |

#### 色彩使用规则

1. **语义一致性**：绿色永远代表安全，红色永远代表需关注，不混用
2. **面积控制**：语义色仅用于数值标签和图表，不大面积铺底
3. **对比度标准**：所有文字与背景的对比度不低于 **4.5:1**（WCAG AA），核心数值不低于 **7:1**（WCAG AAA）
4. **暗色模式纯黑**：主背景使用 `#000000` 而非深灰，在 OLED 屏幕上实现最佳省电和沉浸感

#### SwiftUI 实现

```swift
// Color+Theme.swift
import SwiftUI

extension Color {
    // 血糖语义色
    static let glucoseNormal = Color("GlucoseNormal")    // Assets 中定义
    static let glucoseHigh = Color("GlucoseHigh")
    static let glucoseLow = Color("GlucoseLow")
    static let brandPrimary = Color("BrandPrimary")

    // 快捷方法
    static func forGlucoseLevel(_ level: GlucoseLevel) -> Color {
        switch level {
        case .normal:   return .glucoseNormal
        case .high:     return .glucoseHigh
        case .low, .veryHigh: return .glucoseLow
        }
    }
}
```

### 2.2 字体系统

#### 字体选择

- **主字体：** SF Pro（iOS 系统默认）
- **数值字体：** SF Pro Rounded（圆角变体，传递柔和感，降低医疗数据的"冰冷感"）
- **等宽数字：** `.monospacedDigit()` 修饰符，确保数值对齐不跳动

#### 字体层级

| 层级 | 字体 | 字号 | 字重 | 用途 |
|:-----|:-----|:-----|:-----|:-----|
| **Display** | SF Pro Rounded | 56pt | Bold | 录入页实时预览数值 |
| **Hero** | SF Pro Rounded | 36pt | Bold | 首页最新血糖读数 |
| **Title 1** | SF Pro | 24pt | Bold | 页面标题 |
| **Title 2** | SF Pro | 20pt | Semibold | 卡片标题 |
| **Title 3** | SF Pro Rounded | 18pt | Medium | 统计指标数值（eAG/TIR/A1C） |
| **Body** | SF Pro | 17pt | Regular | 正文内容 |
| **Callout** | SF Pro | 16pt | Regular | 列表中的血糖数值 |
| **Subheadline** | SF Pro | 15pt | Regular | 辅助说明 |
| **Footnote** | SF Pro | 13pt | Regular | 时间戳、标签 |
| **Caption 1** | SF Pro | 12pt | Regular | 图表轴标签 |
| **Caption 2** | SF Pro | 11pt | Regular | 最小级辅助文字 |

#### SwiftUI 字体定义

```swift
extension Font {
    /// 录入页大数字预览
    static let glucoseDisplay = Font.system(size: 56, weight: .bold, design: .rounded)
        .monospacedDigit()

    /// 首页最新读数
    static let glucoseHero = Font.system(size: 36, weight: .bold, design: .rounded)
        .monospacedDigit()

    /// 统计指标数值
    static let glucoseMetric = Font.system(size: 18, weight: .medium, design: .rounded)
        .monospacedDigit()

    /// 列表中的数值
    static let glucoseCallout = Font.system(size: 16, weight: .semibold, design: .rounded)
        .monospacedDigit()
}
```

### 2.3 间距系统

采用 **8pt 网格系统**，所有间距为 4 的倍数：

| Token | 值 | 用途 |
|:------|:---|:-----|
| `spacing.xs` | 4pt | 图标与文字间距、紧凑标签内间距 |
| `spacing.sm` | 8pt | 列表项内部元素间距 |
| `spacing.md` | 12pt | 卡片内部元素间距 |
| `spacing.lg` | 16pt | 卡片内边距、区域间间距 |
| `spacing.xl` | 20pt | 卡片之间的间距 |
| `spacing.xxl` | 24pt | 页面顶部/底部安全边距 |
| `spacing.section` | 32pt | 不同功能区块之间的间距 |

### 2.4 圆角规范

| 元素 | 圆角值 | 说明 |
|:-----|:-------|:-----|
| 全屏卡片 | 20pt | 与 iOS 系统卡片风格一致 |
| 标准卡片 | 16pt | 统计卡片、图表容器 |
| 按钮（大） | 14pt | 保存按钮、CTA 按钮 |
| 按钮（中） | 12pt | 数字键盘按键 |
| 标签胶囊 | 全圆角 (capsule) | 场景标签（早餐前/餐后等） |
| 输入框 | 10pt | 备注输入框 |

### 2.5 阴影与层级

本应用以**扁平化**为主，极少使用阴影：

| 层级 | 阴影定义 | 用途 |
|:-----|:---------|:-----|
| **Level 0** | 无阴影 | 背景、列表行 |
| **Level 1** | `shadow(color: .black.opacity(0.05), radius: 8, y: 2)` | 浮动卡片（仅 Light Mode） |
| **Level 2** | `shadow(color: .black.opacity(0.1), radius: 16, y: 4)` | 录入键盘 sheet |

> **Dark Mode 规则：** 暗色模式下不使用阴影，改用 1px border (`Color.white.opacity(0.06)`) 区分层级。

### 2.6 图标系统

全部使用 **SF Symbols**（Apple 官方图标库），保持与系统一致性。

| 场景 | SF Symbol 名称 | 渲染模式 |
|:-----|:---------------|:---------|
| 录入（Tab图标） | `plus.circle.fill` | hierarchical |
| 首页（Tab图标） | `list.bullet` | monochrome |
| 趋势（Tab图标） | `chart.line.uptrend.xyaxis` | monochrome |
| 设置（Tab图标） | `gearshape` | monochrome |
| 早餐 | `sunrise` | hierarchical |
| 午餐 | `sun.max` | hierarchical |
| 晚餐 | `sunset` | hierarchical |
| 睡前 | `bed.double` | hierarchical |
| 空腹 | `moon.zzz` | hierarchical |
| 导出 | `square.and.arrow.up` | monochrome |
| 删除 | `delete.left` | monochrome |
| HealthKit | `heart.fill` | palette |

---

## 3. 信息架构与导航

### 3.1 导航结构

```
┌──────────────────────────────────────────────┐
│                 App 入口                      │
│                                              │
│  ┌─ 首次启动? ─── 是 ──→ OnboardingView     │
│  │                        ├─ 第1步: 欢迎      │
│  │                        ├─ 第2步: 单位选择   │
│  │                        ├─ 第3步: HealthKit  │
│  │                        └─ 完成 ──┐         │
│  │                                   │         │
│  └── 否 ────────────────────────────┘         │
│                    │                           │
│                    ▼                           │
│            MainTabView                         │
│     ┌──────┬───────┬──────┐                   │
│     │ 首页  │ 趋势  │ 设置  │                   │
│     │ Tab1 │ Tab2  │ Tab3 │                   │
│     └──┬───┴───┬───┴──┬───┘                   │
│        │       │      │                        │
│   HomeView  TrendView  SettingsView            │
│     │ ↓        │ ↓       │ ↓                   │
│     │ Sheet:   │ 图表    │ UnitPicker          │
│     │ Record   │ 交互    │ TargetRange         │
│     │ InputView│        │ ExportView           │
│     │          │        │ AboutView            │
│     │ Push:    │        │                      │
│     │ Record   │        │                      │
│     │ Detail   │        │                      │
└──────────────────────────────────────────────┘
```

### 3.2 Tab Bar 设计

底部导航栏采用 iOS 标准 TabView，共 3 个 Tab：

| Tab | 图标 | 标题 | 核心功能 |
|:----|:-----|:-----|:---------|
| **首页** | `list.bullet` | 记录 | 血糖记录流 + 快速录入入口 |
| **趋势** | `chart.line.uptrend.xyaxis` | 趋势 | 图表可视化 + 关键指标 |
| **设置** | `gearshape` | 设置 | 偏好设置 + 数据导出 |

**设计要点：**
- Tab 图标使用 SF Symbols 的 `.regular` 状态（未选中）和 `.fill` 状态（选中）
- Tab 数量控制在 3 个，避免"底部工具栏恐惧症"
- 首页 Tab 上方常驻一个显眼的 "+" 浮动按钮（FAB），作为快速录入入口

### 3.3 页面流转图

```
                    ┌──────────┐
                    │ App 启动  │
                    └────┬─────┘
                         │
              ┌──────────▼──────────┐
              │    是否首次启动？     │
              └──┬──────────────┬───┘
                 │ 是           │ 否
        ┌────────▼────────┐    │
        │  OnboardingView │    │
        │  (3 步引导流程)   │    │
        └────────┬────────┘    │
                 │              │
              ┌──▼──────────────▼──┐
              │    MainTabView     │
              │  ┌──┬──────┬──┐   │
              │  │首页│趋势│设置│   │
              │  └──┴──────┴──┘   │
              └──┬──────────────┬──┘
                 │              │
     ┌───────────▼──┐   ┌──────▼──────────┐
     │   点击 "+"    │   │   Tab 切换       │
     └───────┬──────┘   └─────────────────┘
             │
     ┌───────▼──────────────┐
     │  RecordInputView     │
     │  (Sheet 模态弹出)     │
     │                      │
     │  ┌─────────────────┐ │
     │  │ 大字数值预览     │ │
     │  │ 场景标签选择     │ │
     │  │ 自定义数字键盘   │ │
     │  │ 保存按钮         │ │
     │  └─────────────────┘ │
     └───────┬──────────────┘
             │ 保存成功
     ┌───────▼──────────────┐
     │  返回首页             │
     │  新记录出现在列表顶部  │
     │  + 成功动画 + 触觉反馈 │
     └──────────────────────┘
```

---

## 4. 各页面详细设计

### 4.1 启动引导页（OnboardingView）

**触发条件：** 首次安装后第一次打开 App

**设计要求：** 极简 3 步引导，不超过 30 秒完成

#### 第 1 步：欢迎

```
┌─────────────────────────────┐
│                             │
│                             │
│         [App Icon]          │
│                             │
│       学糖记录               │
│   让控糖回归简单              │
│                             │
│                             │
│                             │
│     ┌─────────────────┐     │
│     │     开始使用      │     │
│     └─────────────────┘     │
│                             │
└─────────────────────────────┘
```

- 全屏居中布局
- App Icon 使用大尺寸展示（80x80pt）
- 主标题 `.title` 字号 + Bold
- 副标题 `.body` 字号 + Secondary Color
- 按钮使用品牌蓝色填充样式

#### 第 2 步：单位选择

```
┌─────────────────────────────┐
│                             │
│   选择您的血糖单位            │
│   可随时在设置中更改           │
│                             │
│   ┌───────────────────┐     │
│   │                   │     │
│   │    mmol/L         │     │ ← 根据地区预选
│   │    (中国/欧洲常用)  │     │
│   │                   │     │
│   └───────────────────┘     │
│                             │
│   ┌───────────────────┐     │
│   │                   │     │
│   │    mg/dL          │     │
│   │    (美国/日本常用)  │     │
│   │                   │     │
│   └───────────────────┘     │
│                             │
│     ┌─────────────────┐     │
│     │      下一步      │     │
│     └─────────────────┘     │
│                             │
└─────────────────────────────┘
```

- 两个大卡片式选项，点击选中时有蓝色边框 + 轻触觉反馈
- 根据 `Locale.current.region` 自动预选
- 底部辅助文字："可随时在设置中更改"

#### 第 3 步：HealthKit 授权

```
┌─────────────────────────────┐
│                             │
│      ❤️ 健康数据同步          │
│                             │
│   连接 Apple Health 后，      │
│   您的血糖数据将自动备份       │
│   到系统"健康"应用中。        │
│                             │
│   ┌───────────────────┐     │
│   │   ✓ 数据备份更安全   │     │
│   │   ✓ 删除App数据不丢  │     │
│   │   ✓ 与其他健康数据   │     │
│   │     联动查看         │     │
│   └───────────────────┘     │
│                             │
│     ┌─────────────────┐     │
│     │   连接 Health    │     │
│     └─────────────────┘     │
│                             │
│     稍后再说（可在设置中开启）  │
│                             │
└─────────────────────────────┘
```

- HealthKit 图标使用心形 SF Symbol
- 列出 3 个核心好处
- 提供"稍后再说"的退出选项（文字链接，非按钮）
- 点击"连接"后触发系统 HealthKit 权限弹窗

### 4.2 首页 - 记录流（HomeView）

首页是用户使用频率最高的页面，承载"查看"和"录入入口"两个核心功能。

#### 页面结构

```
┌─────────────────────────────────────┐
│ 状态栏                               │
├─────────────────────────────────────┤
│                                     │
│  最新血糖                            │
│                                     │
│        5.6                          │  ← Hero 数值（36pt Bold Rounded）
│       mmol/L                        │  ← 单位（Caption）
│                                     │
│    早餐前 · 20 分钟前                 │  ← 标签 + 相对时间
│                                     │
├─────────────────────────────────────┤
│                                     │
│  今日概要                            │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │ 次数  │ │ 均值  │ │ 达标率│        │  ← 三个迷你统计卡片
│  │  4    │ │ 6.2  │ │ 75%  │        │
│  └──────┘ └──────┘ └──────┘        │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  今日记录                            │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 12:30  午餐后    7.2        │    │  ← 黄色数值（偏高）
│  ├─────────────────────────────┤    │
│  │ 11:00  午餐前    5.8        │    │  ← 绿色数值（正常）
│  ├─────────────────────────────┤    │
│  │ 08:15  早餐后    6.5        │    │  ← 绿色数值（正常）
│  ├─────────────────────────────┤    │
│  │ 06:30  早餐前    5.2        │    │  ← 绿色数值（正常）
│  └─────────────────────────────┘    │
│                                     │
│  昨日记录                            │
│  ┌─────────────────────────────┐    │
│  │  ...                        │    │
│  └─────────────────────────────┘    │
│                                     │
│                                     │
│                                     │
├─────────────────────────────────────┤
│                                     │
│        ┌─────────┐                  │
│        │    +    │                  │  ← 浮动录入按钮（FAB）
│        └─────────┘                  │
│                                     │
│  [ 记录 ]    [ 趋势 ]    [ 设置 ]    │  ← Tab Bar
└─────────────────────────────────────┘
```

#### 设计细节

**最新血糖区域：**
- 占据屏幕顶部约 1/4 空间
- 数值使用 Hero 字体（36pt Rounded Bold）
- 数值颜色根据 `GlucoseLevel` 动态变化
- 场景标签使用胶囊样式（Capsule）
- 相对时间显示（"20 分钟前"、"2 小时前"）
- 如无今日记录，显示"暂无记录"占位图

**今日概要卡片：**
- 水平排列 3 个迷你统计卡片
- 等宽分布，间距 `spacing.sm`（8pt）
- 卡片背景使用 `secondarySystemGroupedBackground`
- 数值使用 `glucoseMetric` 字体
- 标签使用 `caption` 字体 + secondary 颜色

**时间轴列表：**
- 按日期分组（Section），日期作为 Section Header
- 每行左侧：时间（HH:mm 格式）+ 场景标签图标
- 每行右侧：血糖数值（带语义颜色）
- 支持左滑删除
- 支持点击查看详情（如有备注）
- 使用 `LazyVStack` 实现懒加载

**浮动录入按钮（FAB）：**
- 固定在列表底部上方、Tab Bar 上方
- 尺寸：56x56pt 圆形
- 背景色：品牌蓝色
- 图标：白色 `plus` SF Symbol
- 阴影：Level 1
- 点击后以 Sheet 模态弹出 `RecordInputView`

**空状态设计：**

```
┌─────────────────────────────┐
│                             │
│                             │
│      [滴血图标 - 淡灰色]     │
│                             │
│     还没有任何记录            │
│   点击下方 "+" 开始记录       │
│                             │
│                             │
└─────────────────────────────┘
```

### 4.3 快速录入页（RecordInputView）

这是整个 App 的**核心页面**，承载产品最重要的竞争力——3 秒录入。

#### 页面结构

```
┌─────────────────────────────────────┐
│  ┌──────┐              ┌──────┐    │
│  │ 取消  │              │ 备注  │    │  ← 顶部导航
│  └──────┘              └──────┘    │
│                                     │
│               5.6                   │  ← Display 数值（56pt Rounded）
│              mmol/L                 │
│                                     │
│   ┌────────────────────────────┐    │
│   │ 🌅早餐前│午餐前│午餐后│...  │    │  ← 场景标签横向滚动选择
│   └────────────────────────────┘    │
│                                     │
│   2026年2月12日 12:30              │  ← 可点击修改日期时间
│                                     │
├─────────────────────────────────────┤
│                                     │
│   ┌────┐  ┌────┐  ┌────┐          │
│   │ 1  │  │ 2  │  │ 3  │          │
│   └────┘  └────┘  └────┘          │
│                                     │
│   ┌────┐  ┌────┐  ┌────┐          │
│   │ 4  │  │ 5  │  │ 6  │          │  ← 自定义数字键盘
│   └────┘  └────┘  └────┘          │
│                                     │
│   ┌────┐  ┌────┐  ┌────┐          │
│   │ 7  │  │ 8  │  │ 9  │          │
│   └────┘  └────┘  └────┘          │
│                                     │
│   ┌────┐  ┌────┐  ┌────┐          │
│   │ .  │  │ 0  │  │ ⌫  │          │
│   └────┘  └────┘  └────┘          │
│                                     │
│   ┌─────────────────────────────┐  │
│   │         保存记录              │  │  ← 保存按钮
│   └─────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

#### 设计细节

**数值预览区域：**
- 居中大字展示当前输入值
- 字体：`glucoseDisplay`（56pt Rounded Bold Monospaced）
- 颜色随输入值动态变化（实时反映血糖状态）
- 单位标签居于数值下方（caption 大小）
- 输入为空时显示 "0.0" 占位（三级文字色）

**场景标签选择器：**
- 水平滚动的 Capsule 标签列表
- 根据当前时间自动预选一个标签（TagEngine）
- 选中状态：品牌蓝色背景 + 白色文字
- 未选中状态：`tertiarySystemGroupedBackground` + 一级文字
- 每个标签左侧带 SF Symbol 图标
- 标签高度 36pt，水平内边距 16pt

**日期时间选择器：**
- 默认显示当前日期时间（"2026年2月12日 12:30"格式）
- 点击后弹出系统 DatePicker（`.dateAndTime` 样式）
- 多数情况用户无需修改，降低视觉权重（footnote 字号 + secondary 色彩）

**自定义数字键盘（MinimalKeypad）：**
- 3 列 4 行网格布局（`LazyVGrid`）
- 按键尺寸：宽度三等分（减去间距），高度 60pt
- 按键背景：`tertiarySystemGroupedBackground`
- 按键文字：28pt Medium Rounded
- 按键圆角：12pt
- 按键间距：10pt
- 小数点键 "." 放在左下角（对血糖录入极为重要）
- 删除键 "⌫" 放在右下角，使用 SF Symbol `delete.left`
- 每次按键触发 `UIImpactFeedbackGenerator(.light)` 触觉反馈

**保存按钮：**
- 全宽按钮，高度 54pt
- 背景色：品牌蓝色
- 文字："保存记录"，白色 17pt Semibold
- 圆角：14pt
- 未输入有效值时：灰色禁用状态
- 按下后：
  1. 触觉反馈（`.success` notification feedback）
  2. 数值上浮消失动画（0.3s）
  3. Sheet 自动关闭
  4. 首页列表顶部出现新记录（带淡入动画）

**备注功能：**
- 顶部右侧"备注"按钮打开备注输入
- 备注为可选功能，使用系统键盘
- 备注内容显示在数值预览下方（如有）
- placeholder："添加备注（可选）"

#### 输入验证规则

| 规则 | 条件 | 反馈 |
|:-----|:-----|:-----|
| 最小值 | mmol/L: 1.0 / mg/dL: 18 | 低于阈值保存按钮禁用 |
| 最大值 | mmol/L: 33.3 / mg/dL: 600 | 超过阈值保存按钮禁用 |
| 小数位数 | mmol/L: 最多1位 / mg/dL: 无小数 | 超过位数忽略输入 |
| 多个小数点 | 已有小数点时 | 忽略第二个 "." 输入 |
| 前导零 | "05.6" | 自动去除显示为 "5.6" |

### 4.4 趋势页（TrendView）

展示血糖数据的可视化图表和关键统计指标。

#### 页面结构

```
┌─────────────────────────────────────┐
│ 趋势                                │  ← 导航标题
├─────────────────────────────────────┤
│                                     │
│  ┌──7天──┬──14天──┬──30天──┐        │  ← 时间范围分段控件
│  └───────┴───────┴────────┘        │
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │      📈 趋势折线图           │   │
│  │                             │   │  ← Swift Charts 折线图
│  │   目标范围带（浅绿色区域）    │   │
│  │                             │   │
│  │   数据点（带颜色语义）       │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │  平均血糖  │  │  预估A1C  │        │
│  │  (eAG)   │  │          │        │  ← 关键指标卡片（2列）
│  │  6.2     │  │  5.8%    │        │
│  │ mmol/L   │  │          │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │  达标率   │  │  记录次数  │        │
│  │  (TIR)   │  │          │        │  ← 关键指标卡片（2列）
│  │  78%     │  │   28     │        │
│  │ 目标>70% │  │  近7天    │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  波动系数 (CV%)               │   │
│  │  22.3%   稳定 ✓              │   │  ← 附加指标
│  │  目标 < 36%                  │   │
│  └─────────────────────────────┘   │
│                                     │
│  [ 记录 ]    [ 趋势 ]    [ 设置 ]   │
└─────────────────────────────────────┘
```

#### 设计细节

**时间范围选择器：**
- 使用 iOS 原生 `Picker` 的 `.segmented` 样式
- 三个选项：7 天 / 14 天 / 30 天
- 切换时图表平滑过渡动画

**趋势折线图（TrendLineChart）：**
- 使用 Swift Charts `LineMark` 绘制
- X 轴：日期（按天/半天分组）
- Y 轴：血糖数值（mmol/L 或 mg/dL）
- 目标范围区域：使用 `AreaMark` 绘制半透明绿色背景带（3.9-7.0 mmol/L）
- 数据点样式：小圆点，颜色随 `GlucoseLevel` 变化
- 折线样式：曲线插值（`.catmullRom`），线宽 2pt
- 长按交互：十字线 + 浮动气泡显示精确值和时间
- 图表高度：约 200pt
- Y 轴范围自动适应数据，但最小显示 2.0-12.0 mmol/L

**Swift Charts 实现要点：**

```swift
import Charts

struct TrendLineChart: View {
    let dataPoints: [ChartDataPoint]
    let targetLow: Double
    let targetHigh: Double

    var body: some View {
        Chart {
            // 目标范围背景
            RectangleMark(
                yStart: .value("Low", targetLow),
                yEnd: .value("High", targetHigh)
            )
            .foregroundStyle(.green.opacity(0.1))

            // 数据折线
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("时间", point.date),
                    y: .value("血糖", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.brandPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("时间", point.date),
                    y: .value("血糖", point.value)
                )
                .foregroundStyle(Color.forGlucoseLevel(point.level))
                .symbolSize(30)
            }
        }
        .chartYScale(domain: 2...14)
        .frame(height: 200)
    }
}
```

**关键指标卡片（StatCard）：**
- 2x2 网格布局
- 卡片背景：`secondarySystemGroupedBackground`
- 卡片圆角：16pt
- 卡片内边距：16pt
- 布局：
  - 顶部：指标名称（footnote + secondary 颜色）
  - 中部：数值（glucoseMetric 字体 + 一级文字色）
  - 底部：单位或目标参考（caption + tertiary 颜色）
- TIR 卡片额外展示一个迷你圆环进度条

**附加指标 - 波动系数（CV%）：**
- 全宽卡片
- 数值 + 状态标签（"稳定 ✓" 或 "波动较大 ⚠"）
- CV < 36% 显示绿色"稳定"标签
- CV >= 36% 显示黄色"波动较大"标签

### 4.5 设置页（SettingsView）

#### 页面结构

```
┌─────────────────────────────────────┐
│ 设置                                │
├─────────────────────────────────────┤
│                                     │
│  血糖偏好                            │
│  ┌─────────────────────────────┐   │
│  │ 单位                  mmol/L │   │
│  ├─────────────────────────────┤   │
│  │ 目标下限               3.9  │   │
│  ├─────────────────────────────┤   │
│  │ 目标上限               7.0  │   │
│  ├─────────────────────────────┤   │
│  │ 智能标签              ✓ 开启 │   │
│  └─────────────────────────────┘   │
│                                     │
│  数据同步                            │
│  ┌─────────────────────────────┐   │
│  │ Apple Health 同步    ✓ 已连接│   │
│  ├─────────────────────────────┤   │
│  │ iCloud 同步          ✓ 开启 │   │
│  └─────────────────────────────┘   │
│                                     │
│  数据管理                            │
│  ┌─────────────────────────────┐   │
│  │ 导出 PDF 报告            >  │   │
│  ├─────────────────────────────┤   │
│  │ 导出 CSV 数据            >  │   │
│  └─────────────────────────────┘   │
│                                     │
│  关于                               │
│  ┌─────────────────────────────┐   │
│  │ 版本                  1.0.0 │   │
│  ├─────────────────────────────┤   │
│  │ 隐私政策                  > │   │
│  ├─────────────────────────────┤   │
│  │ 免责声明                  > │   │
│  ├─────────────────────────────┤   │
│  │ 给我们评分                > │   │
│  └─────────────────────────────┘   │
│                                     │
│  [ 记录 ]    [ 趋势 ]    [ 设置 ]   │
└─────────────────────────────────────┘
```

#### 设计细节

- 使用 iOS 标准 `Form` / `List` 的 `.insetGrouped` 样式
- 分为 4 个 Section：血糖偏好 / 数据同步 / 数据管理 / 关于
- 单位选择使用 `NavigationLink` 跳转至选择页
- 目标上下限使用 `Stepper` 或 `Slider` 调整
- 开关项使用系统 `Toggle`
- 数据管理区域的"导出 PDF"跳转至日期范围选择页

### 4.6 PDF 报告预览页（PDFPreviewView）

```
┌─────────────────────────────────────┐
│ ← 返回            PDF 报告          │
├─────────────────────────────────────┤
│                                     │
│  选择日期范围                         │
│  ┌─────────────────────────────┐   │
│  │ 开始日期          2026-02-01│   │
│  ├─────────────────────────────┤   │
│  │ 结束日期          2026-02-12│   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │     [PDF 预览区域]           │   │
│  │                             │   │
│  │     血糖记录报告              │   │
│  │     报告周期：2/1 - 2/12     │   │
│  │     ...                     │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    📤 分享报告               │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

- 日期范围选择使用系统 `DatePicker`
- PDF 预览使用 `PDFKitView`（UIViewRepresentable 包装 PDFView）
- 分享按钮调用 `ShareLink` 或 `UIActivityViewController`
- 分享目标支持：微信、邮件、AirDrop、文件

---

## 5. 组件库定义

### 5.1 GlucoseValueBadge（血糖数值标签）

带颜色语义的血糖数值显示组件，根据数值自动变色。

```swift
struct GlucoseValueBadge: View {
    let value: Double
    let unit: GlucoseUnit
    let level: GlucoseLevel
    let style: BadgeStyle

    enum BadgeStyle {
        case hero      // 36pt，用于首页大数字
        case display   // 56pt，用于录入预览
        case callout   // 16pt，用于列表行
        case compact   // 14pt，用于 Widget
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(formattedValue)
                .font(fontForStyle)
                .foregroundStyle(Color.forGlucoseLevel(level))

            if showUnit {
                Text(unit.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

**变体展示：**

| 样式 | 字体 | 场景 |
|:-----|:-----|:-----|
| Hero | 36pt Rounded Bold | 首页最新读数 |
| Display | 56pt Rounded Bold | 录入页预览 |
| Callout | 16pt Rounded Semibold | 时间轴列表 |
| Compact | 14pt Rounded Medium | Widget |

### 5.2 MealContextTag（场景标签胶囊）

```swift
struct MealContextTag: View {
    let context: MealContext
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: context.iconName)
                .font(.caption2)
            Text(context.displayName)
                .font(.footnote)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            isSelected
                ? Color.brandPrimary
                : Color(.tertiarySystemGroupedBackground)
        )
        .foregroundStyle(isSelected ? .white : .primary)
        .clipShape(Capsule())
    }
}
```

**状态：**
- 未选中：灰色背景 + 主文字色
- 选中：品牌蓝色背景 + 白色文字
- 自动预选（TagEngine 推荐）：与选中相同

### 5.3 MinimalKeypad（自定义数字键盘）

```swift
struct MinimalKeypad: View {
    let onKeyPress: (KeypadKey) -> Void

    enum KeypadKey {
        case digit(Int)
        case decimal
        case delete
    }

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            // Row 1: 1, 2, 3
            ForEach(1...3, id: \.self) { num in
                KeypadButton(label: "\(num)") {
                    onKeyPress(.digit(num))
                }
            }
            // Row 2: 4, 5, 6
            ForEach(4...6, id: \.self) { num in
                KeypadButton(label: "\(num)") {
                    onKeyPress(.digit(num))
                }
            }
            // Row 3: 7, 8, 9
            ForEach(7...9, id: \.self) { num in
                KeypadButton(label: "\(num)") {
                    onKeyPress(.digit(num))
                }
            }
            // Row 4: ., 0, ⌫
            KeypadButton(label: ".") {
                onKeyPress(.decimal)
            }
            KeypadButton(label: "0") {
                onKeyPress(.digit(0))
            }
            KeypadButton(icon: "delete.left") {
                onKeyPress(.delete)
            }
        }
        .padding(.horizontal)
    }
}

struct KeypadButton: View {
    let label: String?
    let icon: String?
    let action: () -> Void

    init(label: String, action: @escaping () -> Void) {
        self.label = label
        self.icon = nil
        self.action = action
    }

    init(icon: String, action: @escaping () -> Void) {
        self.label = nil
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            // 触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Group {
                if let label {
                    Text(label)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
```

### 5.4 StatCard（统计指标卡片）

```swift
struct StatCard: View {
    let title: String         // 指标名称（如"平均血糖"）
    let value: String         // 数值（如"6.2"）
    let subtitle: String?     // 单位或参考（如"mmol/L"）
    let tintColor: Color?     // 可选的强调色

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.glucoseMetric)
                .foregroundStyle(tintColor ?? .primary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

### 5.5 TimelineRow（时间轴列表行）

```swift
struct TimelineRow: View {
    let record: GlucoseRecord
    let unit: GlucoseUnit

    var body: some View {
        HStack(spacing: 12) {
            // 左侧：时间 + 场景图标
            VStack(alignment: .leading, spacing: 2) {
                Text(record.timestamp, format: .dateTime.hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: record.mealContext.iconName)
                        .font(.caption2)
                    Text(record.mealContext.displayName)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            // 右侧：血糖数值
            GlucoseValueBadge(
                value: record.value,
                unit: unit,
                level: record.glucoseLevel,
                style: .callout
            )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}
```

### 5.6 EmptyStateView（空状态占位）

```swift
struct EmptyStateView: View {
    let icon: String           // SF Symbol 名称
    let title: String          // 主标题
    let subtitle: String       // 辅助说明

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
```

---

## 6. 动效与交互规范

### 6.1 触觉反馈（Haptics）

| 场景 | 反馈类型 | 强度 | 说明 |
|:-----|:---------|:-----|:-----|
| 数字键盘按键 | `UIImpactFeedbackGenerator` | `.light` | 每次按键轻微震动 |
| 保存成功 | `UINotificationFeedbackGenerator` | `.success` | 两段式成功震动 |
| 删除确认 | `UINotificationFeedbackGenerator` | `.warning` | 警告震动 |
| 标签选中切换 | `UISelectionFeedbackGenerator` | — | 选择切换震动 |
| 长按图表查看数值 | `UIImpactFeedbackGenerator` | `.medium` | 首次触发时震动一次 |

#### SwiftUI 便利方法

```swift
extension View {
    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(TapGesture().onEnded { _ in
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        })
    }

    func hapticSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
```

### 6.2 页面转场动画

| 转场 | 动画类型 | 时长 | 说明 |
|:-----|:---------|:-----|:-----|
| 录入页弹出 | Sheet（系统默认） | ~0.3s | 从底部滑入，支持下拉关闭 |
| 录入页关闭 | Sheet dismiss | ~0.3s | 保存成功后自动关闭 |
| Tab 切换 | 无动画 | 即时 | Tab 切换不加过渡动画（系统标准） |
| 导航 Push | 系统默认滑入 | ~0.35s | 设置页子页面 |
| 图表范围切换 | `.animation(.smooth)` | 0.3s | 数据点平滑过渡 |

### 6.3 录入成功动画

```swift
// 保存成功后的数值上浮消失效果
struct SaveSuccessAnimation: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        Text("5.6")
            .font(.glucoseHero)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    offset = -40
                    opacity = 0
                }
            }
    }
}
```

**动画时序：**
1. 用户点击"保存"（0ms）
2. 触觉反馈触发（0ms）
3. 数值上浮 + 淡出（0-600ms）
4. Sheet 开始关闭（300ms）
5. 首页新记录淡入（600ms）

### 6.4 图表交互

**长按查看数值：**

```swift
// 图表长按选择器
Chart { ... }
    .chartOverlay { proxy in
        GeometryReader { geometry in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let xPosition = value.location.x
                            guard let date: Date = proxy.value(atX: xPosition) else { return }
                            // 找到最近的数据点
                            // 显示十字线 + 气泡
                            // 首次触发触觉反馈
                        }
                        .onEnded { _ in
                            // 隐藏十字线和气泡
                        }
                )
        }
    }
```

**气泡设计：**
- 小圆角矩形（8pt）
- 深色半透明背景（`Color(.systemBackground).opacity(0.9)`)
- 显示：精确数值 + 时间 + 场景标签
- 位置：跟随手指水平移动，固定在图表上方

### 6.5 Reduce Motion 适配

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// 如用户开启了减少动效
if reduceMotion {
    // 保存成功直接关闭 Sheet，不播放上浮动画
    // 图表切换使用淡入淡出而非平滑过渡
    // 取消所有 spring 动画
}
```

---

## 7. Widget 设计

### 7.1 小号 Widget（SystemSmall）

显示最新一次血糖读数和距今时间。

```
┌───────────────────────┐
│                       │
│       5.6             │  ← 数值（Compact 样式）
│      mmol/L           │  ← 单位
│                       │
│    早餐前              │  ← 场景标签
│    20 分钟前           │  ← 相对时间
│                       │
└───────────────────────┘
```

**设计要点：**
- 数值使用 `glucoseCallout` 字体（或更大）+ 语义颜色
- 背景使用系统 Widget 默认背景（自动适配 Light/Dark）
- 内边距 16pt
- 信息密度极低，一眼可读

### 7.2 中号 Widget（SystemMedium）

显示最新读数 + 最近 7 天的迷你趋势折线。

```
┌─────────────────────────────────────────┐
│                                         │
│  最新血糖           7日趋势              │
│                                         │
│    5.6             📈[迷你折线图]         │
│   mmol/L                                │
│                                         │
│  早餐前 · 20分钟前                        │
│                                         │
└─────────────────────────────────────────┘
```

**设计要点：**
- 左侧占 40% 宽度：最新读数信息
- 右侧占 60% 宽度：迷你趋势折线图
- 折线图不显示坐标轴，仅绘制曲线和目标范围背景带
- 折线图使用 Swift Charts 的简化配置

### 7.3 锁屏 Widget（AccessoryCircular）

圆形进度环显示今日 TIR（达标率）。

```
    ┌─────┐
   ╱       ╲
  │   78%   │    ← TIR 百分比
  │   TIR   │    ← 标签
   ╲       ╱
    └─────┘
```

**设计要点：**
- 使用 `Gauge` 组件的 `.accessoryCircular` 样式
- 进度颜色：按 TIR 值分段（>70% 绿色，50-70% 黄色，<50% 红色）
- 中心显示百分比数值
- 底部显示 "TIR" 标签

```swift
struct LockScreenWidget: View {
    let entry: GlucoseWidgetEntry

    var body: some View {
        Gauge(value: entry.tirValue, in: 0...100) {
            Text("TIR")
        } currentValueLabel: {
            Text("\(Int(entry.tirValue))%")
                .font(.system(.body, design: .rounded, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}
```

### 7.4 Widget 交互

- 点击任何 Widget 打开 App 的首页
- 中号 Widget 配置深链接 (Deep Link)：点击左侧打开首页，点击右侧打开趋势页

```swift
// Widget Deep Link
Link(destination: URL(string: "xuetangjilu://trend")!) {
    // 趋势图区域
}
```

---

## 8. 无障碍设计

### 8.1 VoiceOver 标签规范

每个交互元素必须有清晰、完整的 VoiceOver 标签。

| 元素 | accessibilityLabel | accessibilityHint |
|:-----|:-------------------|:------------------|
| 首页大数值 | "最新血糖 5.6 mmol/L，正常范围，早餐前" | — |
| 录入按钮 (+) | "添加血糖记录" | "双击打开血糖录入键盘" |
| 数字键 "5" | "五" | — |
| 小数点键 "." | "小数点" | — |
| 删除键 "⌫" | "删除" | "双击删除最后一位数字" |
| 保存按钮 | "保存记录 5.6 mmol/L 早餐前" | "双击保存此次血糖记录" |
| 场景标签 "早餐前" | "早餐前，已选中" / "早餐前，未选中" | "双击切换选中状态" |
| 统计卡片 | "平均血糖 6.2 mmol/L，近7天" | — |
| 趋势图 | "血糖趋势图，近7天，最高值 8.2，最低值 4.5，平均 6.2" | "长按可查看单个数据点" |
| 时间轴行 | "12:30 午餐后 血糖 7.2 mmol/L 偏高" | "右划可删除" |

### 8.2 Dynamic Type 适配

所有文字使用 SwiftUI 的动态字体 API，支持系统字体大小调整：

```swift
// 使用系统预设字体样式（自动支持 Dynamic Type）
Text("标题")
    .font(.headline)

// 自定义字体也需包装为可缩放
Text("5.6")
    .font(.system(size: 36, weight: .bold, design: .rounded))
    .dynamicTypeSize(.large ... .accessibility3) // 限制最大缩放
```

**布局适配规则：**

| 字体大小级别 | 首页大数值 | 列表行布局 | 键盘按钮 |
|:-------------|:----------|:----------|:---------|
| Default - XL | 36pt | 水平排列 | 正常高度 60pt |
| XXL - XXXL | 44pt | 水平排列 | 增加高度 70pt |
| Accessibility 1-3 | 56pt | **垂直堆叠** | 增加高度 80pt |
| Accessibility 4-5 | 56pt (封顶) | 垂直堆叠 | 增加高度 90pt |

> 当字体大小达到 Accessibility 级别时，列表行从水平布局切换为垂直堆叠（时间在上、数值在下），避免截断。

### 8.3 高对比度适配

```swift
@Environment(\.colorSchemeContrast) var contrast

// 高对比度模式下增强颜色
var glucoseColor: Color {
    if contrast == .increased {
        return level == .normal ? .green : .red  // 更纯的颜色
    }
    return Color.forGlucoseLevel(level)
}
```

### 8.4 色觉障碍适配

除颜色外，使用**形状**和**文字**作为辅助信息传递手段：

| 血糖状态 | 颜色 | 辅助图标 | 文字 |
|:---------|:-----|:---------|:-----|
| 正常 | 绿色 | `checkmark.circle` | "正常" |
| 偏高 | 黄色/橙色 | `exclamationmark.triangle` | "偏高" |
| 异常 | 红色 | `exclamationmark.circle` | "注意" |

### 8.5 Reduce Transparency 适配

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

// 减少透明度模式下，使用不透明背景
.background(
    reduceTransparency
        ? Color(.systemBackground)
        : Color(.systemBackground).opacity(0.9)
)
```

---

## 9. 页面线框图与布局

### 9.1 首页布局详细尺寸

```
┌─────────────────────────────────────────┐
│                                         │
│ ← 16pt →                    ← 16pt →   │  水平安全边距
│                                         │
│  ┌─────────────────────────────────┐    │
│  │        最新血糖区域               │    │  ← 高度约 140pt
│  │                                 │    │
│  │   数值: 36pt Rounded Bold       │    │
│  │   单位: 12pt Regular            │    │
│  │   标签+时间: 13pt Regular       │    │
│  │                                 │    │
│  │   内边距: 20pt                  │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ← 20pt 区域间距 →                       │
│                                         │
│  ┌────────┐ 8pt ┌────────┐ 8pt ┌────────┐
│  │ 统计卡1 │     │ 统计卡2 │     │ 统计卡3 │  ← 高度 80pt
│  │        │     │        │     │        │
│  │ 内边距  │     │ 内边距  │     │ 内边距  │
│  │ 12pt   │     │ 12pt   │     │ 12pt   │
│  └────────┘     └────────┘     └────────┘
│                                         │
│  ← 20pt 区域间距 →                       │
│                                         │
│  今日记录                        全部 >  │
│  ┌─────────────────────────────────┐    │
│  │ TimelineRow  高度约 56pt         │    │
│  │ 上下内边距 8pt + 左右内边距 16pt   │    │
│  ├─ 分割线 ─────────────────────────┤    │
│  │ TimelineRow                     │    │
│  ├─ 分割线 ─────────────────────────┤    │
│  │ TimelineRow                     │    │
│  ├─ 分割线 ─────────────────────────┤    │
│  │ TimelineRow                     │    │
│  └─────────────────────────────────┘    │
│                                         │
│         ┌────────────┐                  │
│         │  + (56x56) │                  │  ← FAB 浮动按钮
│         │  圆角28pt   │                  │
│         └────────────┘                  │
│          底部距 Tab 16pt                  │
│                                         │
├─ Tab Bar ───────────────────────────────┤
│  [记录]      [趋势]      [设置]          │  高度 49pt (系统标准)
└─────────────────────────────────────────┘
```

### 9.2 录入页布局详细尺寸

```
┌─────────────────────────────────────────┐
│                                         │
│  取消                           备注     │  ← 导航栏 44pt
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  ← 居中 →                               │
│                                         │
│               5.6                       │  ← 56pt Rounded Bold
│              mmol/L                     │  ← 12pt + 8pt 间距
│                                         │
│  ← 20pt 间距 →                           │
│                                         │
│  ┌────────────────────────────────┐     │
│  │ ScrollView 水平滚动              │     │
│  │ [空腹] [早餐前] [早餐后] [...] │     │  ← 标签 高度 36pt
│  │  间距 8pt  内边距 H:12 V:8      │     │
│  └────────────────────────────────┘     │
│                                         │
│  2026年2月12日 12:30                    │  ← 13pt secondary
│                                         │
│  ← 12pt 间距 →                           │
│                                         │
├─ 键盘区域 ──────────────────────────────┤
│                                         │
│  水平内边距: 16pt                         │
│  按键间距: 10pt (水平+垂直)               │
│  按键高度: 60pt                          │
│  总高度: 4行 × 60pt + 3 × 10pt = 270pt  │
│                                         │
│  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │  1   │  │  2   │  │  3   │          │
│  │ 60pt │  │ 60pt │  │ 60pt │          │
│  └──────┘  └──────┘  └──────┘          │
│                                         │
│  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │  4   │  │  5   │  │  6   │          │
│  └──────┘  └──────┘  └──────┘          │
│                                         │
│  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │  7   │  │  8   │  │  9   │          │
│  └──────┘  └──────┘  └──────┘          │
│                                         │
│  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │  .   │  │  0   │  │  ⌫   │          │
│  └──────┘  └──────┘  └──────┘          │
│                                         │
│  ← 16pt 间距 →                           │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │          保存记录                │    │  ← 高度 54pt, 圆角 14pt
│  └─────────────────────────────────┘    │
│                                         │
│  ← 底部安全区域 →                         │
└─────────────────────────────────────────┘
```

### 9.3 趋势页布局详细尺寸

```
┌─────────────────────────────────────────┐
│ 趋势                                    │  ← 大标题导航栏
├─────────────────────────────────────────┤
│                                         │
│  ┌──7天──┬──14天──┬──30天──┐            │  ← Segmented Picker
│  └───────┴───────┴────────┘            │     高度 32pt
│                                         │
│  ← 16pt 间距 →                           │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  │       趋势折线图                 │    │  ← 高度 200pt
│  │                                 │    │
│  │  左边距 8pt (Y轴标签)            │    │
│  │  右边距 8pt                      │    │
│  │  底部 24pt (X轴日期标签)          │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ← 20pt 区域间距 →                       │
│                                         │
│  ┌──────────┐ 12pt ┌──────────┐        │
│  │ 平均血糖  │      │ 预估A1C  │        │  ← 高度约 100pt
│  │ eAG      │      │          │        │
│  │ 6.2      │      │ 5.8%     │        │
│  │ mmol/L   │      │          │        │
│  └──────────┘      └──────────┘        │
│                                         │
│  ← 12pt 间距 →                           │
│                                         │
│  ┌──────────┐ 12pt ┌──────────┐        │
│  │ 达标率   │      │ 记录次数  │        │  ← 高度约 100pt
│  │ TIR     │      │          │        │
│  │ 78%     │      │ 28       │        │
│  └──────────┘      └──────────┘        │
│                                         │
│  ← 12pt 间距 →                           │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 波动系数 CV%                     │    │  ← 高度约 70pt
│  │ 22.3%  稳定 ✓                   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  [ 记录 ]    [ 趋势 ]    [ 设置 ]        │
└─────────────────────────────────────────┘
```

### 9.4 响应式布局策略

| 设备 | 屏幕宽度 | 布局调整 |
|:-----|:---------|:---------|
| iPhone SE 3 | 375pt | 统计卡片文字缩小一级，键盘按键高度 54pt |
| iPhone 15 | 393pt | 标准布局（本文档所述） |
| iPhone 15 Plus | 430pt | 统计卡片增加内边距，键盘按键高度 64pt |
| iPhone 15 Pro Max | 430pt | 同上 |
| iPad | 768pt+ | 使用 `NavigationSplitView`，左侧记录流 + 右侧详情/趋势 |

**iPad 适配要点：**
- 首页使用 `NavigationSplitView`（侧边栏 + 详情）
- 录入页使用 `.presentationDetents([.medium])` 半屏 Sheet
- 趋势图可利用更大宽度展示更多数据点
- 键盘区域居中显示，宽度不超过 400pt

---

## 附录

### A. 设计走查清单

在每次设计/开发迭代后，使用以下清单进行走查：

- [ ] **暗色模式**：所有页面在 Dark Mode 下是否正常显示？
- [ ] **Dynamic Type**：使用 Accessibility XXL 字体时，布局是否正常？
- [ ] **VoiceOver**：能否仅通过 VoiceOver 完成完整录入流程？
- [ ] **高对比度**：开启"增强对比度"后，所有文字是否可读？
- [ ] **Reduce Motion**：开启"减少动效"后，无动画卡顿或异常？
- [ ] **横屏**：是否锁定为竖屏？（建议锁定竖屏，简化适配）
- [ ] **小屏设备**：iPhone SE 上布局是否完整？
- [ ] **iPad**：iPad 上布局是否合理利用空间？
- [ ] **空状态**：无数据时，每个页面是否有友好的空状态提示？
- [ ] **错误状态**：HealthKit 权限拒绝时，是否有引导提示？
- [ ] **色觉障碍**：仅看形状和文字（不看颜色），能否区分血糖状态？

### B. 设计资产命名规范

| 类型 | 命名规则 | 示例 |
|:-----|:---------|:-----|
| 颜色 (Assets) | PascalCase | `GlucoseNormal`, `BrandPrimary` |
| SF Symbol | 官方名称 | `sunrise`, `chart.line.uptrend.xyaxis` |
| 视图文件 | PascalCase + View 后缀 | `HomeView.swift`, `RecordInputView.swift` |
| 组件文件 | PascalCase 描述 | `GlucoseValueBadge.swift`, `MinimalKeypad.swift` |

### C. 动效参数速查

| 动画 | 类型 | 时长 | 曲线 |
|:-----|:-----|:-----|:-----|
| 保存成功上浮 | offset + opacity | 0.6s | `.easeOut` |
| Sheet 弹出/关闭 | 系统默认 | ~0.3s | spring |
| 图表范围切换 | 数据过渡 | 0.3s | `.smooth` |
| 标签选中切换 | 背景色过渡 | 0.2s | `.easeInOut` |
| Widget 数据刷新 | 淡入淡出 | 0.3s | `.default` |
