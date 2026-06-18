# 记账本 (Jizhang)

<div align="center">

一个简洁实用的个人财务记账 Flutter 应用

[![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?style=flat&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-iOS-Windows-lightgrey)](https://flutter.dev)

</div>

## 功能特性

- **多账户管理** — 支持微信、支付宝、银行卡等多个钱包账户，随时调整余额
- **智能记账** — 支出/收入分类记录，收入记账已简化（无需选分类）
- **自定义分类** — 可自由添加主分类和子分类，支持选择图标，满足个性化需求
- **自动汇总预算** — 三级预算体系：子分类预算 → 主分类预算（自动汇总） → 月度总预算（自动汇总）
- **可视化图表** — 手绘柱状图展示年度收支趋势，甜甜圈饼图展示分类支出占比
- **本地存储** — 所有数据存储在设备本地 JSON 文件中，安全隐私
- **预算进度追踪** — 实时显示各类别预算使用情况和剩余金额

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/                      # 数据模型
│   ├── account.dart             # 账户模型
│   ├── budget.dart              # 预算模型
│   ├── category.dart            # 分类模型
│   ├── category_budget.dart     # 分类预算模型
│   └── transaction.dart         # 交易模型
├── database/
│   └── database_helper.dart     # JSON 文件数据库
├── screens/                     # 页面
│   ├── home_screen.dart         # 首页
│   ├── add_transaction_screen.dart  # 记账页面
│   ├── category_budget_screen.dart    # 预算管理
│   ├── account_settings_screen.dart   # 账户设置
│   ├── history_screen.dart            # 历史记录（图表分析）
│   └── transaction_history_screen.dart # 交易记录
├── widgets/                     # 组件
│   ├── account_card.dart        # 账户卡片
│   ├── budget_card.dart         # 每日预算卡片
│   ├── budget_progress_card.dart    # 分类预算进度卡片
│   ├── monthly_overview_card.dart     # 本月概览卡片
│   └── transaction_list.dart    # 交易列表
└── utils/
    └── chart_helpers.dart       # 手绘图表组件（柱状图/饼图）
```

## 预算层级说明

本应用采用自动汇总的三级预算体系：

| 层级 | 说明 | 是否可编辑 |
|------|------|-----------|
| 子分类预算 | 如"早餐"、"午餐"、"打车"等 | 是，在此输入金额 |
| 主分类预算 | 如"餐饮"、"交通" | 否，自动 = 子分类之和 |
| 月度总预算 | 所有主分类之和 | 否，自动 = 主分类之和 |

**使用方式：** 只需在子分类输入框中设置预算金额，上层预算会自动汇总计算。

## 技术栈

- **Flutter** 3.12+ / **Dart** 3.12+
- **本地存储** — JSON 文件（path_provider），无 SQLite / 云端
- **图表** — 纯手绘实现（CustomPainter），零第三方图表库依赖
- **状态管理** — StatefulWidget 本地状态
- **日期格式化** — intl 包

## 快速开始

### 环境要求

- Flutter SDK >= 3.12.0
- Dart SDK >= 3.12.0
- Android Studio / VS Code + Flutter 插件

### 安装

```bash
# 克隆仓库
git clone https://github.com/<your-username>/jizhang.git

# 进入项目
cd jizhang

# 安装依赖
flutter pub get

# 运行（Android 模拟器 / 真机 / Windows）
flutter run
```

### 构建发布

```bash
# 构建 Android APK
flutter build apk --release

# 构建 Android App Bundle（上传 Google Play）
flutter build appbundle --release

# 构建 Windows 桌面应用
flutter build windows --release
```

## 数据说明

- 所有数据存储在设备本地 `jizhang_data/data.json` 文件中
- 首次运行自动生成默认账户（微信、支付宝）和分类体系
- 预算按月独立设置，每月需重新配置
- 自定义分类和预算数据也会持久化存储
- 如需备份，复制 `data.json` 文件即可

## 开源协议

本项目采用 [MIT](LICENSE) 协议开源。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 相关文档

- [用户手册](用户手册.md) — 详细功能说明和使用指南
