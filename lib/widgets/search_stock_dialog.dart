import 'dart:async';
import 'package:flutter/material.dart';

import '../models/stock_model.dart';
import '../models/stock_search_models.dart';
import '../services/stock_search_service.dart';
import '../services/stock_quote_service.dart';
import '../utils/center_toast.dart';
import '../utils/currency_helper.dart';
import '../utils/logo_cacher.dart';
import '../config/app_config.dart';
import 'common/app_number_field.dart';
import 'common/info_row_widget.dart';

/// 股票搜索弹窗 - 支持按名称/代码搜索港股、美股
class SearchStockDialog extends StatefulWidget {
  /// 选中股票后的回调，返回新构建的 StockModel 和建仓操作记录
  final void Function(StockModel stock, OperationRecord buyRecord) onStockAdded;

  /// 当前已持有的股票代码列表，用于去重
  final Set<String> existingSymbols;

  const SearchStockDialog({
    super.key,
    required this.onStockAdded,
    this.existingSymbols = const {},
  });

  @override
  State<SearchStockDialog> createState() => _SearchStockDialogState();
}

class _SearchStockDialogState extends State<SearchStockDialog> {
  final _controller = TextEditingController();
  final _searchService = StockSearchService();
  final _quoteService = StockQuoteService();
  final _focusNode = FocusNode();

  List<StockSearchResult> _results = [];
  List<StockSearchResult> _allResults = []; // 全部搜索结果（过滤前）
  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  String? _selectedMarket; // 市场筛选：null=全部, '美股', '港股'

  // 正在获取行情的股票（loading 状态）
  final Set<String> _loadingQuotes = {};
  // 缓存行情数据
  final Map<String, StockQuote?> _quoteCache = {};
  // 行情获取失败的股票
  final Set<String> _failedQuotes = {};

  @override
  void initState() {
    super.initState();
    // 弹窗打开后自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    // 不再 dispose service，因为是单例，其他 dialog 还要用
    _focusNode.dispose();
    super.dispose();
  }

