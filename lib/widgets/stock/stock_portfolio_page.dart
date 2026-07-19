import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/stock_model.dart';
import '../../models/stock_search_models.dart';
import '../../models/calculator_models.dart';
import '../../config/app_config.dart';
import '../../utils/currency_helper.dart';
import '../../utils/center_toast.dart';
import '../../utils/stock_calculator.dart';
import '../../services/stock_quote_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/settings_service.dart';
import '../../services/icloud_storage.dart';
import 'stock_card.dart';
import 'records_dialog.dart';
import 'edit_delete_dialogs.dart';
import 'search_stock_dialog.dart';
import 'stock_summary_card.dart';
import '../settings_page.dart';
import '../common/empty_state_widget.dart';

/// 股票持仓主页 - 仅负责状态管理和页面组装
class StockPortfolioPage extends StatefulWidget {
  const StockPortfolioPage({super.key});

  @override
  StockPortfolioPageState createState() => StockPortfolioPageState();
}

class StockPortfolioPageState extends State<StockPortfolioPage>
    with WidgetsBindingObserver {
  // 状态
  List<StockModel> stocks = [];
  String selectedCurrency = DevConfig.defaultCurrency;
  String? _expandedStockSymbol;
  // 每只股票的操作记录
  final Map<String, List<OperationRecord>> _operationRecords = {};
  // 每只股票的派息记录
  final Map<String, List<DividendRecord>> _dividendRecords = {};

  // 行情服务实例和定时刷新
  final StockQuoteService _quoteService = StockQuoteService();
  final ExchangeRateService _exchangeRateService = ExchangeRateService();
  Timer? _priceRefreshTimer;
  bool _isForeground = true;

  /// 平仓后是否保留持仓股票（若选择删除，则清空数据，效果等同直接删除股票）
  bool _keepStockAfterClose = false;

  // 排序状态
  String _sortColumn = 'profit'; // 'name', 'holdings', 'profit'
  bool _sortAscending = false;

  // 悬浮按钮位置
  double _fabY = 0;
  bool _fabInitialized = false;

  /// 数据是否有变更（脏标记），用于延迟写入 iCloud
  bool _dataDirty = false;

  /// 防抖定时器：修改后延迟自动异步同步到 iCloud
  Timer? _syncTimer;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 同步配置
    _syncSettingsFromCloud();
    _syncStockData();
    // 加载保存的默认货币
    _loadSavedCurrency();
    // 加载平仓设置
    _loadKeepStockSetting();
    // 加载排序设置
    _loadSortSettings();
    // 启动后延迟刷新价格和汇率，然后定时刷新一次
    _startRefresh();
  }

  /// 从本地存储加载默认货币
  Future<void> _loadSavedCurrency() async {
    final saved = await SettingsService.getDefaultCurrency();
    if (saved != null && mounted) {
      setState(() => selectedCurrency = saved);
    }
  }

  /// 加载平仓后是否保留持仓股票的设置
  Future<void> _loadKeepStockSetting() async {
    final keep = await SettingsService.getKeepStockAfterClose();
    if (mounted) setState(() => _keepStockAfterClose = keep);
  }

  /// 加载排序设置
  Future<void> _loadSortSettings() async {
    final column = await SettingsService.getSortColumn();
    final ascending = await SettingsService.getSortAscending();
    if (mounted) {
      setState(() {
        _sortColumn = column;
        _sortAscending = ascending;
      });
    }
  }

  /// 从本地加载股票和记录，并尝试从 iCloud 拉取最新
  Future<void> _syncStockData() async {
    final data = await IcloudStorage.loadStocks();
    if (!mounted) return;
    setState(() {
      stocks = data.$1;
      _operationRecords
        ..clear()
        ..addAll(data.$2);
      _dividendRecords
        ..clear()
        ..addAll(data.$3);
    });
  }

  /// 标记数据已变更，并启动防抖定时器异步同步到 iCloud
  void _markDirty() {
    _dataDirty = true;
    // 取消上一次的定时器，重新计时（防抖）
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 3), () {
      if (_dataDirty && mounted) {
        _flushToCloud();
      }
    });
  }

  /// 真正写入本地（同步到 iCloud 由内部按配置处理）
  Future<void> _flushToCloud() async {
    _syncTimer?.cancel();
    if (!_dataDirty) return;
    await Future.wait([
      IcloudStorage.saveStocks(stocks, _operationRecords, _dividendRecords),
      IcloudStorage.saveSettings(),
    ]);
    _dataDirty = false;
  }

  /// 从 iCloud 下载设置覆盖本地
  Future<void> _syncSettingsFromCloud() async {
    await IcloudStorage.loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _priceRefreshTimer?.cancel();
    super.dispose();
  }

  /// 应用生命周期监听：进入后台时写入 iCloud，回到前台时拉取
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isForeground = false;
      if (_dataDirty) _flushToCloud();
      unawaited(IcloudStorage.recordProfitIfNeeded(totalProfit));
    } else if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      unawaited(_onResumed());
    }
  }

  Future<void> _onResumed() async {
    await IcloudStorage.recordProfitIfNeeded(totalProfit);
    unawaited(IcloudStorage.syncProfitToCloud());
    if (mounted) await _syncStockData();
  }

  /// 启动定时刷新（价格 + 汇率）
  void _startRefresh() {
    // 首次加载后延迟刷新
    Future.delayed(Duration(seconds: DevConfig.refreshInitialDelaySec), () {
      if (mounted) _refreshAll();
    });

    // 定时刷新价格和汇率
    _priceRefreshTimer = Timer.periodic(
      Duration(seconds: DevConfig.refreshIntervalSec),
      (_) {
        if (mounted) _refreshAll();
      },
    );
  }

  /// 拉取汇率但不触发 UI 重建
  Future<void> _fetchExchangeRatesWithoutRebuild() async {
    debugPrint('[${DateTime.now().toString().substring(11, 19)}][首页] 刷新汇率...');
    final rates = await _exchangeRateService.fetchRates();
    if (rates != null) {
      CurrencyHelper.updateRates(rates);
      debugPrint('[${DateTime.now().toString().substring(11, 19)}][首页] 汇率拉取完成');
    } else {
      debugPrint(
        '[${DateTime.now().toString().substring(11, 19)}][首页] 汇率刷新无更新',
      );
    }
  }

  /// 统一刷新：先更新汇率，再更新股票价格，同时从 iCloud 拉取最新数据
  Future<void> _refreshAll() async {
    if (!_isForeground) return;
    _collapseExpandedStock();
    debugPrint(
      '[${DateTime.now().toString().substring(11, 19)}][首页] 开始全量刷新...',
    );
    await _syncSettingsFromCloud();

    // 优先推送本地脏数据到云，再拉取（避免本地编辑被旧云数据覆盖）
    if (_dataDirty) {
      await _flushToCloud();
    }

    // 依次拉取汇率、行情，并同步 iCloud 数据到本地
    await _fetchExchangeRatesWithoutRebuild();
    final quotes = stocks.isEmpty
        ? <String, StockQuote?>{}
        : await _fetchQuotesWithoutRebuild();
    final data = await IcloudStorage.loadStocks();
    if (!mounted) return;

    // 先记录收益快照，再 setState 让 chart 能读到最新数据
    await IcloudStorage.recordProfitIfNeeded(totalProfit);

    if (!mounted) return;

    // 合并为一次 setState，避免列表多次重建导致 LOGO 缓存日志重复打印
    setState(() {
      stocks = data.$1;
      _operationRecords
        ..clear()
        ..addAll(data.$2);
      _dividendRecords
        ..clear()
        ..addAll(data.$3);
      _applyQuotes(stocks, quotes);
    });
    _markDirty();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    debugPrint('[${DateTime.now().toString().substring(11, 19)}][首页] 全量刷新完成');
  }

  /// 拉取行情但不触发 UI 重建
  Future<Map<String, StockQuote?>> _fetchQuotesWithoutRebuild() async {
    debugPrint(
      '[${DateTime.now().toString().substring(11, 19)}][首页] 开始刷新行情: ${stocks.length}只股票',
    );
    final searchResults = stocks
        .map(
          (stock) => StockSearchResult(
            code: stock.symbol,
            name: stock.companyName,
            market: stock.marketType,
            secid:
                stock.secid ??
                '${stock.marketType == DevConfig.searchMarketUS ? '105' : '116'}.${stock.symbol}',
          ),
        )
        .toList();
    final quotes = await _quoteService.getStockQuotesBatch(searchResults);
    debugPrint('[${DateTime.now().toString().substring(11, 19)}][首页] 行情拉取完成');
    return quotes;
  }

  /// 将行情数据应用到股票列表（在 setState 内调用）
  void _applyQuotes(
    List<StockModel> stockList,
    Map<String, StockQuote?> quotes,
  ) {
    for (final stock in stockList) {
      final secid =
          stock.secid ??
          '${stock.marketType == DevConfig.searchMarketUS ? '105' : '116'}.${stock.symbol}';
      final quote = quotes[secid];
      if (quote != null) {
        final index = stockList.indexWhere((s) => s.symbol == stock.symbol);
        if (index != -1) {
          stockList[index] = stock.copyWith(
            currentPrice: quote.currentPrice,
            changePercent: quote.changePercent,
          );
          _recalculateStockFromRecords(stock.symbol);
        }
      }
    }
  }

  /// 根据操作记录重算单只股票的股数、总金额、盈亏
  void _recalculateStockFromRecords(String symbol) {
    final records = _operationRecords[symbol];
    final stockIndex = stocks.indexWhere((s) => s.symbol == symbol);
    if (stockIndex == -1) return;

    if (records == null || records.isEmpty) {
      // 记录被删空，归零持仓数据
      stocks[stockIndex] = stocks[stockIndex].copyWith(
        shares: 0,
        totalValue: 0,
        profitLossAmount: 0,
        profitLossPercent: 0,
        isPositive: true,
      );
      return;
    }

    final updated = StockCalculator.recalculateFromRecords(
      stocks[stockIndex],
      records,
    );
    stocks[stockIndex] = updated;
  }

  // 计算属性
  AssetSummary get _assetSummary => StockCalculator.calculateAssetSummary(
    stocks,
    _operationRecords,
    _dividendRecords,
    selectedCurrency,
  );
  double get totalAssets => _assetSummary.totalAssets;
  double get totalMarketValue => _assetSummary.totalMarketValue;
  double get totalCost => _assetSummary.totalCost;
  double get totalProfit => _assetSummary.totalProfit;
  double get totalAfterTaxDividends => _assetSummary.totalAfterTaxDividends;
  double get totalSellAmount => _assetSummary.totalSellAmount;
  double get totalRealizedPL => _assetSummary.totalRealizedPL;
  double get totalProfitPercent => _assetSummary.totalProfitPercent;
  double get exchangeRate => CurrencyHelper.getExchangeRate(selectedCurrency);

  // 排序
  /// 排序规则：
  /// 股票列：按股票代码，次级无
  /// 持仓列：按持仓价值（价格×股数），相同则按股数
  /// 盈亏列：按盈亏金额（含负数亏损），相同则按总价值
  List<StockModel> get _sortedStocks {
    final sorted = List<StockModel>.from(stocks);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'name':
          cmp = a.symbol.compareTo(b.symbol);
          break;
        case 'holdings':
          // 按持仓价值（价格×股数）排序，转换为统一币种
          final valueA =
              CurrencyHelper.convertCurrency(
                a.currentPrice * a.shares,
                a.currency,
                selectedCurrency,
              ).compareTo(
                CurrencyHelper.convertCurrency(
                  b.currentPrice * b.shares,
                  b.currency,
                  selectedCurrency,
                ),
              );
          cmp = valueA;
          if (cmp == 0) {
            // 持仓价值相同，按股数排序
            cmp = a.shares.compareTo(b.shares);
          }
          break;
        case 'profit':
          // 盈亏金额（含负数亏损），转换为统一币种再比较
          final plA = CurrencyHelper.convertCurrency(
            a.profitLossAmount,
            a.currency,
            selectedCurrency,
          );
          final plB = CurrencyHelper.convertCurrency(
            b.profitLossAmount,
            b.currency,
            selectedCurrency,
          );
          cmp = plA.compareTo(plB);
          if (cmp == 0) {
            final valA = CurrencyHelper.convertCurrency(
              a.totalValue,
              a.currency,
              selectedCurrency,
            );
            final valB = CurrencyHelper.convertCurrency(
              b.totalValue,
              b.currency,
              selectedCurrency,
            );
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
    _collapseExpandedStock();
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

  // 事件处理
  void _onStockTap(StockModel stock) {
    setState(() {
      _expandedStockSymbol = _expandedStockSymbol == stock.symbol
          ? null
          : stock.symbol;
    });
  }

  /// 收缩已展开的股票卡片（仅收缩，不切换）
  void _collapseExpandedStock() {
    if (_expandedStockSymbol != null) {
      setState(() => _expandedStockSymbol = null);
    }
  }

  void _onEditStock(
    StockModel updatedStock,
    OperationRecord? record,
    bool isClosed,
  ) {
    setState(() {
      if (isClosed) {
        // 平仓后保留股票记录，只清持仓数量，保留已实现盈亏
        final index = stocks.indexWhere((s) => s.symbol == updatedStock.symbol);
        if (index == -1) {
          stocks.add(updatedStock.copyWith(shares: 0, totalValue: 0));
        }
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
    _markDirty();
    Navigator.pop(context);
    if (record != null) {
      String action;
      if (isClosed) {
        action = DevConfig.opClosePosition;
      } else if (_operationRecords[updatedStock.symbol]?.length == 1) {
        action = DevConfig.opOpenPosition;
      } else {
        action = record.type == DevConfig.opBuy
            ? DevConfig.opAddPosition
            : DevConfig.opReducePosition;
      }
      CenterToast.success(
        context,
        '${action}${DevConfig.resultAddSuccess.replaceAll(DevConfig.opAddPosition, '')}',
      );
    }
  }

  void _onDeleteStock(StockModel stock) {
    setState(() {
      stocks.remove(stock);
      _operationRecords.remove(stock.symbol);
      _dividendRecords.remove(stock.symbol);
    });
    _markDirty();
    CenterToast.success(context, DevConfig.resultDeleteSuccess);
  }

  void _showRecordsDialog(StockModel stock) {
    final records = _operationRecords[stock.symbol] ?? [];
    final divRecords = _dividendRecords[stock.symbol] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => RecordsDialog(
          stock: stock,
          operationRecords: records,
          dividendRecords: divRecords,
          scrollController: scrollController,
          onDeleteOperationRecord: (symbol, index) {
            setState(() {
              final list = _operationRecords[symbol];
              if (list != null && index < list.length) {
                list.removeAt(index);
              }
              if (list == null || list.isEmpty) {
                if (_keepStockAfterClose) {
                  _recalculateStockFromRecords(symbol);
                } else {
                  // 不保留持仓，直接删除股票
                  stocks.removeWhere((s) => s.symbol == symbol);
                  _operationRecords.remove(symbol);
                  _dividendRecords.remove(symbol);
                }
              } else {
                _recalculateStockFromRecords(symbol);
              }
            });
            _markDirty();
          },
          onEditOperationRecord: (symbol, index, updated) {
            setState(() {
              final list = _operationRecords[symbol];
              if (list != null && index < list.length) {
                list[index] = updated;
              }
              _recalculateStockFromRecords(symbol);
            });
            _markDirty();
          },
          onDeleteDividendRecord: (symbol, index) {
            setState(() {
              final list = _dividendRecords[symbol];
              if (list != null && index < list.length) {
                list.removeAt(index);
              }
            });
            _markDirty();
          },
          onEditDividendRecord: (symbol, index, updated) {
            setState(() {
              final list = _dividendRecords[symbol];
              if (list != null && index < list.length) {
                list[index] = updated;
              }
            });
            _markDirty();
          },
        ),
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
        onDividend: () => _showDividendDialog(stock),
      ),
    );
  }

  void _showDividendDialog(StockModel stock) {
    showDialog(
      context: context,
      builder: (_) => DividendDialog(
        stock: stock,
        onConfirm: (date, amountPerShare, taxRate) {
          setState(() {
            final record = DividendRecord(
              date: date,
              amount: amountPerShare,
              shares: stock.shares,
              taxRate: taxRate,
              currency: stock.currency,
            );
            _dividendRecords.putIfAbsent(stock.symbol, () => []);
            _dividendRecords[stock.symbol]!.add(record);
          });
          _markDirty();
          Navigator.pop(context);
          CenterToast.success(context, DevConfig.dividendSuccess);
        },
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
    _collapseExpandedStock();
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
          _markDirty();
          CenterToast.success(context, DevConfig.resultAddStockSuccess);
        },
      ),
    );
  }

  // 设置页面本地货币变更回调
  void _onCurrencyChanged(String newCurrency) {
    _collapseExpandedStock();
    setState(() => selectedCurrency = newCurrency);
    _markDirty();
  }

  /// 设置页面排序变更回调
  void _onSortChanged(String column) {
    setState(() {
      _sortColumn = column;
    });
    SettingsService.setSortColumn(column);
    SettingsService.setSortAscending(false);
    _markDirty();
  }

  /// 设置页面排序方向变更回调
  void _onSortDirectionChanged(bool ascending) {
    setState(() => _sortAscending = ascending);
    SettingsService.setSortAscending(ascending);
    _markDirty();
  }

  /// 设置页面平仓保留变更回调
  void _onKeepStockChanged(bool value) {
    SettingsService.setKeepStockAfterClose(value);
    _markDirty();
  }

  /// 同步开关被切换
  Future<void> _onSyncToggled() async {
    if (stocks.isNotEmpty) {
      if (_dataDirty) await _flushToCloud();
    } else {
      await _syncStockData();
    }
  }

  /// 打开全屏设置页面
  void _showSettingsPage() {
    _collapseExpandedStock();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          currentCurrency: selectedCurrency,
          onCurrencyChanged: _onCurrencyChanged,
          onSortChanged: _onSortChanged,
          onSortDirectionChanged: _onSortDirectionChanged,
          onSyncToggled: _onSyncToggled,
          onKeepStockChanged: _onKeepStockChanged,
          onSettingsChanged: () => IcloudStorage.saveSettings(),
        ),
      ),
    ).then((_) {
      // 从设置页返回后重新加载设置
      if (mounted) {
        _loadKeepStockSetting();
        _loadSortSettings();
      }
    });
  }

  // 页面组装（仅股票内容，不含外壳/底部 Tab）
  @override
  Widget build(BuildContext context) {
    return Stack(children: [_buildStockTab(), _buildFloatingAddButton()]);
  }

  /// 股票 Tab 内容
  Widget _buildStockTab() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: Colors.blue,
      backgroundColor: const Color(0xFF1A1F26),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              // 点击空白区域自动收缩已展开的股票卡片
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onTap: _collapseExpandedStock,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    StockSummaryCard(
                      selectedCurrency: selectedCurrency,
                      totalAssets: totalAssets,
                      totalMarketValue: totalMarketValue,
                      totalCost: totalCost,
                      totalProfit: totalProfit,
                      totalRealizedPL: totalRealizedPL,
                      totalProfitPercent: totalProfitPercent,
                      totalAfterTaxDividends: totalAfterTaxDividends,
                      totalSellAmount: totalSellAmount,
                      onCurrencyChanged: _onCurrencyChanged,
                      onCollapse: _collapseExpandedStock,
                    ),
                    const SizedBox(height: 8),
                    _buildStockListHeader(),
                    const SizedBox(height: 2),
                    if (_sortedStocks.isEmpty) ...[
                      const EmptyStateWidget(
                        icon: Icons.show_chart,
                        title: DevConfig.homeEmptyTitle,
                        subtitle: DevConfig.homeEmptySubtitle,
                        iconSize: 64,
                        padding: EdgeInsets.symmetric(vertical: 60),
                      ),
                    ] else ...[
                      Column(
                        children: _sortedStocks.map((stock) {
                          return StockCard(
                            stock: stock,
                            isExpanded: _expandedStockSymbol == stock.symbol,
                            onExpandTap: () => _onStockTap(stock),
                            onRecordTap: () => _showRecordsDialog(stock),
                            onMoreTap: () => _showMoreOptions(stock),
                            operationRecords:
                                _operationRecords[stock.symbol] ?? [],
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        },
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
                DevConfig.homeTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DevConfig.homeSubtitle.replaceAll(
                  '{count}',
                  '${stocks.length}',
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _showSearchStockDialog,
                icon: const Icon(Icons.add, color: Color(0xFF5B9CF6), size: 30),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                onPressed: _showSettingsPage,
                icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAddButton() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    // 去掉 SafeArea 上下边距，得到实际可用高度
    final usableHeight =
        mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
    final fabSize = 56.0;

    if (!_fabInitialized) {
      _fabY = (usableHeight - fabSize) / 2;
      _fabInitialized = true;
    }

    final fabLeft = screenWidth - fabSize - 16;

    return Positioned(
      left: fabLeft,
      top: _fabY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _fabY = (_fabY + details.delta.dy).clamp(
              20,
              usableHeight - fabSize - 20,
            );
          });
        },
        onTap: _showSearchStockDialog,
        child: Container(
          width: fabSize,
          height: fabSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  /// 股票列表标题（可点击排序）
  Widget _buildStockListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 2, 26, 2),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _onColumnTap('name'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    DevConfig.homeStockHeader,
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
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DevConfig.homeHoldingHeader,
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
                    DevConfig.homeProfitHeader,
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
