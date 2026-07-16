/// 开发者配置信息 - 集中管理全局常量
class DevConfig {
  DevConfig._();

  // 应用信息
  static const String appName = '股票持仓';
  static const String appVersion = '1.0.0';

  // UI 布局
  static const double dialogWidthRatio = 0.75;

  // 开发者信息
  static const String developerName = 'LI GUOBIN';
  static const String developerEmail = 'dreamylost@outlook.com';
  static const String developerWechat = 'naive_dddd';

  // 设置页 分区标题
  static const String settingsTitle = '设置';
  static const String sectionCurrency = '本地货币';
  static const String sectionStock = '股票设置';
  static const String sectionSync = '数据同步';
  static const String sectionOther = '其他';

  // 股票设置 文案
  static const String keepStockLabel = '平仓后保留持仓';
  static const String syncSettingsLabel = 'iCloud 同步';
  static const String syncItemSettings = '设置';
  static const String syncItemStocks = '股票持仓';
  static const String syncItemRecords = '操作记录';
  static const String syncHelpSettingsDesc = '默认货币、排序方式等应用设置';
  static const String syncHelpStocksDesc = '持仓股票、买入价格、股数等数据';
  static const String syncHelpRecordsDesc = '加仓、减仓、平仓等操作记录';
  static const String syncPrivacyNote =
      '如果不开启同步，数据仅存在本地，无法跨 Apple 设备使用（为保证用户隐私，本 APP 不会存储任何用户数据）';
  static const String keepStockOnLabel = '开启后';
  static const String keepStockOnDesc =
      '平仓时保留股票在列表中，持仓数量和市值变为 0，已实现盈亏保留，历史记录依旧保留';
  static const String keepStockOffLabel = '关闭后';
  static const String keepStockOffDesc = '平仓时删除股票及所有数据（收益曲线不会删），效果等同直接删除股票和操作记录';
  static const String sortLabel = '默认排序';
  static const String sortByProfit = '按盈亏';
  static const String sortByHoldings = '按持仓';
  static const String sortByName = '按代码';
  static const String sortDirectionLabel = '方向';
  static const String sortAscending = '升序';
  static const String sortDescending = '降序';

  // 其他设置 文案
  static const String feedbackLabel = '意见反馈';
  static const String openSourceLabel = '开源软件说明';
  static const String versionLabel = '版本';

  // 反馈提示
  static const String feedbackTitle = '意见反馈';
  static const String feedbackHint = '如有建议或问题，欢迎通过以下方式联系开发者：';
  static const String contactEmail = '邮箱';
  static const String contactWechat = '微信';

  // 开源说明
  static const String openSourceTitle = '开源软件说明';
  static const String openSourceDesc = '本应用使用了以下开源库和数据服务';
  static const String licenseSectionLibs = 'Flutter / Dart 开源库';
  static const String licenseSectionData = '数据服务';

  // 通用按钮
  static const String btnClose = '确定';
  static const String btnCancel = '取消';
  static const String btnDelete = '删除';
  static const String btnConfirm = '确认删除';
  static const String btnAdd = '添加';
  static const String btnAdded = '已添加';
  static const String btnConfirmAdd = '确认添加';
  static const String btnConfirmBuy = '确认加仓';
  static const String btnConfirmSell = '确认减仓';

  // 定时器 / 缓存 / 超时
  static const int refreshInitialDelaySec = 300;
  static const int refreshIntervalSec = 60;
  static const int quoteCacheTTLMin = 15;
  static const int searchCacheTTLMin = 5;
  static const int exchangeRateCacheTTLMin = 24 * 60;
  static const int cooldownDurationMin = 5;
  static const int failureThreshold = 3;
  static const int httpTimeoutSec = 10;
  static const int searchDebounceMs = 1000;

  // Toast 文案
  static const String toastEmailCopied = '邮箱地址';
  static const String toastWechatCopied = '微信号';
  static const String toastClipboardSuffix = '已复制到剪贴板';

  // 首页 文案
  static const String homeTitle = '股票持仓';
  static const String homeSubtitle = '共 {count} 只 · 实时更新';
  static const String homeEmptyTitle = '暂无股票持仓';
  static const String homeEmptySubtitle = '点击右上角 + 添加股票开始投资';
  static const String homeStockHeader = '股票';
  static const String homeHoldingHeader = '持仓';
  static const String homeProfitHeader = '盈亏';

