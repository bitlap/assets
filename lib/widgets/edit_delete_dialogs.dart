import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/stock_model.dart';
import '../utils/currency_helper.dart';
import '../services/stock_search_service.dart';
import '../utils/center_toast.dart';

/// 加仓/减仓对话框
class EditStockDialog extends StatefulWidget {
  final StockModel stock;
  final void Function(StockModel updatedStock, OperationRecord? record, bool isClosed) onSave;
  final List<OperationRecord> operationRecords;
  final bool isAdd; // true=加仓, false=减仓

  const EditStockDialog({
    super.key,
    required this.stock,
    required this.onSave,
    required this.isAdd,
    this.operationRecords = const [],
  });

  @override
  State<EditStockDialog> createState() => _EditStockDialogState();
}

class _EditStockDialogState extends State<EditStockDialog> {
  late TextEditingController _sharesController;
  late TextEditingController _priceController;
  final StockSearchService _searchService = StockSearchService();
  bool _isLoadingPrice = false;

  /// 从操作记录计算买入均价：平均成本 = 总金额 / 总股数
  double get _avgBuyPrice {
    final buyRecords = widget.operationRecords.where((r) => r.type == '买入');
    if (buyRecords.isEmpty) return 0.0;
    double totalCost = 0;
    double totalShares = 0;
    for (final r in buyRecords) {
      totalCost += r.amount * r.shares;
      totalShares += r.shares;
    }
    return totalShares > 0 ? totalCost / totalShares : 0.0;
  }

  @override
  void initState() {
    super.initState();
    _sharesController = TextEditingController();
    // 先用当前存储的价格初始化
    _priceController = TextEditingController(
      text: widget.stock.currentPrice > 0
          ? widget.stock.currentPrice.toStringAsFixed(widget.stock.currentPrice >= 100 ? 2 : 3)
          : '',
    );
    // 尝试获取实时价格作为默认值
    _fetchRealtimePrice();
  }

  Future<void> _fetchRealtimePrice() async {
    final secid = widget.stock.secid;
    if (secid == null || secid.isEmpty) return;
    // 检查冷却期
    if (_searchService.cooldownRemainingSeconds > 0) return;
    setState(() => _isLoadingPrice = true);
    try {
      final quote = await _searchService.getStockQuote(
        StockSearchResult(
          code: widget.stock.symbol,
          name: widget.stock.companyName,
          market: widget.stock.marketType,
          secid: secid,
        ),
      );
      if (!mounted) return;
      if (quote != null && quote.currentPrice > 0) {
        _priceController.text = quote.currentPrice.toStringAsFixed(
          quote.currentPrice >= 100 ? 2 : 3,
        );
      }
    } catch (_) {
      // 获取失败时保持原有价格
    } finally {
      if (mounted) setState(() => _isLoadingPrice = false);
    }
  }

