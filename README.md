# 股票持仓 (Stock Portfolio)

[![Flutter CI](https://github.com/bitlap/assets/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/assets/actions/workflows/flutter-ci.yml)

一款使用 Flutter 开发的个人股票持仓管理应用，支持实时行情、多币种切换、盈亏统计、操作记录追踪等功能，采用 Material 3 暗色主题设计。

## ✨ 功能特性

### 📊 资产总览
- 展示总资产、总盈亏（金额 + 百分比）、总股息
- 支持汇率展开查看各币种对 USD 的实时汇率
- 下拉刷新实时更新所有数据

### 💱 多币种支持
- 支持 CNY / USD / HKD / EUR / GBP / JPY 一键切换
- 自动汇率换算，所有金额统一显示为目标币种
- 默认货币设置持久化保存

### 📈 持仓列表
- 展示每只股票的 Logo、公司名、代码、持仓数量、现价、盈亏情况
- 点击卡片展开查看平均成本、市盈率、股息率等详细数据
- 支持按股票名称、持仓数量、盈亏金额排序（升序/降序）
- 实时价格刷新（每5分钟自动更新）

### 🔍 股票搜索与添加
- 支持关键词搜索股票（A股/港股/美股）
- 自动识别市场类型和股票代码
- 添加时自动创建首笔买入操作记录

### 📝 操作记录
- 查看完整的买入/卖出历史（Tab 切换）
- 支持分页加载和操作记录删除
- 根据操作记录自动重算持仓成本和盈亏

### 💰 派息记录
- 查看股息派发历史
- 独立的派息记录管理

### ⚙️ 编辑与管理
- **加仓/减仓** — 修改持股数量，自动计算平均成本
- **平仓** — 清空持仓并删除股票
- **删除** — 直接移除持仓记录
- 所有操作均有成功提示反馈

### 🎨 用户体验
- 全局深色 UI 设计，护眼舒适
- Material 3 设计语言，现代化界面
- 流畅的交互动画和状态反馈
- 空状态引导提示

## 📁 项目结构

```
lib/
├── main.dart                        # 入口文件，状态管理 + 页面组装
├── models/
│   └── stock_model.dart             # 数据模型（StockModel, OperationRecord, DividendRecord）
├── data/
│   └── mock_data.dart               # 初始持仓数据（股票列表和操作记录）
├── services/
│   ├── exchange_rate_service.dart   # 汇率服务（实时获取汇率）
│   ├── stock_search_service.dart    # 股票搜索与行情服务
│   └── settings_service.dart        # 用户设置持久化服务
├── utils/
│   ├── currency_helper.dart         # 汇率换算 / 货币符号工具类
│   └── center_toast.dart            # 居中提示组件
└── widgets/
    ├── asset_card.dart              # 资产总额卡片组件
    ├── stock_card.dart              # 股票卡片组件（支持展开详情）
    ├── records_dialog.dart          # 操作记录 / 派息记录对话框
    ├── edit_delete_dialogs.dart     # 编辑 / 删除 / 更多操作对话框
    ├── search_stock_dialog.dart     # 股票搜索与添加对话框
    └── settings_page.dart           # 设置页面（货币选择等）
```

## 🛠 技术栈

- **Flutter** (Dart SDK ^3.12.2)
- **Material 3** 设计语言
- **intl** — 数字/货币格式化
- **http** — HTTP 请求（行情API、汇率API）
- **shared_preferences** — 本地持久化存储
- **架构模式**：状态管理与 UI 分离，Widget 均为 `StatelessWidget`（纯展示）

## 🚀 环境准备

### 1. 安装 Flutter SDK

建议版本 3.12+：

```bash
# macOS / Linux
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Windows
git clone https://github.com/flutter/flutter.git -b stable
set PATH=%PATH%;%cd%\flutter\bin
```

### 2. 验证环境

```bash
flutter doctor
```

确保以下环境已正确配置：
- ✅ Flutter SDK
- ✅ Xcode（iOS 开发）
- ✅ iOS 模拟器或真机

## 📦 安装依赖

```bash
flutter pub get
```

## ▶️ 运行与调试

### iOS 模拟器

```bash
# 启动 iOS 模拟器
open -a Simulator

# 运行应用
flutter run
```

### 连接真机

```bash
# 查看已连接设备
flutter devices

# 指定设备运行
flutter run -d <device_id>
```

### 热重载

应用运行中，在终端按：
- `r` — 热重载（保留状态）
- `R` — 热重启（重置状态）
- `q` — 退出应用

## 🔧 代码分析

```bash
# 静态代码分析
flutter analyze

# 格式化代码
flutter format lib/
```

## ⚙️ 配置说明

### 行情刷新

- 自动刷新间隔：300秒（5分钟）
- 支持下拉手动刷新
- 熔断机制：汇率失败不影响股票行情

## 📋 注意事项

- ⚠️ 仅支持 iOS 平台（当前项目配置）
- ⚠️ 股票行情和汇率依赖外部 API，请确保网络连接正常
- ⚠️ 首次启动会延迟3秒开始刷新数据