  // 底部 Tab 文案
  static const String tabStock = '股票';
  static const String tabAsset = '资产';
  static const String assetComingSoon = '资产页面正在开发中';
  static const String assetComingSoonDesc = '敬请期待';

  // AssetCard 文案
  static const String assetTotalAssets = '总资产';
  static const String assetTotalCost = '持仓总市值';
  static const String assetTotalProfit = '总盈亏';
  static const String assetTotalDividends = '总股息';
  static const String assetExchangeRate = '汇率';
  static const String assetSelectCurrency = '选择货币';
  static const String assetTotalCostHelp = '每股现价 × 持仓股数';
  static const String assetTotalRealizedPL = '已实现盈亏';
  static const String assetTotalProfitHelp = '持仓总浮盈 + 已实现盈亏';
  static const String assetTotalAssetsHelp = '持仓总市值 + 已平仓总额（累计卖出金额）';
  static const String assetTotalDividendsHelp = '税后总股息 / 总资产';
  static const String sectionFormula = '计算公式';
  static const String assetTotalSellAmount = '已平仓总额';
  static const String assetCostDetailLabel = '持仓总成本';
  static const String assetFloatProfitLabel = '持仓总浮盈';
  static const String assetAfterTaxDividendsLabel = '税后总股息';
  static const String assetDividendRateLabel = '股息率';
  static const String assetPositionRatioLabel = '持仓比例';
  static const String assetPositionRatioHelp = '持仓总市值 / 总资产';

  // StockCard 文案
  static const String stockTotalValue = '总市值';
  static const String stockRecord = '记录';
  static const String stockMore = '更多';
  static const String stockSharesSuffix = '股';
  static const String stockDetailTotalCost = '总成本';
  static const String stockDetailAvgPrice = '持仓均价';
  static const String stockDetailMaxPrice = '最大购买价';
  static const String stockDetailMinPrice = '最低购买价';
  static const String stockDetailBuyCount = '加仓次数';
  static const String stockDetailSellCount = '减仓次数';

  // 操作/记录 文案
  static const String opBuy = '买入';
  static const String opSell = '卖出';
  static const String opAddPosition = '加仓';
  static const String opReducePosition = '减仓';
  static const String opClosePosition = '平仓';
  static const String opOpenPosition = '开仓';
  static const String opDeleteStock = '删除股票';
  static const String opDividend = '派息';
  static const String opMoreActions = '更多操作';
  static const String opConfirmDelete = '确认删除';

  // 编辑对话框 文案
  static const String editPriceHint = '价格（由于开仓有手续费，请输入成本价）';
  static const String editPricePlaceholder = '请输入价格';
  static const String editAddSharesLabel = '加仓股数';
  static const String editReduceSharesLabel = '减仓股数';
  static const String editAddSharesHint = '请输入加仓股数';
  static const String editReduceSharesHint = '请输入减仓股数';
  static const String editInvalidInput = '请输入有效的股数和价格';
  static const String editOverflow = '减仓股数不能超过持股数';
  static const String deleteConfirmContent = '确定要删除 {symbol} ({name}) 吗?';

  // 派息对话框 文案
  static const String dividendTitle = '派息';
  static const String dividendDateLabel = '派息日期';
  static const String dividendAmountLabel = '每股派息金额';
  static const String dividendAmountHint = '请输入每股派息金额';
  static const String dividendTaxRateLabel = '税率';
  static const String dividendConfirm = '确认派息';
  static const String dividendInvalidAmount = '请输入有效的派息金额';
  static const String dividendSuccess = '派息成功';
  static const String dividendEditTitle = '编辑派息记录';
  static const String dividendEditAmountLabel = '每股派息金额';
  static const String dividendEditSharesLabel = '持仓股数';
  static const String dividendEditDateLabel = '派息日期';