  @override
  void dispose() {
    _sharesController.dispose();
    _priceController.dispose();
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
                widget.isAdd ? '加仓' : '减仓',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
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
                  _buildInfoRow('股票代码', widget.stock.symbol),
                  const SizedBox(height: 8),
                  _buildInfoRow('公司名称', widget.stock.companyName),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    '当前价格',
                    '${CurrencyHelper.getSymbol(widget.stock.currency)}${NumberFormat('#,##0.00').format(widget.stock.currentPrice)}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('当前持股', '${_formatShares(widget.stock.shares)}股'),
                  if (_avgBuyPrice > 0) ...[  
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      '买入均价',
                      '${CurrencyHelper.getSymbol(widget.stock.currency)}${NumberFormat('#,##0.00').format(_avgBuyPrice)}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 价格输入
            Row(
              children: [
                const Text('价格（默认实时价格，可修改）', style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.2)),
                const Spacer(),
                if (_isLoadingPrice)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                  ),
              ],
            ),
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
                hintText: '请输入价格',
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 12),
            // 股数输入（变动股数）
            Text(
              widget.isAdd ? '加仓股数' : '减仓股数',
              style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.2),
            ),
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
                hintText: widget.isAdd ? '请输入加仓股数' : '请输入减仓股数',
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),
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
                    onTap: () {
                      final diffShares = double.tryParse(_sharesController.text);
                      final newPrice = double.tryParse(_priceController.text);
                      if (diffShares == null || diffShares <= 0 || newPrice == null || newPrice <= 0) {
                        CenterToast.error(context, '请输入有效的股数和价格');
                        return;
                      }

                      final oldShares = widget.stock.shares;

                      // 减仓时检查股数是否足够
                      if (!widget.isAdd && diffShares > oldShares) {
                        CenterToast.error(context, '减仓股数不能超过持股数');
                        return;
                      }

                      // 计算新总股数
                      final newShares = widget.isAdd
                          ? oldShares + diffShares
                          : oldShares - diffShares;

                      // 判断是否为平仓操作（减仓且数量等于持仓）
                      final bool isClosePosition = !widget.isAdd && diffShares == oldShares;

                      // 计算盈亏：基于买入均价
                      final double avgBuyPrice = _avgBuyPrice;
                      final double profitLoss = avgBuyPrice > 0
                          ? (newPrice - avgBuyPrice) * newShares
                          : 0.0;

                      // 更新股票
                      final updatedStock = widget.stock.copyWith(
                        shares: newShares,
                        currentPrice: newPrice,
                        totalValue: newPrice * newShares,
                        profitLossAmount: profitLoss,
                      );

                      // 创建操作记录
                      String recordType, description;
                      if (isClosePosition) {
                        recordType = '卖出';
                        description = '平仓 ${widget.stock.symbol}';
                      } else if (widget.operationRecords.isEmpty) {
                        recordType = '买入';
                        description = '开仓 ${widget.stock.symbol}';
                      } else {
                        recordType = widget.isAdd ? '买入' : '卖出';
                        description = '${widget.isAdd ? "加仓" : "减仓"} ${widget.stock.symbol}';
                      }

                      final record = OperationRecord(
                        date: DateTime.now(),
                        type: recordType,
                        description: description,
                        amount: newPrice,
                        shares: diffShares,
                      );

                      widget.onSave(updatedStock, record, isClosePosition);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: widget.isAdd
                            ? Colors.red.withOpacity(0.85)
                            : Colors.green.withOpacity(0.85),
                      ),
                      child: Center(
                        child: Text(
                          widget.isAdd ? '确认加仓' : '确认减仓',
                          style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
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
    );
  }

  /// 格式化股数：整数不显示小数点，小数保留原样
  String _formatShares(double shares) {
    if (shares == shares.toInt()) {
      return shares.toInt().toString();
    }
    // 去除末尾多余的0
    return shares.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
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
}

/// 删除确认对话框
class DeleteStockDialog extends StatelessWidget {
  final StockModel stock;
  final VoidCallback onDelete;

  const DeleteStockDialog({super.key, required this.stock, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C1117),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF303631)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(height: 12),
            const Text('确认删除', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              '确定要删除 ${stock.symbol} (${stock.companyName}) 吗?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.4),
            ),
            const SizedBox(height: 20),
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
                    onTap: () {
                      onDelete();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red.withOpacity(0.85),
                      ),
                      child: const Center(child: Text('删除', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600))),
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
}

/// 更多操作对话框
class MoreOptionsDialog extends StatelessWidget {
  final StockModel stock;
  final VoidCallback onAdd;
  final VoidCallback onReduce;
  final VoidCallback onDelete;

  const MoreOptionsDialog({
    super.key,
    required this.stock,
    required this.onAdd,
    required this.onReduce,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C1117),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF303631)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('更多操作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Divider(height: 1, color: const Color(0xFF303631)),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.redAccent),
              title: const Text('加仓', style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                onAdd();
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.greenAccent),
              title: const Text('减仓', style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                onReduce();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('删除股票', style: TextStyle(color: Colors.redAccent, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