  /// 触发搜索（带防抖）
  void _onSearchChanged(String keyword) {
    _debounceTimer?.cancel();
    if (keyword.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _errorMessage = '';
      });
      return;
    }
    _debounceTimer = Timer(
      const Duration(milliseconds: DevConfig.searchDebounceMs),
      () {
        _doSearch(keyword);
      },
    );
  }

  /// 执行搜索
  Future<void> _doSearch(String keyword) async {
    // 检查是否在冷却期
    final cooldownSecs = _searchService.cooldownRemainingSeconds;
    if (cooldownSecs > 0) {
      setState(() {
        _errorMessage = DevConfig.searchRateLimit.replaceAll(
          '{secs}',
          '${cooldownSecs}',
        );
        _hasSearched = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _failedQuotes.clear();
      // 不清空缓存，保留已缓存的行情数据
    });

    try {
      final results = await _searchService.searchStocks(keyword);
      if (!mounted) return;

      // 搜索后再次检查冷却状态
      if (_searchService.cooldownRemainingSeconds > 0 && results.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
          _errorMessage = DevConfig.searchRateLimitShort;
        });
        return;
      }

      setState(() {
        _allResults = results;
        _results = _applyMarketFilter(results);
        _isLoading = false;
        _hasSearched = true;
        if (_results.isEmpty) {
          _errorMessage = _selectedMarket != null
              ? DevConfig.searchNotFoundMarket.replaceAll(
                  '{market}',
                  _selectedMarket ?? '',
                )
              : DevConfig.searchNotFound;
        }
      });
      // 从 service 缓存中恢复已有行情
      _restoreCachedQuotes();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasSearched = true;
        _errorMessage = DevConfig.searchFailed;
      });
    }
  }

  /// 添加股票到持仓列表
  Future<void> _addStock(StockSearchResult stock) async {
    if (widget.existingSymbols.contains(stock.code)) {
      CenterToast.warning(
        context,
        DevConfig.searchAlreadyExists.replaceAll('{code}', '${stock.code}'),
      );
      return;
    }

    // 先尝试从缓存获取行情，没有则实时获取
    StockQuote? quote = _quoteCache[stock.secid];
    if (quote == null) {
      // 检查冷却状态
      final cooldownSecs = _searchService.cooldownRemainingSeconds;
      if (cooldownSecs > 0) {
        CenterToast.warning(
          context,
          DevConfig.searchRateLimit.replaceAll('{secs}', '${cooldownSecs}'),
        );
        return;
      }
      setState(() => _loadingQuotes.add(stock.secid));
      quote = await _quoteService.getStockQuote(stock);
      if (!mounted) return;
      setState(() => _loadingQuotes.remove(stock.secid));
    }

    final defaultPrice = quote?.currentPrice ?? 0.0;

    // 弹出输入价格和股数的弹窗
    if (!mounted) return;
    final result = await showDialog<Map<String, double>>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AddStockConfirmDialog(
        stockCode: stock.code,
        stockName: quote?.name ?? stock.name,
        market: stock.market,
        defaultPrice: defaultPrice,
      ),
    );

    if (result == null) return; // 用户取消

    final price = result['price']!;
    final shares = result['shares']!;
    final totalValue = price * shares;

    final stockModel = StockModel(
      symbol: stock.code,
      companyName: quote?.name ?? stock.name,
      currentPrice: defaultPrice > 0 ? defaultPrice : price, // 优先使用真实价格，回退到用户输入
      shares: shares,
      totalValue: defaultPrice > 0
          ? defaultPrice * shares
          : totalValue, // 使用真实价格计算总金额
      profitLossPercent: quote?.changePercent ?? 0.0,
      profitLossAmount: 0.0, // 刚建仓，盈亏为0
      isPositive: (quote?.changePercent ?? 0.0) >= 0,
      logoUrl: StockQuoteService.getLogoUrl(stock.code, stock.market),
      marketType: stock.market,
      changePercent: quote?.changePercent ?? 0.0,
      currency: CurrencyHelper.currencyForMarket(stock.market),
      secid: stock.secid,
    );

    // 创建建仓操作记录
    final buyRecord = OperationRecord(
      date: DateTime.now(),
      type: DevConfig.opBuy,
      description: DevConfig.opOpenPosition + ' ${stock.code}',
      amount: price,
      shares: shares,
    );

    widget.onStockAdded(stockModel, buyRecord);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1F26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * DevConfig.dialogWidthRatio,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSearchBar(),
            const Divider(height: 1, color: Color(0xFF303631)),
            FlexibleChild(child: _buildResultsList()),
          ],
        ),
      ),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                DevConfig.searchTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, color: Colors.grey, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0C1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF303631)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: DevConfig.searchHint,
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                        _errorMessage = '';
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.clear, color: Colors.grey, size: 18),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag(DevConfig.searchAll, _selectedMarket == null),
              const SizedBox(width: 8),
              _buildTag(
                DevConfig.searchMarketUS,
                _selectedMarket == DevConfig.searchMarketUS,
              ),
              const SizedBox(width: 8),
              _buildTag(
                DevConfig.searchMarketHK,
                _selectedMarket == DevConfig.searchMarketHK,
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMarket = label == DevConfig.searchAll ? null : label;
          _results = _applyMarketFilter(_allResults);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.25)
              : Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.6)
                : Colors.blue.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? const Color(0xFF5B9CF6) : Colors.grey[500],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 根据选中的市场筛选结果
  List<StockSearchResult> _applyMarketFilter(List<StockSearchResult> results) {
    if (_selectedMarket == null) return results;
    return results.where((s) => s.market == _selectedMarket).toList();
  }

  /// 从 service 缓存中恢复已有行情，并对未缓存的股票批量获取行情
  void _restoreCachedQuotes() {
    final needFetch = <StockSearchResult>[];
    for (final stock in _allResults) {
      if (!_quoteCache.containsKey(stock.secid)) {
        final cached = _quoteService.getCachedQuote(stock.secid);
        if (cached != null) {
          _quoteCache[stock.secid] = cached;
        } else {
          needFetch.add(stock);
        }
      }
    }
    if (needFetch.isEmpty) {
      // 全部命中缓存，直接结束 loading 显示结果
      setState(() => _isLoading = false);
    } else {
      _fetchQuotesBatch(needFetch);
    }
  }

  /// 批量获取股票行情并更新 UI
  Future<void> _fetchQuotesBatch(List<StockSearchResult> stocks) async {
    setState(() {
      for (final stock in stocks) {
        _loadingQuotes.add(stock.secid);
      }
    });
    final quotes = await _quoteService.getStockQuotesBatch(stocks);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      for (final stock in stocks) {
        _loadingQuotes.remove(stock.secid);
        final quote = quotes[stock.secid];
        if (quote != null) {
          _quoteCache[stock.secid] = quote;
        } else {
          _failedQuotes.add(stock.secid);
        }
      }
    });
  }

  /// 搜索结果列表
  Widget _buildResultsList() {
    if (_isLoading && _results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }

    if (_hasSearched && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: Colors.grey,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                DevConfig.searchInitHint,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 6),
              Text(
                DevConfig.searchInitExample,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _results.length,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (context, index) {
        final stock = _results[index];
        final quote = _quoteCache[stock.secid];
        final isLoadingQuote = _loadingQuotes.contains(stock.secid);
        final isFailedQuote = _failedQuotes.contains(stock.secid);
        final isExisting = widget.existingSymbols.contains(stock.code);

        return _buildStockItem(
          stock,
          quote,
          isLoadingQuote,
          isFailedQuote,
          isExisting,
        );
      },
    );
  }

  /// 单只股票行
  Widget _buildStockItem(
    StockSearchResult stock,
    StockQuote? quote,
    bool isLoadingQuote,
    bool isFailedQuote,
    bool isExisting,
  ) {
    final changePercent = quote?.changePercent ?? 0.0;
    final isPositive = changePercent >= 0;
    final priceColor = isPositive
        ? const Color(0xFFFF5252)
        : const Color(0xFF4CAF50);

    return InkWell(
      onTap: isExisting ? null : () => _addStock(stock),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[850]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0C1117),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: () {
                  final logoUrl = StockQuoteService.getLogoUrl(
                    stock.code,
                    stock.market,
                  );
                  if (logoUrl != null) {
                    return FutureBuilder<ImageProvider>(
                      future: LogoCacher.getLogo(stock.code, logoUrl),
                      builder: (_, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasData) {
                            return Image(
                              image: snapshot.data!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildLogoFallback(stock),
                            );
                          }
                          return _buildLogoFallback(stock);
                        }
                        return Container(
                          width: 36,
                          height: 36,
                          color: const Color(0xFF2A3040),
                        );
                      },
                    );
                  }
                  return _buildLogoFallback(stock);
                }(),
              ),
            ),
            const SizedBox(width: 12),
            // 股票信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stock.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: stock.market == DevConfig.searchMarketUS
                              ? Colors.blue.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stock.market,
                          style: TextStyle(
                            fontSize: 10,
                            color: stock.market == DevConfig.searchMarketUS
                                ? const Color(0xFF5B9CF6)
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stock.name,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 行情数据 + 添加按钮（右侧固定区域，限制最大宽度防溢出）
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.35,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 行情数据
                  if (isLoadingQuote)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),
                    )
                  else if (isFailedQuote)
                    Flexible(
                      child: Text(
                        DevConfig.searchQuoteUnavailable,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else if (quote != null)
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyHelper.formatCompact(
                              quote.currentPrice,
                              formatBase: CurrencyHelper.formatRate,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${isPositive ? '+' : '-'}${changePercent.abs().toStringAsFixed(2)}%',
                            style: TextStyle(color: priceColor, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),
                    ),
                  // 添加按钮
                  const SizedBox(width: 12),
                  if (isExisting)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800]!,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        DevConfig.btnAdded,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        DevConfig.btnAdd,
                        style: TextStyle(
                          color: Color(0xFF5B9CF6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoFallback(StockSearchResult stock) {
    final firstChar = stock.name.isNotEmpty ? stock.name[0] : stock.code[0];
    return Container(
      color: const Color(0xFF2A3040),
      child: Center(
        child: Text(
          firstChar,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// 可伸缩子组件，让列表占满剩余空间
class FlexibleChild extends StatelessWidget {
  final Widget child;
  const FlexibleChild({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Flexible(child: child);
  }
}

/// 添加股票确认弹窗 - 输入价格和股数
class _AddStockConfirmDialog extends StatefulWidget {
  final String stockCode;
  final String stockName;
  final String market;
  final double defaultPrice;

  const _AddStockConfirmDialog({
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.defaultPrice,
  });

  @override
  State<_AddStockConfirmDialog> createState() => _AddStockConfirmDialogState();
}

class _AddStockConfirmDialogState extends State<_AddStockConfirmDialog> {
  late final TextEditingController _priceController;
  late final TextEditingController _sharesController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.defaultPrice > 0
          ? CurrencyHelper.formatRate(widget.defaultPrice)
          : '',
    );
    _sharesController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _sharesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C1117),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * DevConfig.dialogWidthRatio,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF303631)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  DevConfig.searchAddTitle.replaceAll(
                    '{code}',
                    widget.stockCode,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 股票信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF303631)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRowWidget(
                      label: DevConfig.searchStockName,
                      value: widget.stockName,
                    ),
                    const SizedBox(height: 8),
                    InfoRowWidget(
                      label: DevConfig.searchMarket,
                      value: widget.market,
                    ),
                    if (widget.defaultPrice > 0) ...[
                      const SizedBox(height: 8),
                      InfoRowWidget(
                        label: DevConfig.searchRealtimePrice,
                        value: CurrencyHelper.formatRate(widget.defaultPrice),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 买入价格
              AppNumberField(
                controller: _priceController,
                label: DevConfig.searchBuyPrice,
                hintText: DevConfig.searchBuyPriceHint,
              ),
              const SizedBox(height: 12),
              // 持股数量
              AppNumberField(
                controller: _sharesController,
                label: DevConfig.searchShares,
                hintText: DevConfig.searchSharesHint,
              ),
              const SizedBox(height: 20),
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF303631)),
                        ),
                        child: const Center(
                          child: Text(
                            DevConfig.btnCancel,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _onConfirm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            DevConfig.btnConfirmAdd,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onConfirm() {
    final price = double.tryParse(_priceController.text);
    final shares = double.tryParse(_sharesController.text);

    if (price == null || price <= 0) {
      CenterToast.error(context, DevConfig.searchInvalidPrice);
      return;
    }
    if (shares == null || shares <= 0) {
      CenterToast.error(context, DevConfig.searchInvalidShares);
      return;
    }

    Navigator.pop(context, {'price': price, 'shares': shares});
  }
}