  // 搜索对话框 文案
  static const String searchTitle = '添加股票';
  static const String searchHint = '输入股票名称或代码（如 AAPL、腾讯）';
  static const String searchAll = '全部';
  static const String searchMarketUS = '美股';
  static const String searchMarketHK = '港股';
  static const String searchRateLimit = '请求过于频繁，请{secs}秒后再试';
  static const String searchRateLimitShort = '请求过于频繁，请稍后再试';
  static const String searchNotFound = '未找到相关股票';
  static const String searchNotFoundMarket = '未找到相关{market}股票';
  static const String searchFailed = '搜索失败，请重试';
  static const String searchInitHint = '输入名称或代码搜索港股/美股';
  static const String searchInitExample = '如：AAPL、腾讯、00700、TSLA';
  static const String searchAlreadyExists = '{code} 已在持仓中';
  static const String searchAddTitle = '添加 {code}';
  static const String searchStockName = '股票名称';
  static const String searchStockCode = '股票代码';
  static const String searchMarket = '市场';
  static const String searchRealtimePrice = '实时价格';
  static const String searchBuyPrice = '买入价格';
  static const String searchBuyPriceHint = '请输入买入价格';
  static const String searchShares = '持股数量';
  static const String searchSharesHint = '请输入持股数量';
  static const String searchInvalidPrice = '请输入有效的买入价格';
  static const String searchInvalidShares = '请输入有效的持股数量';
  static const String searchQuoteUnavailable = '暂无法获取';

  // 记录对话框 文案
  static const String recordsOpTab = '操作';
  static const String recordsDivTab = '派息';
  static const String recordsEmptyOp = '暂无操作记录';
  static const String recordsEmptyOpHint = '点击"记录"按钮添加第一次操作';
  static const String recordsEmptyDiv = '暂无派息记录';
  static const String recordsEmptyDivHint = '点击更多菜单中的“派息”添加记录';
  static const String profitNoData = '暂无数据';
  static const String recordsDivAmountPerShare = '每股';
  static const String recordsDivShares = '持仓股数';
  static const String recordsDivTotal = '总派息';
  static const String recordsOperationTime = '更新时间';
  static const String recordsOpTotalValue = '总市值';
  static const String recordsOpTotalCost = '总成本';
  static const String recordsDivAfterTax = '税后股息';
  static const String recordsDeleteOpConfirm = '确定删除此条操作记录？';
  static const String recordsDeleteDivConfirm = '确定删除此条派息记录？';
  static const String recordsDeleteHint = '左滑可删除，删除后不可恢复，持仓数据将自动重算，请谨慎操作';
  static const String recordsDivDeleteHint = '左滑可删除，删除后不可恢复，资产数据将自动重算，请谨慎操作';
  static const String recordsFormulaLabel = '计算公式';
  static const String recordsEditTitle = '编辑{desc}';
  static const String recordsEditPrice = '价格';
  static const String recordsEditShares = '股数';

  // 操作结果 文案
  static const String resultCloseSuccess = '平仓成功';
  static const String resultOpenSuccess = '开仓成功';
  static const String resultAddSuccess = '加仓成功';
  static const String resultReduceSuccess = '减仓成功';
  static const String resultDeleteSuccess = '删除成功';
  static const String resultAddStockSuccess = '添加成功';

  // 开源软件 / 数据来源 文案
  static const String licenseDescFlutter = '跨平台 UI 框架';
  static const String licenseDescDart = '编程语言 / 运行时';
  static const String licenseDescCupertino = 'iOS 风格图标集';
  static const String licenseDescIntl = '国际化与日期格式化';
  static const String licenseDescHttp = 'HTTP 网络请求库';
  static const String licenseDescSharedPrefs = '本地键值存储';
  static const String licenseDescUrlLauncher = 'URL 启动 / 邮件调用';
  static const String dataSourceDescEastMoney = '股票搜索 / 代码查询';
  static const String dataSourceDescTencent = '实时股价 / 涨跌幅';
  static const String dataSourceDescExchangeRate = '实时汇率数据';

  // 公式 文案
  static const String formulaDialogSubtitle = '资产卡片中各数据的计算公式';

  // 收益曲线 文案
  static const String profitChartTitle = '收益曲线';
  static const String profitRangeToday = '今天';
  static const String profitRange7d = '7天';
  static const String profitRange30d = '30天';
  static const String profitRange180d = '180天';
  static const String profitRange360d = '360天';

  // 通用后缀
  static const String suffixCount = '次';
  static const String suffixWan = '万';
}
