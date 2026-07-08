import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/stock_model.dart';
import 'data/mock_data.dart';
import 'utils/currency_helper.dart';
import 'utils/center_toast.dart';
import 'widgets/asset_card.dart';
import 'widgets/stock_card.dart';
import 'widgets/records_dialog.dart';
import 'widgets/edit_delete_dialogs.dart';
import 'widgets/search_stock_dialog.dart';

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
  List<StockModel> stocks = MockDataGenerator.generateStocks();
  String selectedCurrency = 'CNY';
  bool _isExchangeRateExpanded = false;
  String? _expandedStockSymbol;
  // 每只股票的操作记录
  final Map<String, List<OperationRecord>> _operationRecords = {};

  // ========== 计算属性 ==========
  /// 将股票自身币种金额转换为目标币种
  double _convertToSelected(double amount, String stockCurrency) {
    final amountInUSD = amount / CurrencyHelper.getExchangeRate(stockCurrency);
    return amountInUSD * CurrencyHelper.getExchangeRate(selectedCurrency);
  }

  double get totalAssets => stocks.fold(0.0, (sum, stock) => sum + _convertToSelected(stock.totalValue, stock.currency));
  double get totalProfit => stocks.fold(0.0, (sum, stock) => sum + _convertToSelected(stock.profitLossAmount, stock.currency));
  double get totalDividends => 38756;
  double get exchangeRate => CurrencyHelper.getExchangeRate(selectedCurrency);

  // ========== 事件处理 ==========
  void _onCurrencyChanged(String newCurrency) {
    setState(() => selectedCurrency = newCurrency);
  }

  void _onStockTap(StockModel stock) {
    setState(() {
      _expandedStockSymbol = _expandedStockSymbol == stock.symbol ? null : stock.symbol;
    });
  }

  void _onEditStock(StockModel updatedStock, OperationRecord? record, bool isClosed) {
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
          });
          CenterToast.success(context, '添加成功');
        },
      ),
    );
  }

  /// 格式化股数
  String _formatShares(double shares) {
    if (shares == shares.toInt()) {
      return shares.toInt().toString();
    }
    return shares.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  // ========== 页面组装 ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1117),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              AssetCard(
                selectedCurrency: selectedCurrency,
                totalAssets: totalAssets,
                totalProfit: totalProfit,
                totalDividends: totalDividends,
                exchangeRate: exchangeRate,
                isExchangeRateExpanded: _isExchangeRateExpanded,
                onToggleExchangeRate: () => setState(() => _isExchangeRateExpanded = !_isExchangeRateExpanded),
                onCurrencyChanged: _onCurrencyChanged,
              ),
              const SizedBox(height: 10),
              _buildStockListHeader(),
              const SizedBox(height: 6),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stocks.length,
                itemBuilder: (context, index) {
                  final stock = stocks[index];
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
              const SizedBox(height: 30),
            ],
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
              const Text('股票持仓', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
              const SizedBox(height: 2),
              Text('共 ${stocks.length} 只 · 实时更新', style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.2)),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  /// 股票列表标题
  Widget _buildStockListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('股票', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[500], height: 1.2))),
          Expanded(flex: 2, child: Text('持仓', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[500], height: 1.2))),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('盈亏', textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[500], height: 1.2)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showSearchStockDialog,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Color(0xFF5B9CF6)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
