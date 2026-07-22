class SettingsConfig {
  SettingsConfig._();

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
  static const String syncItemStocks = '持仓';
  static const String syncItemRecords = '操作';
  static const String syncHelpSettingsDesc = '本地货币、排序、手续费等设置';
  static const String syncHelpStocksDesc = '持仓股票的买入价格、持有股数等数据';
  static const String syncHelpRecordsDesc = '建仓、加仓、派息等数据';
  static const String syncPrivacyNote =
      '如果不开启同步，数据仅存在本地，无法跨 Apple 设备使用（为保证用户隐私，本 APP 不会存储任何用户数据）';
  static const String keepStockOnLabel = '开启后';
  static const String keepStockOnDesc =
      '平仓时保留股票在列表中，持仓数量和市值变为 0，已实现盈亏保留，历史记录依旧保留';
  static const String keepStockOffLabel = '关闭后';
  static const String keepStockOffDesc = '平仓时删除股票及所有数据（盈亏曲线除外），效果等同直接删除股票和操作记录';
  static const String sortLabel = '默认排序';
  static const String sortByProfit = '按盈亏';
  static const String sortByHoldings = '按持仓';
  static const String sortByName = '按代码';
  static const String sortByManual = '手动';
  static const String sortByAssetName = '按名称';
  static const String sortByAssetAmount = '按金额';
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

  // 手续费设置 文案
  static const String sectionFee = '交易手续费';
  static const String feeTypeLabel = '默认手续费';
  static const String feeTypePercentage = '按费率';
  static const String feeTypeFixed = '固定金额';
  static const String feeValueLabel = '费率';
  static const String feeValueHint = '如 0.03 表示 0.03%';
  static const String feeAmountLabel = '金额';
  static const String feeAmountHint = '每笔固定手续费';
  static const String feeHelpTitle = '手续费说明';
  static const String feeHelpDesc = '设置在加仓/减仓时自动填入的手续费默认值，可手动修改';
  static const String feeHelpRate = '成交金额 × 费率';
  static const String feeHelpFixed = '每笔交易固定的手续费';

  // 公式
  static const String sectionFormula = '计算公式';
  static const String formulaDialogSubtitle = '资产卡片中各数据的计算公式';

  // 开源软件 / 数据来源 文案
  static const String licenseDescFlutter = '跨平台 UI 框架';
  static const String licenseDescDart = '编程语言 / 运行时';
  static const String licenseDescCupertino = 'iOS 风格图标集';
  static const String licenseDescIntl = '国际化与日期格式化';
  static const String licenseDescHttp = 'HTTP 网络请求库';
  static const String licenseDescSharedPrefs = '本地键值存储';
  static const String licenseDescUrlLauncher = 'URL 启动 / 邮件调用';
  static const String licenseDescPathProvider = '文件系统路径访问';
  static const String licenseDescPackageInfo = '应用版本信息读取';
  static const String licenseDescWorkmanager = '后台定时任务调度';
  static const String dataSourceDescEastMoney = '股票搜索 / 代码查询';
  static const String dataSourceDescTencent = '实时股价 / 涨跌幅';
  static const String dataSourceDescExchangeRate = '实时汇率数据';

  // 数据来源显示名称
  static const String dataSourceNameEastMoney = '东方财富 API';
  static const String dataSourceAuthorEastMoney = '东方财富';
  static const String dataSourceNameTencent = '腾讯股票行情';
  static const String dataSourceAuthorTencent = '腾讯';
}
