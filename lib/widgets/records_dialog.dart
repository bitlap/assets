import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_model.dart';
import '../data/mock_data.dart';
import '../utils/currency_helper.dart';

/// 记录对话框（带Tab切换）
class RecordsDialog extends StatefulWidget {
  final StockModel stock;
  final String currency;

  const RecordsDialog({super.key, required this.stock, required this.currency});

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
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
                  _OperationRecordsTab(stock: widget.stock, currency: widget.currency),
                  _DividendRecordsTab(stock: widget.stock, currency: widget.currency),
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
  final String currency;

  const _OperationRecordsTab({required this.stock, required this.currency});

  @override
  State<_OperationRecordsTab> createState() => _OperationRecordsTabState();
}

class _OperationRecordsTabState extends State<_OperationRecordsTab> {
  late List<OperationRecord> allRecords;
  final int pageSize = 10;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    allRecords = MockDataGenerator.generateOperationRecords(widget.stock.symbol);
  }

  List<OperationRecord> get paginatedRecords {
    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    if (endIndex > allRecords.length) return allRecords.sublist(startIndex);
    return allRecords.sublist(startIndex, endIndex);
  }

  int get totalPages => (allRecords.length / pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,##0.00');
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: paginatedRecords.length,
            itemBuilder: (context, index) {
              final record = paginatedRecords[index];
              final isBuy = record.type == '买入';
              return Container(
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
                        color: isBuy ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(isBuy ? Icons.arrow_upward : Icons.arrow_downward, color: isBuy ? Colors.redAccent : Colors.greenAccent, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(record.description, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(DateFormat('yyyy-MM-dd HH:mm').format(record.date), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${record.shares}股', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyHelper.getSymbol(widget.currency)}${format.format(CurrencyHelper.convertFromUSD(record.amount, widget.currency))}',
                          style: TextStyle(color: isBuy ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildPaginationBar(),
      ],
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(top: BorderSide(color: const Color(0xFF303631))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: currentPage > 1 ? () => setState(() => currentPage--) : null,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF303631)),
                color: currentPage > 1 ? const Color(0xFF0C1117) : Colors.transparent,
              ),
              child: Icon(Icons.chevron_left, size: 16, color: currentPage > 1 ? Colors.white : Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF303631)),
            ),
            child: Text('$currentPage / $totalPages', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: currentPage < totalPages ? () => setState(() => currentPage++) : null,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF303631)),
                color: currentPage < totalPages ? const Color(0xFF0C1117) : Colors.transparent,
              ),
              child: Icon(Icons.chevron_right, size: 16, color: currentPage < totalPages ? Colors.white : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 派息记录Tab
class _DividendRecordsTab extends StatefulWidget {
  final StockModel stock;
  final String currency;

  const _DividendRecordsTab({required this.stock, required this.currency});

  @override
  State<_DividendRecordsTab> createState() => _DividendRecordsTabState();
}

class _DividendRecordsTabState extends State<_DividendRecordsTab> {
  late List<DividendRecord> allRecords;
  final int pageSize = 10;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    allRecords = MockDataGenerator.generateDividendRecords();
  }

  List<DividendRecord> get paginatedRecords {
    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    if (endIndex > allRecords.length) return allRecords.sublist(startIndex);
    return allRecords.sublist(startIndex, endIndex);
  }

  int get totalPages => (allRecords.length / pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,##0.00');
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: paginatedRecords.length,
            itemBuilder: (context, index) {
              final record = paginatedRecords[index];
              return Container(
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
                      '${CurrencyHelper.getSymbol(widget.currency)}${format.format(CurrencyHelper.convertFromUSD(record.amount, widget.currency))}',
                      style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildDividendPaginationBar(),
      ],
    );
  }

  Widget _buildDividendPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(top: BorderSide(color: const Color(0xFF303631))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: currentPage > 1 ? () => setState(() => currentPage--) : null,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF303631)),
                color: currentPage > 1 ? const Color(0xFF0C1117) : Colors.transparent,
              ),
              child: Icon(Icons.chevron_left, size: 16, color: currentPage > 1 ? Colors.white : Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF303631)),
            ),
            child: Text('$currentPage / $totalPages', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: currentPage < totalPages ? () => setState(() => currentPage++) : null,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF303631)),
                color: currentPage < totalPages ? const Color(0xFF0C1117) : Colors.transparent,
              ),
              child: Icon(Icons.chevron_right, size: 16, color: currentPage < totalPages ? Colors.white : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
