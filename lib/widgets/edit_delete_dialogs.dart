import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_model.dart';
import '../utils/currency_helper.dart';

/// 编辑持股对话框
class EditStockDialog extends StatefulWidget {
  final StockModel stock;
  final String selectedCurrency;
  final ValueChanged<StockModel> onSave;

  const EditStockDialog({
    super.key,
    required this.stock,
    required this.selectedCurrency,
    required this.onSave,
  });

  @override
  State<EditStockDialog> createState() => _EditStockDialogState();
}

class _EditStockDialogState extends State<EditStockDialog> {
  late TextEditingController _sharesController;

  @override
  void initState() {
    super.initState();
    _sharesController = TextEditingController(text: widget.stock.shares.toString());
  }

  @override
  void dispose() {
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
            const Center(
              child: Text('编辑持股', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    '${CurrencyHelper.getSymbol(widget.selectedCurrency)}${NumberFormat('#,##0.00').format(CurrencyHelper.convertFromUSD(widget.stock.currentPrice, widget.selectedCurrency))}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('持股数量', style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.2)),
            const SizedBox(height: 8),
            TextField(
              controller: _sharesController,
              keyboardType: TextInputType.number,
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
                      final newShares = int.tryParse(_sharesController.text);
                      if (newShares != null && newShares > 0) {
                        final oldShares = widget.stock.shares;
                        final ratio = newShares / oldShares;
                        final updatedStock = widget.stock.copyWith(
                          shares: newShares,
                          totalValue: widget.stock.totalValue * ratio,
                          profitLossAmount: widget.stock.profitLossAmount * ratio,
                        );
                        widget.onSave(updatedStock);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入有效的持股数量')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF2962FF)]),
                      ),
                      child: const Center(child: Text('保存', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600))),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MoreOptionsDialog({
    super.key,
    required this.stock,
    required this.onEdit,
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
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text('编辑持股', style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                onEdit();
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
