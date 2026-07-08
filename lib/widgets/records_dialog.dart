import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_model.dart';
import '../data/mock_data.dart';
import '../utils/currency_helper.dart';

/// 记录对话框（带Tab切换）
class RecordsDialog extends StatefulWidget {
  final StockModel stock;
  final List<OperationRecord> operationRecords;
  final void Function(String symbol, int index)? onDeleteOperationRecord;
  final void Function(String symbol, int index)? onDeleteDividendRecord;

  const RecordsDialog({
    super.key,
    required this.stock,
    this.operationRecords = const [],
    this.onDeleteOperationRecord,
    this.onDeleteDividendRecord,
  });

  @override
  State<RecordsDialog> createState() => _RecordsDialogState();
}

class _RecordsDialogState extends State<RecordsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C1117),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF303631)),
        ),
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Text(
                    widget.stock.symbol,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('记录', style: TextStyle(fontSize: 12, color: Color(0xFF5B9CF6), fontWeight: FontWeight.w500)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF303631)),
                      ),
                      child: const Icon(Icons.close, color: Colors.grey, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            // Tab栏 - pill style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(color: const Color(0xFF1A56DB), borderRadius: BorderRadius.circular(10)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                  dividerColor: Colors.transparent,
                  splashBorderRadius: BorderRadius.circular(10),
                  tabs: const [
                    Tab(text: '操作', height: 36),
                    Tab(text: '派息', height: 36),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tab内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OperationRecordsTab(
                    stock: widget.stock,
                    operationRecords: widget.operationRecords,
                    onDeleteRecord: widget.onDeleteOperationRecord,
                  ),
                  _DividendRecordsTab(
                    stock: widget.stock,
                    onDeleteRecord: widget.onDeleteDividendRecord,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 操作记录Tab
class _OperationRecordsTab extends StatefulWidget {
  final StockModel stock;
  final List<OperationRecord> operationRecords;
  final void Function(String symbol, int index)? onDeleteRecord;

  const _OperationRecordsTab({required this.stock, required this.operationRecords, this.onDeleteRecord});

  @override
  State<_OperationRecordsTab> createState() => _OperationRecordsTabState();
}

class _OperationRecordsTabState extends State<_OperationRecordsTab> {
  late List<OperationRecord> allRecords;

  @override
  void initState() {
    super.initState();
    // 使用真实操作记录，如果没有则用模拟数据
    if (widget.operationRecords.isNotEmpty) {
      allRecords = List.from(widget.operationRecords);
    } else {
      allRecords = MockDataGenerator.generateOperationRecords(widget.stock.symbol);
    }
  }

  String _formatShares(double shares) {
    if (shares == shares.toInt()) {
      return shares.toInt().toString();
    }
    return shares.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,##0.00');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: allRecords.length,
      itemBuilder: (context, index) {
        final record = allRecords[index];
        final isBuy = record.type == '买入';
        final isPriceChange = record.type == '改价';
        final iconColor = isPriceChange ? Colors.blue : (isBuy ? Colors.redAccent : Colors.greenAccent);
        final iconBgColor = isPriceChange ? Colors.blue.withOpacity(0.15) : (isBuy ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15));
        final icon = isPriceChange ? Icons.edit : (isBuy ? Icons.arrow_upward : Icons.arrow_downward);
        return Dismissible(
          key: ValueKey('op_${index}_${record.date.millisecondsSinceEpoch}'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.4)),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('确认删除', style: TextStyle(color: Colors.white, fontSize: 16)),
                content: const Text('确定删除此条操作记录？', style: TextStyle(color: Colors.grey, fontSize: 14)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (_) {
            setState(() => allRecords.removeAt(index));
            widget.onDeleteRecord?.call(widget.stock.symbol, index);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF303631)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.description, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(DateFormat('yyyy-MM-dd HH:mm').format(record.date), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      if (record.amount > 0 && !isPriceChange) ...[  
                        const SizedBox(height: 4),
                        Text(
                          '${format.format(record.amount)} \u00d7 ${_formatShares(record.shares)}股 = ${CurrencyHelper.getSymbol(widget.stock.currency)}${format.format(record.amount * record.shares)}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                      if (isPriceChange) ...[
                        const SizedBox(height: 4),
                        Text(
                          '新价格: ${CurrencyHelper.getSymbol(widget.stock.currency)}${format.format(record.amount)}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isPriceChange)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isBuy ? "+" : "-"}${_formatShares(record.shares)}股',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyHelper.getSymbol(widget.stock.currency)}${format.format(record.amount * record.shares)}',
                        style: TextStyle(color: isBuy ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 派息记录Tab
class _DividendRecordsTab extends StatefulWidget {
  final StockModel stock;
  final void Function(String symbol, int index)? onDeleteRecord;

  const _DividendRecordsTab({required this.stock, this.onDeleteRecord});

  @override
  State<_DividendRecordsTab> createState() => _DividendRecordsTabState();
}

class _DividendRecordsTabState extends State<_DividendRecordsTab> {
  late List<DividendRecord> allRecords;

  @override
  void initState() {
    super.initState();
    allRecords = MockDataGenerator.generateDividendRecords();
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,##0.00');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: allRecords.length,
      itemBuilder: (context, index) {
        final record = allRecords[index];
        return Dismissible(
          key: ValueKey('div_${index}_${record.date.millisecondsSinceEpoch}'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.4)),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('确认删除', style: TextStyle(color: Colors.white, fontSize: 16)),
                content: const Text('确定删除此条派息记录？', style: TextStyle(color: Colors.grey, fontSize: 14)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (_) {
            setState(() => allRecords.removeAt(index));
            widget.onDeleteRecord?.call(widget.stock.symbol, index);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF303631)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.attach_money, color: Colors.orangeAccent, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('派息 ${widget.stock.symbol}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(DateFormat('yyyy-MM-dd').format(record.date), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  '${CurrencyHelper.getSymbol(widget.stock.currency)}${format.format(record.amount)}',
                  style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
