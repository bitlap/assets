import 'package:flutter/material.dart';
import '../models/stock_model.dart';
import '../utils/currency_helper.dart';

/// 股票卡片组件（纯UI展示）
class StockCard extends StatelessWidget {
  final StockModel stock;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onRecordTap;
  final VoidCallback onMoreTap;
  final List<OperationRecord> operationRecords;

  const StockCard({
    super.key,
    required this.stock,
    required this.isExpanded,
    required this.onTap,
    required this.onRecordTap,
    required this.onMoreTap,
    this.operationRecords = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1117),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded ? Colors.blue : const Color(0xFF303631),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 市场标签 + 总价值
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stock.marketType == '美股'
                        ? Colors.blue
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stock.marketType,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${CurrencyHelper.getSymbol(stock.currency)}${CurrencyHelper.formatRate(stock.totalValue)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 主信息行
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildCompanyInfo()),
                Expanded(flex: 2, child: _buildSharesAndPrice()),
                Expanded(flex: 2, child: _buildProfitLoss()),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: const Color(0xFF303631)),
            const SizedBox(height: 12),
            // 操作按钮
            Row(
              children: [
                Expanded(child: _buildRecordButton()),
                const SizedBox(width: 8),
                Expanded(child: _buildMoreButton()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: stock.logoUrl == null
            ? LinearGradient(
                colors: [
                  stock.isPositive
                      ? Colors.red.withOpacity(0.7)
                      : Colors.green.withOpacity(0.7),
                  stock.isPositive
                      ? Colors.redAccent.withOpacity(0.5)
                      : Colors.greenAccent.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: stock.logoUrl == null ? null : Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: stock.logoUrl != null
            ? Image.network(
                stock.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildLogoFallback(),
              )
            : Center(
                child: Text(
                  stock.symbol.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLogoFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stock.isPositive
                ? Colors.red.withOpacity(0.7)
                : Colors.green.withOpacity(0.7),
            stock.isPositive
                ? Colors.redAccent.withOpacity(0.5)
                : Colors.greenAccent.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          stock.symbol.substring(0, 1),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stock.companyName,
          style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          stock.symbol,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSharesAndPrice() {
    final changeColor = stock.changePercent >= 0
        ? const Color(0xFFFF5252)
        : const Color(0xFF4CAF50);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_formatShares(stock.shares)}股',
          style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.2),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${CurrencyHelper.formatRate(stock.currentPrice)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
                height: 1.2,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
              style: TextStyle(fontSize: 12, color: changeColor, height: 1.2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfitLoss() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${stock.profitLossPercent > 0 ? '+' : ''}${stock.profitLossPercent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: stock.isPositive ? Colors.redAccent : Colors.greenAccent,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${stock.profitLossAmount > 0 ? '+' : ''}${CurrencyHelper.formatRate(stock.profitLossAmount.abs())}',
          style: TextStyle(
            fontSize: 12,
            color: stock.isPositive ? Colors.redAccent : Colors.greenAccent,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: onRecordTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A56DB).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              '记录',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return GestureDetector(
      onTap: onMoreTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF303631)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              '更多',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatShares(double shares) {
    if (shares == shares.toInt()) {
      return shares.toInt().toString();
    }
    return shares
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
