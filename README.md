# 资产管理（iAssets）

一款使用 Flutter 开发的个人资产管理 iOS APP，支持实时行情、多币种切换、盈亏统计、操作记录追踪、**多类型资产管理**等功能，采用 Material 3 暗色主题设计。

已在[App Store](https://apps.apple.com/cn/app/iassets/id6790114856) 上线，欢迎使用。

> 无内购无广告，使用公开 API，不保证严格实时。

## 功能特性

### 股票管理
- **持仓列表** — 展示股票 Logo、公司名、代码、市值、持仓数量、盈亏；点击展开详情（总成本、均价、最大/最小购买价、买卖次数）；支持按盈亏、持仓、名称排序
- **搜索与添加** — 支持美股（NASDAQ / NYSE / NYSE Arca）和港股搜索，自动识别市场类型，展示实时价格，添加时自动创建首笔买入记录
- **操作记录** — 买入/卖出/改价/平仓记录 Tab 切换；左滑删除，点击编辑（价格/股数联动重算）；底部弹窗下拉关闭；删除安全警告
- **编辑与管理** — 加仓/减仓/平仓/改价自动计算平均成本；平仓可保留归零数据；删除确认弹窗移除持仓及所有记录
- **实时行情** — 前台每 60s 定时刷新，下拉手动刷新；搜索防抖（1000ms）+ API 熔断保护（连续 3 次失败冷却 5 分钟）
- **收益曲线** — 多粒度查看收益走势（今天/7天/30天/180天/360天），前台+后台定时记录快照，最多保留一年

### 资产管理
- **资产总览** — 总资产、总市值、总成本、总盈亏（金额+百分比）、总股息、持仓比例一屏展示；股息率 = 税后总股息 / 总资产；持仓比例 = 持仓总市值 / 总资产
- **多类型管理** — 支持**现金**、**定期存款**、**理财/基金**三种资产类型统一管理
- **分组折叠** — 资产按分类分组展示，每个分类可独立折叠/展开
- **拖拽排序** — 分类标题可拖拽调整顺序，同分类内资产可拖拽调整顺序；跨分类操作被拦截并提示
- **公式说明** — 设置页提供"计算公式"对话框，各指标计算方式一目了然

### 设置
- **本地货币** — CNY / USD / HKD / EUR / GBP / JPY 一键切换，实时汇率自动换算，默认货币持久化
- **iCloud 同步** — 本地优先读写，开启后每次修改自动同步到 iCloud，切回前台拉取最新数据合并
- **排序与偏好** — 排序方式（盈亏/持仓/名称）、排序方向（升/降序）、平仓保留持仓开关
- **手续费** — 设置默认手续费（比例或固定金额），加仓/减仓自动填入
- **其他** — 意见反馈（邮箱唤起客户端、微信一键复制）、开源软件说明

## 项目结构

```
lib/
├── main.dart                          # 入口 + 全局状态管理 + 页面组装
├── config/
│   ├── app_config.dart                # 应用级常量 + 市场→币种映射（barrel 导出各子配置）
│   ├── stock_config.dart              # 股票相关常量（卡片、搜索、记录、派息、交易所等）
│   ├── settings_config.dart           # 设置页常量（手续费、排序、公式、开源/数据来源等）
│   ├── asset_config.dart              # 资产模块常量（分类、字段、对话框、默认名称等）
│   └── sort_options.dart              # 排序选项（key -> 显示文案 映射）
├── models/
│   ├── asset_account.dart             # 资产数据模型（AssetBase / Cash / TD / WP）
│   ├── asset_flat_item.dart           # 资产列表扁平化模型（SectionHeader / AssetCardItem）
│   ├── stock_model.dart               # 数据模型（Stock / Record / Dividend / ProfitSnapshot）
│   ├── calculator_models.dart         # 计算模型（AssetSummary）
│   └── settings/
│       └── open_source_lib.dart       # OpenSourceLib 模型 + 开源库/数据来源列表
├── services/
│   ├── exchange_rate_service.dart     # 实时汇率（缓存 + 熔断）
│   ├── settings_service.dart          # 用户设置持久化（文件系统 JSON）
│   ├── stock_search_service.dart      # 股票搜索（缓存 + 熔断）
│   ├── stock_quote_service.dart       # 行情路由（腾讯 + 东方财富）
│   ├── east_money_quote_service.dart  # 东方财富行情实现
│   ├── tencent_quote_service.dart     # 腾讯行情实现
│   ├── circuit_breaker.dart           # API 熔断保护
│   └── icloud_storage.dart            # 本地持久化 + iCloud 同步
├── task/
│   └── profit_task.dart               # WorkManager 后台收益快照任务
├── utils/
│   ├── asset_calculator.dart          # 资产价值计算（换算 / 汇总 / 排序 / 按类型汇总）
│   ├── asset_reorder_util.dart        # 资产拖拽排序纯函数（分类/资产重排）
│   ├── center_toast.dart              # 居中 Toast 提示
│   ├── currency_helper.dart           # 汇率换算 / 货币符号
│   ├── logo_cacher.dart               # Logo 图片缓存
│   └── stock_calculator.dart          # 盈亏 / 均成本 / 资产汇总计算
└── widgets/
    ├── asset/
    │   ├── assets_page.dart           # 资产主页（分组折叠列表 + 拖拽排序）
    │   ├── asset_dialogs.dart         # 资产添加/编辑对话框（现金/定期/理财）
    │   ├── asset_header.dart          # 资产页标题 + 总资产摘要卡片
    │   └── asset_card.dart            # 资产卡片通用框架
    ├── stock_card.dart                # 股票卡片（展开详情）
    ├── records_dialog.dart            # 操作/派息记录底部弹窗
    ├── edit_delete_dialogs.dart       # 加仓/减仓/删除对话框
    ├── search_stock_dialog.dart       # 股票搜索与添加
    ├── settings_page.dart             # 全屏设置页
    └── common/
        ├── app_number_field.dart      # 统一数字输入框
        ├── confirm_delete_dialog.dart # 统一删除确认弹窗
        ├── dialog_utils.dart          # 对话框工具（键盘避让适配等）
        ├── empty_state_widget.dart    # 统一空状态组件
        ├── info_row_widget.dart       # 统一信息行组件
        ├── profit_chart.dart          # 收益曲线组件（CustomPaint 渲染）
        └── settings_expansion_card.dart # 统一设置折叠卡片
```

## 技术栈

| 类别   | 技术                         |
|------|----------------------------|
| 框架   | Flutter (Dart SDK ^3.12.2) |
| 设计   | Material 3                 |
| HTTP | http                       |
| 本地存储 | 文件系统 (JSON)                |
| 云存储  | iCloud（可选同步，读写均走本地）        |
| 后台任务 | workmanager                |
| 国际化  | intl                       |
| 版本信息 | package_info_plus          |
| 系统调用 | url_launcher（邮件）           |

## 快速开始

```bash
# 克隆
git clone https://github.com/bitlap/assets
cd assets

# 配置 Apple Developer Team ID（用于真机调试和签名）
cp ios/Config.example.xcconfig ios/Config.xcconfig
# 编辑 ios/Config.xcconfig，填入你的 Team ID

# 安装依赖
flutter pub get

# 运行（iOS 模拟器）
open -a Simulator && flutter run

# 真机调试
open ios/Runner.xcworkspace
flutter devices            # 查看设备 ID
flutter run -d <device_id>

# 代码分析
flutter analyze

# 格式化
dart format lib/
```

## 贡献

欢迎提交 Issue 和 Pull Request。

### 开发准则

- 保持 `flutter analyze --fatal-infos` 无错误
- 提交前运行 `dart format lib/`
- PR 标题用中文简述改动，描述中英文均可

### PR 流程

1. Fork 并创建特性分支
2. 确保 `flutter analyze` 通过
3. 提交 PR，描述改了什么和为什么
4. 维护者 review 后合并

## 配置

| 配置项       | 值                                       | 说明                                     |
|-----------|-----------------------------------------|----------------------------------------|
| 行情刷新间隔    | 60 秒                                    | 定时拉取最新价格和汇率                            |
| 行情缓存      | 15 分钟                                   | 行情数据缓存有效期                              |
| 汇率缓存      | 24 小时                                   | 汇率缓存有效期                                |
| 搜索缓存      | 5 分钟                                    | 搜索结果缓存有效期                              |
| 首次刷新延迟    | 10 秒                                    | 启动后延迟，避免冷启动阻塞                          |
| 搜索防抖      | 1 秒                                     | 输入停止后延迟搜索                              |
| API 熔断    | 3 次/5 分钟                                | 连续失败后冷却，保护 API 配额                      |
| HTTP 超时   | 15 秒                                    | 单次请求超时上限                               |
| 后台快照间隔    | 10 分钟                                   | WorkManager 定时记录收益快照                   |
| 数据源       | -                                       | 东方财富（搜索）、腾讯行情（价格）、ExchangeRate-API（汇率） |
| Bundle ID | `YOUR_BUNDLE_ID`（如 `org.bitlap.assets`） | 克隆后需替换为自己的 Bundle ID                   |
