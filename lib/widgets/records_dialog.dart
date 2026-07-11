import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_model.dart';
import '../utils/currency_helper.dart';
import '../config/app_config.dart';
import 'common/empty_state_widget.dart';
import 'common/confirm_delete_dialog.dart';

/// 记录弹窗（底部弹出，支持下拉关闭）
class RecordsDialog extends StatefulWidget {
  final StockModel stock;
  final List<OperationRecord> operationRecords;
  final ScrollController scrollController;
  final void Function(String symbol, int index)? onDeleteOperationRecord;
  final void Function(String symbol, int index, OperationRecord updated)?
  onEditOperationRecord;
  final void Function(String symbol, int index)? onDeleteDividendRecord;

  const RecordsDialog({
    super.key,
    required this.stock,
    required this.scrollController,
    this.operationRecords = const [],
    this.onDeleteOperationRecord,
    this.onEditOperationRecord,
    this.onDeleteDividendRecord,
  });

  @override
  State<RecordsDialog> createState() => _RecordsDialogState();
}

class _RecordsDialogState extends State<RecordsDialog>
    with SingleTickerProviderStateMixin {
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Color(0xFF303631)),
          left: BorderSide(color: Color(0xFF303631)),
          right: BorderSide(color: Color(0xFF303631)),
        ),
      ),
      child: Column(
        children: [
          // 拖拽手柄
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Text(
                  widget.stock.symbol,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    DevConfig.stockRecord,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5B9CF6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF303631)),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1A56DB),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(10),
                tabs: [
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(DevConfig.recordsOpTab),
                        const SizedBox(width: 3),
                        GestureDetector(
                          onTap: _showOpDeleteHint,
                          child: const Icon(
                            Icons.help_outline,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(text: DevConfig.recordsDivTab, height: 36),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OperationRecordsTab(
                  stock: widget.stock,
                  operationRecords: widget.operationRecords,
                  onDeleteRecord: widget.onDeleteOperationRecord,
                  onEditRecord: widget.onEditOperationRecord,
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
    );
  }

  void _showOpDeleteHint() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: Color(0xFF5B9CF6)),
            SizedBox(width: 8),
            Text(
              DevConfig.recordsOpTab,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          DevConfig.recordsDeleteHint,
          style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              DevConfig.btnClose,
              style: TextStyle(color: Color(0xFF5B9CF6)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 操作记录Tab
class _OperationRecordsTab extends StatefulWidget {
  final StockModel stock;
  final List<OperationRecord> operationRecords;
  final void Function(String symbol, int index)? onDeleteRecord;
  final void Function(String symbol, int index, OperationRecord updated)?
  onEditRecord;

  const _OperationRecordsTab({
    required this.stock,
    required this.operationRecords,
    this.onDeleteRecord,
    this.onEditRecord,
  });

  @override
  State<_OperationRecordsTab> createState() => _OperationRecordsTabState();
}

class _OperationRecordsTabState extends State<_OperationRecordsTab> {
  late List<OperationRecord> allRecords;

  @override
  void initState() {
    super.initState();
    allRecords = List.from(widget.operationRecords);
  }

  @override
  Widget build(BuildContext context) {
    if (allRecords.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.list_alt,
        title: DevConfig.recordsEmptyOp,
        subtitle: DevConfig.recordsEmptyOpHint,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: allRecords.length,
      itemBuilder: (context, index) {
        final record = allRecords[index];
        final isBuy = record.type == DevConfig.opBuy;
        final isPriceChange = record.type == DevConfig.opPriceChange;
        final iconColor = isPriceChange
            ? Colors.blue
            : (isBuy ? Colors.redAccent : Colors.greenAccent);
        final iconBgColor = isPriceChange
            ? Colors.blue.withOpacity(0.15)
            : (isBuy
                  ? Colors.red.withOpacity(0.15)
                  : Colors.green.withOpacity(0.15));
        final icon = isPriceChange
            ? Icons.edit
            : (isBuy ? Icons.arrow_upward : Icons.arrow_downward);
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
          confirmDismiss: (_) => ConfirmDeleteDialog.show(
            context,
            title: DevConfig.btnConfirm,
            content: DevConfig.recordsDeleteOpConfirm,
          ),
          onDismissed: (_) {
            setState(() => allRecords.removeAt(index));
            widget.onDeleteRecord?.call(widget.stock.symbol, index);
          },
          child: InkWell(
            onTap: () => _showEditRecordDialog(context, index, record),
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
                    width: 36,
                    height: 36,
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
                        Text(
                          record.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm:ss').format(record.date),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        if (record.amount > 0 && !isPriceChange) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${CurrencyHelper.formatRate(record.amount)} × ${CurrencyHelper.formatShares(record.shares)}${DevConfig.stockSharesSuffix} = ${CurrencyHelper.getSymbol(widget.stock.currency)}${CurrencyHelper.formatRate(record.amount * record.shares)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (isPriceChange) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${DevConfig.recordsNewPrice}: ${CurrencyHelper.getSymbol(widget.stock.currency)}${CurrencyHelper.formatRate(record.amount)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
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
                          '${isBuy ? "+" : "-"}${CurrencyHelper.formatShares(record.shares)}${DevConfig.stockSharesSuffix}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyHelper.getSymbol(widget.stock.currency)}${CurrencyHelper.formatRate(record.amount * record.shares)}',
                          style: TextStyle(
                            color: isBuy
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditRecordDialog(
    BuildContext context,
    int index,
    OperationRecord record,
  ) {
    final priceCtrl = TextEditingController(
      text: CurrencyHelper.formatRate(record.amount),
    );
    final sharesCtrl = TextEditingController(
      text: CurrencyHelper.formatShares(record.shares),
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0C1117),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  DevConfig.recordsEditTitle.replaceAll(
                    '{desc}',
                    record.description,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                DevConfig.recordsEditPrice,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF303631)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF303631)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                DevConfig.recordsEditShares,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: sharesCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF303631)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF303631)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
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
                        final newPrice = double.tryParse(priceCtrl.text);
                        final newShares = double.tryParse(sharesCtrl.text);
                        if (newPrice == null ||
                            newPrice <= 0 ||
                            newShares == null ||
                            newShares <= 0) {
                          return;
                        }
                        final updated = OperationRecord(
                          date: record.date,
                          type: record.type,
                          description: record.description,
                          amount: newPrice,
                          shares: newShares,
                        );
                        setState(() => allRecords[index] = updated);
                        widget.onEditRecord?.call(
                          widget.stock.symbol,
                          index,
                          updated,
                        );
                        Navigator.pop(ctx);
                      },
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
                            DevConfig.btnClose,
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
    allRecords = [];
  }

  @override
  Widget build(BuildContext context) {
    if (allRecords.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.attach_money,
        title: DevConfig.recordsEmptyDiv,
        subtitle: DevConfig.recordsEmptyDivHint,
      );
    }

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
          confirmDismiss: (_) => ConfirmDeleteDialog.show(
            context,
            title: DevConfig.btnConfirm,
            content: DevConfig.recordsDeleteDivConfirm,
          ),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.orangeAccent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DevConfig.recordsDivTab + ' ${widget.stock.symbol}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('yyyy-MM-dd').format(record.date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${CurrencyHelper.getSymbol(widget.stock.currency)}${CurrencyHelper.formatRate(record.amount)}',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
