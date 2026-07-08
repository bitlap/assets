import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stock_model.dart';
import '../services/stock_search_service.dart';
import '../utils/center_toast.dart';
import '../utils/currency_helper.dart';

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
  final _service = StockSearchService();
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
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _doSearch(keyword);
    });
  }

  /// 执行搜索
  Future<void> _doSearch(String keyword) async {
    // 检查是否在冷却期
    final cooldownSecs = _service.cooldownRemainingSeconds;
    if (cooldownSecs > 0) {
      setState(() {
        _errorMessage = '请求过于频繁，请${cooldownSecs}秒后再试';
        _hasSearched = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      // 不清空缓存，保留已缓存的行情数据
    });

    try {
      final results = await _service.searchStocks(keyword);
      if (!mounted) return;

      // 搜索后再次检查冷却状态
      if (_service.cooldownRemainingSeconds > 0 && results.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
          _errorMessage = '请求过于频繁，请稍后再试';
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
              ? '未找到相关${_selectedMarket}股票'
              : '未找到相关股票';
        }
      });
      // 不自动加载行情，等用户点击时才按需获取（避免请求过多被封IP）
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasSearched = true;
        _errorMessage = '搜索失败，请重试';
      });
    }
  }

  /// 添加股票到持仓列表
  Future<void> _addStock(StockSearchResult stock) async {
    if (widget.existingSymbols.contains(stock.code)) {
      CenterToast.warning(context, '${stock.code} 已在持仓中');
      return;
    }

    // 先尝试从缓存获取行情，没有则实时获取
    StockQuote? quote = _quoteCache[stock.secid];
    if (quote == null) {
      // 检查冷却状态
      final cooldownSecs = _service.cooldownRemainingSeconds;
      if (cooldownSecs > 0) {
        CenterToast.warning(context, '请求过于频繁，请${cooldownSecs}秒后再试');
        return;
      }
      setState(() => _loadingQuotes.add(stock.secid));
      quote = await _service.getStockQuote(stock);
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
      currentPrice: price,
      shares: shares,
      totalValue: totalValue,
      profitLossPercent: quote?.changePercent ?? 0.0,
      profitLossAmount: 0.0,
      isPositive: (quote?.changePercent ?? 0.0) >= 0,
      logoUrl: 'https://logo.clearbit.com/${stock.code.toLowerCase()}.com',
      marketType: stock.market,
      currency: CurrencyHelper.currencyForMarket(stock.market),
      secid: stock.secid,
      peRatio: quote?.peRatio,
      marketCap: quote?.marketCap,
      dividendYield: quote?.dividendYield,
      annualDividend: quote?.annualDividend,
    );

    // 创建建仓操作记录
    final buyRecord = OperationRecord(
      date: DateTime.now(),
      type: '买入',
      description: '建仓 ${stock.code}',
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSearchBar(),
            const Divider(height: 1, color: Color(0xFF303631)),
            FlexibleChild(
              child: _buildResultsList(),
            ),
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
                '添加股票',
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
                      hintText: '输入股票名称或代码（如 AAPL、腾讯）',
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
              _buildTag('全部', _selectedMarket == null),
              const SizedBox(width: 8),
              _buildTag('美股', _selectedMarket == '美股'),
              const SizedBox(width: 8),
              _buildTag('港股', _selectedMarket == '港股'),
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
          _selectedMarket = label == '全部' ? null : label;
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
              Icon(Icons.tips_and_updates_outlined, color: Colors.grey, size: 48),
              SizedBox(height: 12),
              Text(
                '输入名称或代码搜索港股/美股',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 6),
              Text(
                '如：AAPL、腾讯、00700、TSLA',
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
        final isExisting = widget.existingSymbols.contains(stock.code);

        return _buildStockItem(stock, quote, isLoadingQuote, isExisting);
      },
    );
  }

  /// 单只股票行
  Widget _buildStockItem(
    StockSearchResult stock,
    StockQuote? quote,
    bool isLoadingQuote,
    bool isExisting,
  ) {
    final changePercent = quote?.changePercent ?? 0.0;
    final isPositive = changePercent >= 0;
    final priceColor = isPositive ? const Color(0xFF4CAF50) : const Color(0xFFFF5252);

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
                child: Image.network(
                  'https://logo.clearbit.com/${stock.code.toLowerCase()}.com',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container( // ignore: unnecessary_underscores
                    color: const Color(0xFF2A3040),
                    child: Center(
                      child: Text(
                        stock.code.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: stock.market == '美股'
                              ? Colors.blue.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stock.market,
                          style: TextStyle(
                            fontSize: 10,
                            color: stock.market == '美股'
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
            // 行情数据（无缓存时显示 --，不主动请求）
            if (quote != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(quote.currentPrice),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(color: priceColor, fontSize: 12),
                  ),
                ],
              )
            else
              const Text(
                '--',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            // 添加按钮
            const SizedBox(width: 12),
            if (isExisting)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('已添加', style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '添加',
                  style: TextStyle(color: Color(0xFF5B9CF6), fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 10000) {
      return '${(price / 10000).toStringAsFixed(2)}万';
    } else if (price >= 100) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(3);
    }
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
          ? widget.defaultPrice.toStringAsFixed(widget.defaultPrice >= 100 ? 2 : 3)
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
                '添加 ${widget.stockCode}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                  _buildInfoRow('股票名称', widget.stockName),
                  const SizedBox(height: 8),
                  _buildInfoRow('市场', widget.market),
                  if (widget.defaultPrice > 0) ...[  
                    const SizedBox(height: 8),
                    _buildInfoRow('实时价格', widget.defaultPrice.toStringAsFixed(widget.defaultPrice >= 100 ? 2 : 3)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 买入价格
            const Text('买入价格', style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.2)),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161B22),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF303631))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF303631))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
                hintText: '请输入买入价格',
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 12),
            // 持股数量
            const Text('持股数量', style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.2)),
            const SizedBox(height: 8),
            TextField(
              controller: _sharesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161B22),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF303631))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF303631))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
                hintText: '请输入持股数量',
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
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
                      child: const Center(child: Text('取消', style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500))),
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
                        gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF2962FF)]),
                      ),
                      child: const Center(child: Text('确认添加', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }

  void _onConfirm() {
    final price = double.tryParse(_priceController.text);
    final shares = double.tryParse(_sharesController.text);

    if (price == null || price <= 0) {
      CenterToast.error(context, '请输入有效的买入价格');
      return;
    }
    if (shares == null || shares <= 0) {
      CenterToast.error(context, '请输入有效的持股数量');
      return;
    }

    Navigator.pop(context, {'price': price, 'shares': shares});
  }
}
