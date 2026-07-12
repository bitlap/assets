import 'package:flutter/material.dart';
import '../models/stock_model.dart';
import '../utils/currency_helper.dart';
import '../utils/stock_calculator.dart';
import '../services/stock_search_service.dart';
import '../utils/center_toast.dart';
import '../config/app_config.dart';
import 'common/app_number_field.dart';
import 'common/info_row_widget.dart';
import 'common/confirm_delete_dialog.dart';

/// 加仓/减仓对话框
class EditStockDialog extends StatefulWidget {
  final StockModel stock;
  final void Function(
    StockModel updatedStock,
    OperationRecord? record,
    bool isClosed,
  )
  onSave;
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

  /// 从操作记录计算买入均价
  double get _avgBuyPrice =>
      StockCalculator.calculateAvgBuyPrice(widget.operationRecords);

  @override
  void initState() {
    super.initState();
    _sharesController = TextEditingController();
    // 先用当前存储的价格初始化
    _priceController = TextEditingController(
      text: widget.stock.currentPrice > 0
          ? CurrencyHelper.formatRate(widget.stock.currentPrice)
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
        _priceController.text = CurrencyHelper.formatRate(quote.currentPrice);
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
                widget.isAdd
                    ? DevConfig.opAddPosition
                    : DevConfig.opReducePosition,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                  InfoRowWidget(
                    label: DevConfig.searchStockCode,
                    value: widget.stock.symbol,
                  ),
                  const SizedBox(height: 8),
                  InfoRowWidget(
                    label: DevConfig.searchStockName,
                    value: widget.stock.companyName,
                  ),
                  const SizedBox(height: 8),
                  InfoRowWidget(
                    label: DevConfig.searchRealtimePrice,
                    value:
                        '${CurrencyHelper.getSymbol(widget.stock.currency)}${CurrencyHelper.formatRate(widget.stock.currentPrice)}',
                  ),
                  const SizedBox(height: 8),
                  InfoRowWidget(
                    label: DevConfig.searchShares,
                    value:
                        '${CurrencyHelper.formatShares(widget.stock.shares)}${DevConfig.stockSharesSuffix}',
                  ),
                  if (_avgBuyPrice > 0) ...[
                    const SizedBox(height: 8),
                    InfoRowWidget(
                      label: DevConfig.stockDetailAvgPrice,
                      value:
                          '${CurrencyHelper.getSymbol(widget.stock.currency)}${CurrencyHelper.formatRate(_avgBuyPrice)}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 价格输入
            Row(
              children: [
                const Text(
                  DevConfig.editPriceHint,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                if (_isLoadingPrice)
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
            const SizedBox(height: 8),
            AppNumberField(
              controller: _priceController,
              hintText: DevConfig.editPricePlaceholder,
            ),
            const SizedBox(height: 12),
            AppNumberField(
              controller: _sharesController,
              label: widget.isAdd
                  ? DevConfig.editAddSharesLabel
                  : DevConfig.editReduceSharesLabel,
              hintText: widget.isAdd
                  ? DevConfig.editAddSharesHint
                  : DevConfig.editReduceSharesHint,
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
                    onTap: () {
                      final diffShares = double.tryParse(
                        _sharesController.text,
                      );
                      final newPrice = double.tryParse(_priceController.text);
                      if (diffShares == null ||
                          diffShares <= 0 ||
                          newPrice == null ||
                          newPrice <= 0) {
                        CenterToast.error(context, DevConfig.editInvalidInput);
                        return;
                      }

                      final oldShares = widget.stock.shares;

                      // 减仓时检查股数是否足够
                      if (!widget.isAdd && diffShares > oldShares) {
                        CenterToast.error(context, DevConfig.editOverflow);
                        return;
                      }

                      // 计算新总股数
                      final newShares = widget.isAdd
                          ? oldShares + diffShares
                          : oldShares - diffShares;

                      // 判断是否为平仓操作（减仓且数量等于持仓）
                      final bool isClosePosition =
                          !widget.isAdd && diffShares == oldShares;

                      // 计算盈亏：基于买入均价
                      final double avgBuyPrice = _avgBuyPrice;
                      final double profitLoss = avgBuyPrice > 0
                          ? (newPrice - avgBuyPrice) * newShares
                          : 0.0;

                      // 更新股票
                      final updatedStock = widget.stock.copyWith(
                        shares: newShares,
                        // 不更新 currentPrice，保持实时价格
                        totalValue:
                            widget.stock.currentPrice *
                            newShares, // 使用实时价格计算总金额
                        profitLossAmount: profitLoss,
                      );

                      // 创建操作记录
                      String recordType, description;
                      if (isClosePosition) {
                        recordType = DevConfig.opSell;
                        description =
                            '${DevConfig.opClosePosition} ${widget.stock.symbol}';
                      } else if (widget.operationRecords.isEmpty) {
                        recordType = DevConfig.opBuy;
                        description =
                            '${DevConfig.opOpenPosition} ${widget.stock.symbol}';
                      } else {
                        recordType = widget.isAdd
                            ? DevConfig.opBuy
                            : DevConfig.opSell;
                        description =
                            '${widget.isAdd ? DevConfig.opAddPosition : DevConfig.opReducePosition} ${widget.stock.symbol}';
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
                          widget.isAdd
                              ? DevConfig.btnConfirmBuy
                              : DevConfig.btnConfirmSell,
                          style: const TextStyle(
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
    );
  }
}

/// 删除确认对话框（使用通用组件）
class DeleteStockDialog extends StatelessWidget {
  final StockModel stock;
  final VoidCallback onDelete;

  const DeleteStockDialog({
    super.key,
    required this.stock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ConfirmDeleteDialog(
      title: DevConfig.btnConfirm,
      content: DevConfig.deleteConfirmContent
          .replaceAll('{symbol}', stock.symbol)
          .replaceAll('{name}', stock.companyName),
      onConfirm: onDelete,
    );
  }
}

/// 更多操作对话框
class MoreOptionsDialog extends StatelessWidget {
  final StockModel stock;
  final VoidCallback onAdd;
  final VoidCallback onReduce;
  final VoidCallback onDelete;
  final VoidCallback onDividend;

  const MoreOptionsDialog({
    super.key,
    required this.stock,
    required this.onAdd,
    required this.onReduce,
    required this.onDelete,
    required this.onDividend,
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
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  DevConfig.opMoreActions,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Divider(height: 1, color: const Color(0xFF303631)),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.redAccent),
                title: const Text(
                  DevConfig.opAddPosition,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onAdd();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.remove_circle,
                  color: Colors.greenAccent,
                ),
                title: const Text(
                  DevConfig.opReducePosition,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onReduce();
                },
              ),
              ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.amber),
                title: const Text(
                  DevConfig.opDividend,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDividend();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text(
                  DevConfig.opDeleteStock,
                  style: TextStyle(color: Colors.redAccent, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 派息对话框
class DividendDialog extends StatefulWidget {
  final StockModel stock;
  final void Function(DateTime date, double amountPerShare, double taxRate)
  onConfirm;

  const DividendDialog({
    super.key,
    required this.stock,
    required this.onConfirm,
  });

  @override
  State<DividendDialog> createState() => _DividendDialogState();
}

class _DividendDialogState extends State<DividendDialog> {
  late TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now();
  double _taxRate = 10;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5B9CF6),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1F26),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
                DevConfig.dividendTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                  InfoRowWidget(
                    label: DevConfig.searchStockCode,
                    value: widget.stock.symbol,
                  ),
                  const SizedBox(height: 8),
                  InfoRowWidget(
                    label: DevConfig.searchStockName,
                    value: widget.stock.companyName,
                  ),
                  const SizedBox(height: 8),
                  InfoRowWidget(
                    label: DevConfig.searchShares,
                    value:
                        '${CurrencyHelper.formatShares(widget.stock.shares)}${DevConfig.stockSharesSuffix}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 派息日期
            const Text(
              DevConfig.dividendDateLabel,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.2),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF303631)),
                ),
                child: Row(
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 每股派息金额
            AppNumberField(
              controller: _amountController,
              label: DevConfig.dividendAmountLabel,
              hintText: DevConfig.dividendAmountHint,
            ),
            const SizedBox(height: 12),
            // 税率
            Row(
              children: [
                Text(
                  DevConfig.dividendTaxRateLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_taxRate.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF5B9CF6),
                inactiveTrackColor: const Color(0xFF303631),
                thumbColor: const Color(0xFF5B9CF6),
                overlayColor: const Color(0xFF5B9CF6).withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _taxRate,
                min: 0,
                max: 50,
                divisions: 50,
                onChanged: (value) => setState(() => _taxRate = value),
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
                    onTap: () {
                      final amount = double.tryParse(_amountController.text);
                      if (amount == null || amount <= 0) {
                        CenterToast.error(
                          context,
                          DevConfig.dividendInvalidAmount,
                        );
                        return;
                      }
                      widget.onConfirm(_selectedDate, amount, _taxRate / 100);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF5B9CF6).withValues(alpha: 0.85),
                      ),
                      child: Center(
                        child: Text(
                          DevConfig.dividendConfirm,
                          style: const TextStyle(
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
    );
  }
}
