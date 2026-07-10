import 'dart:async';
import 'package:flutter/material.dart';

import 'models/stock_model.dart';
import 'utils/currency_helper.dart';
import 'utils/center_toast.dart';
import 'widgets/asset_card.dart';
import 'widgets/stock_card.dart';
import 'widgets/records_dialog.dart';
import 'widgets/edit_delete_dialogs.dart';
import 'widgets/search_stock_dialog.dart';
import 'widgets/settings_page.dart';
import 'services/stock_search_service.dart';
import 'services/exchange_rate_service.dart';
import 'services/settings_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '股票持仓',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          background: const Color(0xFF0C1117),
          surface: Colors.grey[900]!,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0C1117),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          displayLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const StockPortfolioPage(),
    );
  }
}

/// 股票持仓主页 - 仅负责状态管理和页面组装
class StockPortfolioPage extends StatefulWidget {
  const StockPortfolioPage({super.key});

  @override
  State<StockPortfolioPage> createState() => _StockPortfolioPageState();
}

class _StockPortfolioPageState extends State<StockPortfolioPage> {
  // ========== 状态 ==========
  List<StockModel> stocks = [];
  String selectedCurrency = 'CNY';
  bool _isExchangeRateExpanded = false;
  String? _expandedStockSymbol;
  // 每只股票的操作记录
  final Map<String, List<OperationRecord>> _operationRecords = {};

  // 行情服务实例和定时刷新
  final StockSearchService _searchService = StockSearchService();
  final ExchangeRateService _exchangeRateService = ExchangeRateService();
  Timer? _priceRefreshTimer;

