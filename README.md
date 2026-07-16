# 股票持仓 (Stock Portfolio)

一款使用 Flutter 开发的个人持仓管理 iOS 应用，支持实时行情、多币种切换、盈亏统计、操作记录追踪等功能，采用 Material 3 暗色主题设计。

## ✨ 功能特性

### 📊 资产总览
- 展示总资产、总市值、总成本、总盈亏（金额 + 百分比）、总股息、持仓比例
- 股息率 = 税后总股息 / 总资产
- 持仓比例 = 持仓总市值 / 总资产
- 点击帮助图标查看明细说明；设置页提供"计算公式"对话框

### 📈 收益曲线
- 展示总收益走势图（每小时后台自动记录快照）
- 支持今天（10 分钟粒度）/ 7 天 / 30 天 / 180 天 / 360 天切换
- 点击/拖动查看各时间点的收益数值和日期标签
- 后台定时刷新（`BGTaskScheduler`），进入/回到前台也触发记录

### 💱 多币种支持
- 支持 CNY / USD / HKD / EUR / GBP / JPY 一键切换
- 自动汇率换算，默认货币持久化保存

### 📈 持仓列表
- 展示股票 Logo、公司名、代码、市值、持仓数量、盈亏
- 点击卡片展开详情：总成本、平均持仓价、最大/最小购买价、买卖次数
- 支持按盈亏、持仓、名称排序

### 🔍 股票搜索与添加
- 支持美股（NASDAQ / NYSE / NYSE Arca）和港股搜索
- 自动识别市场类型，展示实时价格
- 添加时自动创建首笔买入操作记录

### 📝 操作记录
- 买入 / 卖出 / 改价 / 平仓操作记录 Tab 切换
- 左滑删除、点击编辑（修改价格/股数，持仓联动重算）
- 底部弹窗展示，支持下拉关闭
- 删除操作提示安全警告

### ⚙️ 编辑与管理
- **加仓 / 减仓 / 平仓 / 改价** — 自动计算平均成本
- **平仓后保留持仓** — 开关带确认弹窗，开启后平仓保留股票归零数据
- **删除** — 确认弹窗后移除持仓及所有记录

### 🛠 设置页
- 本地货币切换与汇率展示
- 排序方式选择
- 意见反馈（邮箱可唤起邮件客户端，微信一键复制）
- 开源软件说明
- 平仓保留持仓开关
- 计算公式说明（股息率、持仓比例、总盈亏等）

### 🎨 用户体验
- 全局深色 UI，Material 3 设计
- 悬浮加号快捷添加股票（右侧边缘吸附，可纵向拖动）
- 搜索防抖（1000ms）+ API 熔断保护（连续 3 次失败冷却 5 分钟）
- 空状态引导提示

## 📁 项目结构

```
lib/
├── main.dart                          # 入口 + 全局状态管理 + 页面组装
├── config/
│   └── app_config.dart                # 全局常量（文案、配置、时间参数）
├── models/
│   ├── stock_model.dart               # 数据模型（Stock / Record / Dividend / ProfitSnapshot）
│   └── calculator_models.dart         # 计算模型（AssetSummary）
├── services/
│   ├── exchange_rate_service.dart     # 实时汇率（缓存 + 熔断）
│   ├── settings_service.dart          # 用户设置持久化
│   ├── stock_search_service.dart      # 股票搜索（缓存 + 熔断）
│   ├── stock_quote_service.dart       # 行情服务（腾讯 + 东方财富，缓存 + 熔断）
│   └── icloud_storage.dart            # iCloud 同步 + 收益快照持久化
├── utils/
│   ├── center_toast.dart              # 居中 Toast 提示
│   ├── currency_helper.dart           # 汇率换算 / 货币符号
│   ├── logo_cacher.dart               # Logo 图片缓存
│   ├── stock_calculator.dart          # 盈亏 / 均成本 / 资产汇总计算
│   └── circuit_breaker.dart           # API 熔断保护
└── widgets/
    ├── asset_card.dart                # 资产总额卡片（含收益曲线）
    ├── stock_card.dart                # 股票卡片（展开详情）
    ├── records_dialog.dart            # 操作/派息记录底部弹窗
    ├── edit_delete_dialogs.dart       # 加仓/减仓/删除对话框
    ├── search_stock_dialog.dart       # 股票搜索与添加
    ├── settings_page.dart             # 全屏设置页
    └── common/
        ├── app_number_field.dart      # 统一数字输入框
        ├── confirm_delete_dialog.dart # 统一删除确认弹窗
        ├── empty_state_widget.dart    # 统一空状态组件
        ├── info_row_widget.dart       # 统一信息行组件
        ├── profit_chart.dart          # 收益曲线组件（CustomPaint 渲染）
        └── settings_expansion_card.dart # 统一设置折叠卡片
```

## 🛠 技术栈

| 类别     | 技术                         |
|--------|----------------------------|
| 框架     | Flutter (Dart SDK ^3.12.2) |
| 设计     | Material 3                 |
| HTTP   | http                       |
| 本地存储   | shared_preferences         |
| 云存储    | iCloud（云端同步持仓/设置/收益快照）    |
| 国际化    | intl                       |
| 系统调用   | url_launcher（邮件）           |
| 后台任务   | BGTaskScheduler（iOS 原生）     |

## 🚀 快速开始

```bash
# 安装依赖
flutter pub get

# 运行（iOS 模拟器）
open -a Simulator && flutter run

# 真机调试，Xcode 打开 Runner.xcworkspace
open ios/Runner.xcworkspace
# 找到设备ID，设备需要在开发者中心注册，且在Xcode登录开发者账号和创建证书
flutter devices
# 运行（选择设备）
flutter run -d <device_id>

# 代码分析
flutter analyze

# 格式化
dart format lib/
```

## ⚙️ 配置

| 配置项       | 值                   | 说明                                     |
|-----------|---------------------|----------------------------------------|
| 行情刷新间隔    | 60 分钟               | 定时拉取最新价格和汇率                            |
| 行情缓存      | 55 分钟               | 缓存期内不重复请求，略短于刷新间隔                      |
| 首次刷新延迟    | 5 分钟                | 启动后延迟，避免冷启动阻塞                          |
| 搜索防抖      | 1 秒                 | 输入停止后延迟搜索                              |
| API 熔断    | 3 次/5 分钟            | 连续失败后冷却，保护 API 配额                      |
| HTTP 超时   | 10 秒                | 单次请求超时上限                               |
| 数据源       | -                   | 东方财富（搜索）、腾讯行情（价格）、ExchangeRate-API（汇率） |
| Bundle ID | `org.bitlap.assets` |                                        |
