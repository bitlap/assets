# 股票持仓 (Stock Portfolio)

一款使用 Flutter 开发的个人股票持仓管理应用，支持多币种切换、盈亏统计、操作记录查看等功能，采用暗色主题设计。

## 功能特性

- **资产总览** — 展示总资产、总盈亏（金额+百分比）、总股息
- **多币种支持** — 支持 CNY / USD / HKD / EUR / GBP / JPY 一键切换，自动汇率换算
- **持仓列表** — 展示每只股票的 Logo、公司名、代码、持仓数量、现价、盈亏情况
- **展开详情** — 点击卡片展开查看平均成本、市盈率、股息率等详细数据
- **操作记录** — 查看买入/卖出历史（Tab 切换 + 分页）
- **派息记录** — 查看股息派发历史
- **编辑/删除** — 修改持股数量或删除持仓
- **暗色主题** — 全局深色 UI 设计，护眼舒适

## 项目结构

```
lib/
├── main.dart                        # 入口文件，状态管理 + 页面组装
├── models/
│   └── stock_model.dart             # 数据模型（StockModel, OperationRecord, DividendRecord）
├── data/
│   └── mock_data.dart               # 模拟数据生成器（后续可替换为真实 API）
├── utils/
│   └── currency_helper.dart         # 汇率换算 / 货币符号工具类
└── widgets/
    ├── asset_card.dart              # 资产总额卡片组件
    ├── stock_card.dart              # 股票卡片组件
    ├── records_dialog.dart          # 操作记录 / 派息记录对话框
    └── edit_delete_dialogs.dart     # 编辑 / 删除 / 更多操作对话框
```

## 技术栈

- **Flutter** (Dart SDK ^3.12.2)
- **Material 3** 设计语言
- **intl** — 数字/货币格式化
- 架构模式：状态管理与 UI 分离，Widget 均为 `StatelessWidget`（纯展示）

## 环境准备

1. 安装 Flutter SDK（建议 3.12+）：
   ```bash
   # macOS / Linux
   git clone https://github.com/flutter/flutter.git -b stable
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. 验证环境：
   ```bash
   flutter doctor
   ```
   确保 Xcode（iOS）或 Android Studio（Android）已正确配置。

## 安装依赖

```bash
flutter pub get
```

## 运行与调试

### iOS 模拟器

```bash
# 启动 iOS 模拟器
open -a Simulator

# 运行应用
flutter run
```

### Android 模拟器

```bash
# 启动 Android 模拟器（需先通过 Android Studio 创建 AVD）
flutter emulators --launch <emulator_id>

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

应用运行中，在终端按 `r` 热重载，按 `R` 热重启，按 `q` 退出。

## 代码分析

```bash
flutter analyze
```

## 构建发布版本

```bash
# iOS
flutter build ios

# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle
```

## 注意事项

- 当前版本使用 **模拟数据**（`lib/data/mock_data.dart`），后续可替换为真实 API 数据源
- 汇率为固定映射值，如需实时汇率请接入第三方 API
- 仅支持 iOS 平台（当前项目配置）