  // ========== 排序状态 ==========
  String _sortColumn = 'profit'; // 'name', 'holdings', 'profit'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    // 加载保存的默认货币
    _loadSavedCurrency();
    // 启动后延迟3秒开始刷新价格和汇率，然后每300秒刷新一次
    _startRefresh();
  }

  /// 从本地存储加载默认货币
  Future<void> _loadSavedCurrency() async {
    final saved = await SettingsService.getDefaultCurrency();
    if (saved != null && mounted) {
      setState(() => selectedCurrency = saved);
    }
  }

  @override
  void dispose() {
    _priceRefreshTimer?.cancel();
    super.dispose();
  }

  /// 启动定时刷新（价格 + 汇率）
  void _startRefresh() {
    // 首次加载后延迟3秒刷新
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _refreshAll();
    });

    // 每300秒刷新一次价格和汇率
    _priceRefreshTimer = Timer.periodic(const Duration(seconds: 300), (_) {
      if (mounted) _refreshAll();
    });
  }

  /// 刷新汇率（使用独立熔断，失败不影响股票行情）
  Future<void> _refreshExchangeRates() async {
    final rates = await _exchangeRateService.fetchRates();
    if (rates != null && mounted) {
      setState(() {
        CurrencyHelper.updateRates(rates);
      });
    }
  }

  /// 统一刷新：先更新汇率，再更新股票价格
  Future<void> _refreshAll() async {
    await _refreshExchangeRates();
    await _refreshAllPrices();
  }

  /// 刷新所有持仓股票的实时价格
  Future<void> _refreshAllPrices() async {
    if (stocks.isEmpty) return;

    for (final stock in stocks) {
      try {
        // 构建搜索对象用于查询行情
        final searchResult = StockSearchResult(
          code: stock.symbol,
          name: stock.companyName,
          market: stock.marketType,
          secid:
              stock.secid ??
              '${stock.marketType == '美股' ? '105' : '116'}.${stock.symbol}',
        );

        // 获取最新行情
        final quote = await _searchService.getStockQuote(searchResult);

        if (quote != null && mounted) {
          setState(() {
            // 更新当前价格和涨跌幅
            final index = stocks.indexWhere((s) => s.symbol == stock.symbol);
            if (index != -1) {
              stocks[index] = stock.copyWith(
                currentPrice: quote.currentPrice,
                profitLossPercent: quote.changePercent,
                changePercent: quote.changePercent,
              );
              debugPrint('开始刷新股票价格 ${stock.companyName}:${stock.currentPrice}');
              // 重新计算盈亏金额（基于新的当前价格）
              _recalculateStockFromRecords(stock.symbol);
            }
          });
        }
      } catch (e) {
        debugPrint('刷新 ${stock.symbol} 价格失败: $e');
      }
    }

    debugPrint('价格刷新完成');
  }

  /// 根据操作记录重算单只股票的股数、总金额、盈亏
  void _recalculateStockFromRecords(String symbol) {
    final records = _operationRecords[symbol];
    // 如果没有操作记录，跳过重算（保持股票原始数据）
    if (records == null || records.isEmpty) return;
    final stockIndex = stocks.indexWhere((s) => s.symbol == symbol);
    if (stockIndex == -1) return;
    final stock = stocks[stockIndex];

    // ========== 第一步：计算当前持仓和交易总额 ==========
    double currentShares = 0; // 当前持股数
    double totalBuyAmount = 0.0; // 所有买入操作的总金额
    double totalSellAmount = 0.0; // 所有卖出操作的总金额

    for (final record in records) {
      if (record.type == '买入') {
        currentShares += record.shares;
        totalBuyAmount += record.amount * record.shares;
      } else if (record.type == '卖出') {
        currentShares -= record.shares;
        totalSellAmount += record.amount * record.shares;
      }
    }

    // 防止浮点误差导致负数
    if (currentShares < 0) currentShares = 0;

    // ========== 第二步：计算当前总持仓金额 ==========
    // 核心公式：当前总金额 = 当前价格 × 当前数量
    final totalValue = stock.currentPrice * currentShares;

    // 如果当前没有持股，直接设为0
    if (currentShares == 0) {
      stocks[stockIndex] = stock.copyWith(
        shares: 0,
        totalValue: 0,
        profitLossAmount: 0,
        profitLossPercent: 0,
        isPositive: true,
      );
      return;
    }

    // ========== 第三步：计算净成本 ==========
    // 净成本 = 总买入金额 - 总卖出金额
    // 解释：买入时花出去的钱 - 卖出时收回来的钱 = 当前持仓的实际成本
    final netCost = totalBuyAmount - totalSellAmount;
    debugPrint('刷新股票持仓 ${stock.companyName}，总价值:${totalValue} 成本:${netCost}');
    // ========== 第四步：计算盈亏 ==========
    // 盈亏 = 当前总金额 - 净成本
    final profitLossAmount = totalValue - netCost;

    // 平均成本价 = 净成本 ÷ 当前股数
    final avgCostPerShare = netCost / currentShares;

    // 盈亏百分比 = (当前价 - 平均成本价) ÷ 平均成本价 × 100%
    final double profitLossPercent = avgCostPerShare > 0
        ? ((stock.currentPrice - avgCostPerShare) / avgCostPerShare * 100.0)
        : 0.0;

    // 判断盈亏方向：操作记录总额 > 当前总额 = 亏本（绿色），否则 = 盈利（红色）
    final bool isPositive = netCost <= totalValue;

    // ========== 第五步：更新股票数据 ==========
    stocks[stockIndex] = stock.copyWith(
      shares: currentShares,
      totalValue: totalValue,
      profitLossAmount: profitLossAmount,
      profitLossPercent: profitLossPercent,
      isPositive: isPositive, // 使用新的判断逻辑：操作记录总额 <= 当前总额
    );
  }

  // ========== 计算属性 ==========
  /// 将股票自身币种金额转换为目标币种
  double _convertToSelected(double amount, String stockCurrency) {
    final amountInUSD = amount / CurrencyHelper.getExchangeRate(stockCurrency);
    return amountInUSD * CurrencyHelper.getExchangeRate(selectedCurrency);
  }

  double get totalAssets => stocks.fold(
    0.0,
    (sum, stock) => sum + _convertToSelected(stock.totalValue, stock.currency),
  );
  double get totalProfit => stocks.fold(
    0.0,
    (sum, stock) =>
        sum + _convertToSelected(stock.profitLossAmount, stock.currency),
  );
  double get totalDividends => 0;
  double get totalProfitPercent =>
      totalAssets > 0 ? (totalProfit / (totalAssets - totalProfit) * 100) : 0.0;
  double get exchangeRate => CurrencyHelper.getExchangeRate(selectedCurrency);

  // ========== 排序 ==========
  /// 排序规则：
  /// 股票列：按名称，次级无
  /// 持仓列：按股数，相同则按股价
  /// 盈亏列：按盈亏金额（含负数亏损），相同则按总价值
  List<StockModel> get _sortedStocks {
    final sorted = List<StockModel>.from(stocks);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'name':
          cmp = a.companyName.compareTo(b.companyName);
          break;
        case 'holdings':
          cmp = a.shares.compareTo(b.shares);
          if (cmp == 0) {
            // 股价币种不同，转换为统一币种再比较
            final priceA = _convertToSelected(a.currentPrice, a.currency);
            final priceB = _convertToSelected(b.currentPrice, b.currency);
            cmp = priceA.compareTo(priceB);
          }
          break;
        case 'profit':
          // 盈亏金额（含负数亏损），转换为统一币种再比较
          final plA = _convertToSelected(a.profitLossAmount, a.currency);
          final plB = _convertToSelected(b.profitLossAmount, b.currency);
          cmp = plA.compareTo(plB);
          if (cmp == 0) {
            final valA = _convertToSelected(a.totalValue, a.currency);
            final valB = _convertToSelected(b.totalValue, b.currency);
            cmp = valA.compareTo(valB);
          }
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  void _onColumnTap(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
    });
  }

  Widget _buildSortIndicator(String column, {bool alignRight = false}) {
    final isActive = _sortColumn == column;
    return SizedBox(
      width: 14,
      child: isActive
          ? Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: const Color(0xFF5B9CF6),
            )
          : null,
    );
  }

  // ========== 事件处理 ==========
  void _onCurrencyChanged(String newCurrency) {
    setState(() => selectedCurrency = newCurrency);
    // 持久化保存选择的货币
    SettingsService.setDefaultCurrency(newCurrency);
  }

  void _onStockTap(StockModel stock) {
    setState(() {
      _expandedStockSymbol = _expandedStockSymbol == stock.symbol
          ? null
          : stock.symbol;
    });
  }

  void _onEditStock(
    StockModel updatedStock,
    OperationRecord? record,
    bool isClosed,
  ) {
    setState(() {
      if (isClosed) {
        // 平仓：删除股票
        stocks.removeWhere((s) => s.symbol == updatedStock.symbol);
      } else {
        // 加仓或减仓：更新股票
        final index = stocks.indexWhere((s) => s.symbol == updatedStock.symbol);
        if (index != -1) stocks[index] = updatedStock;
      }
      // 添加操作记录
      if (record != null) {
        _operationRecords.putIfAbsent(updatedStock.symbol, () => []);
        _operationRecords[updatedStock.symbol]!.insert(0, record);
        // 加仓/减仓后重新计算持仓数据
        _recalculateStockFromRecords(updatedStock.symbol);
      }
    });
    Navigator.pop(context);
    if (record != null) {
      String action;
      if (isClosed) {
        action = '平仓';
      } else if (_operationRecords[updatedStock.symbol]?.length == 1) {
        action = '开仓';
      } else {
        action = record.type == '买入' ? '加仓' : '减仓';
      }
      CenterToast.success(context, '$action成功');
    }
  }

  void _onDeleteStock(StockModel stock) {
    setState(() => stocks.remove(stock));
    CenterToast.success(context, '删除成功');
  }

  void _showRecordsDialog(StockModel stock) {
    final records = _operationRecords[stock.symbol] ?? [];
    showDialog(
      context: context,
      builder: (_) => RecordsDialog(
        stock: stock,
        operationRecords: records,
        onDeleteOperationRecord: (symbol, index) {
          setState(() {
            final list = _operationRecords[symbol];
            if (list != null && index < list.length) {
              list.removeAt(index);
            }
            _recalculateStockFromRecords(symbol);
          });
        },
        onDeleteDividendRecord: (symbol, index) {
          // 派息记录目前为模拟数据，暂无需同步状态
        },
      ),
    );
  }

  void _showMoreOptions(StockModel stock) {
    showDialog(
      context: context,
      builder: (_) => MoreOptionsDialog(
        stock: stock,
        onAdd: () => _showEditDialog(stock, isAdd: true),
        onReduce: () => _showEditDialog(stock, isAdd: false),
        onDelete: () => _showDeleteDialog(stock),
      ),
    );
  }

  void _showEditDialog(StockModel stock, {required bool isAdd}) {
    final records = _operationRecords[stock.symbol] ?? [];
    showDialog(
      context: context,
      builder: (_) => EditStockDialog(
        stock: stock,
        onSave: _onEditStock,
        isAdd: isAdd,
        operationRecords: records,
      ),
    );
  }

  void _showDeleteDialog(StockModel stock) {
    showDialog(
      context: context,
      builder: (_) => DeleteStockDialog(
        stock: stock,
        onDelete: () => _onDeleteStock(stock),
      ),
    );
  }

  void _showSearchStockDialog() {
    final existingSymbols = stocks.map((s) => s.symbol).toSet();
    showDialog(
      context: context,
      builder: (_) => SearchStockDialog(
        existingSymbols: existingSymbols,
        onStockAdded: (newStock, buyRecord) {
          setState(() {
            stocks.add(newStock);
            _operationRecords[newStock.symbol] = [buyRecord];
            // 根据操作记录重算持仓数据
            _recalculateStockFromRecords(newStock.symbol);
          });
          CenterToast.success(context, '添加成功');
        },
      ),
    );
  }

  /// 打开全屏设置页面
  void _showSettingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          currentCurrency: selectedCurrency,
          onCurrencyChanged: _onCurrencyChanged,
        ),
      ),
    );
  }

  // ========== 页面组装 ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1117),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          color: Colors.blue,
          backgroundColor: const Color(0xFF1A1F26),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                AssetCard(
                  selectedCurrency: selectedCurrency,
                  totalAssets: totalAssets,
                  totalProfit: totalProfit,
                  totalProfitPercent: totalProfitPercent,
                  totalDividends: totalDividends,
                  exchangeRate: exchangeRate,
                  isExchangeRateExpanded: _isExchangeRateExpanded,
                  onToggleExchangeRate: () => setState(
                    () => _isExchangeRateExpanded = !_isExchangeRateExpanded,
                  ),
                  onCurrencyChanged: _onCurrencyChanged,
                ),
                const SizedBox(height: 10),
                _buildStockListHeader(),
                const SizedBox(height: 6),
                if (_sortedStocks.isEmpty) ...[
                  // 空状态：暂无股票
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 64,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无股票持仓',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击右上角 + 添加股票开始投资',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sortedStocks.length,
                    itemBuilder: (context, index) {
                      final stock = _sortedStocks[index];
                      return StockCard(
                        stock: stock,
                        isExpanded: _expandedStockSymbol == stock.symbol,
                        onTap: () => _onStockTap(stock),
                        onRecordTap: () => _showRecordsDialog(stock),
                        onMoreTap: () => _showMoreOptions(stock),
                        operationRecords: _operationRecords[stock.symbol] ?? [],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 顶部标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '股票持仓',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '共 ${stocks.length} 只 · 实时更新',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                  height: 1.2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _showSearchStockDialog,
                icon: const Icon(Icons.add, color: Color(0xFF5B9CF6), size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                onPressed: _showSettingsPage,
                icon: const Icon(Icons.settings, color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 股票列表标题（可点击排序）
  Widget _buildStockListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _onColumnTap('name'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '股票',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      height: 1.2,
                    ),
                  ),
                  _buildSortIndicator('name'),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _onColumnTap('holdings'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 14), // 与下方内容对齐
                  Text(
                    '持仓',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      height: 1.2,
                    ),
                  ),
                  _buildSortIndicator('holdings'),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _onColumnTap('profit'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '盈亏',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      height: 1.2,
                    ),
                  ),
                  _buildSortIndicator('profit', alignRight: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
