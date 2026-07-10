import 'package:flutter/material.dart';
import '../models/stock_model.dart';
import '../utils/currency_helper.dart';
import '../utils/stock_calculator.dart';

/// 股票卡片组件（纯UI展示）
class StockCard extends StatelessWidget {
  final StockModel stock;
  final bool isExpanded;
  final VoidCallback onExpandTap;
  final VoidCallback onRecordTap;
  final VoidCallback onMoreTap;
  final List<OperationRecord> operationRecords;

  const StockCard({
    super.key,
    required this.stock,
    required this.isExpanded,
    required this.onExpandTap,
    required this.onRecordTap,
    required this.onMoreTap,
    this.operationRecords = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExpandTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1117),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? Colors.blue : const Color(0xFF303631),
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // 第一行：市场标签 + 总价值
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: stock.marketType == '美股'
                        ? Colors.blue
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    stock.marketType,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '总额',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '${CurrencyHelper.getSymbol(stock.currency)}${CurrencyHelper.formatRate(stock.totalValue)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 第二行：Logo + 信息列
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _buildCompanyInfo()),
                Expanded(flex: 2, child: _buildSharesAndPrice()),
                Expanded(flex: 2, child: _buildProfitLoss()),
              ],
            ),
            const SizedBox(height: 4),
            Divider(height: 1, color: const Color(0xFF303631)),
            const SizedBox(height: 4),
            // 展开详情区域
            if (isExpanded) ..._buildExpandedDetails(),
            if (isExpanded) const SizedBox(height: 4),
            if (isExpanded) Divider(height: 1, color: const Color(0xFF303631)),
            if (isExpanded) const SizedBox(height: 4),
            // 操作按钮
            Row(
              children: [
                Expanded(child: _buildRecordButton()),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onExpandTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: isExpanded ? Colors.blue : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(10),
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
                    fontSize: 18,
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
          style: TextStyle(fontSize: 11, color: Colors.grey[400], height: 1.2),
        ),
        const SizedBox(height: 2),
        Text(
          stock.symbol,
          style: const TextStyle(
            fontSize: 12,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_formatShares(stock.shares)}股',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${CurrencyHelper.formatRate(stock.currentPrice)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.abs().toStringAsFixed(2)}%',
              style: TextStyle(fontSize: 10, color: changeColor, height: 1.2),
            ),
            const SizedBox(width: 14), // 与表头排序指示器对齐
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
        const SizedBox(height: 4),
        Text(
          '${stock.profitLossAmount > 0 ? '+' : ''}${CurrencyHelper.formatRate(stock.profitLossAmount.abs())}',
          style: TextStyle(
            fontSize: 12,
            color: stock.isPositive ? Colors.redAccent : Colors.greenAccent,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        Text(
          '${stock.profitLossPercent > 0 ? '+' : ''}${stock.profitLossPercent.abs().toStringAsFixed(2)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: stock.isPositive ? Colors.redAccent : Colors.greenAccent,
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              '记录',
              style: TextStyle(
                fontSize: 12,
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF303631)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              '更多',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建展开详情区域
  List<Widget> _buildExpandedDetails() {
    final stats = StockCalculator.calculateRecordStats(operationRecords);
    final totalCost = stats.totalBuyAmount - stats.totalSellAmount;

    return [
      _buildDetailRow('总成本', CurrencyHelper.formatRate(totalCost)),
      const SizedBox(height: 10),
      _buildDetailRow('平均持仓价', CurrencyHelper.formatRate(stats.avgBuyPrice)),
      const SizedBox(height: 10),
      _buildDetailRow('最大购买价', CurrencyHelper.formatRate(stats.maxBuyPrice)),
      const SizedBox(height: 10),
      _buildDetailRow('最低购买价', CurrencyHelper.formatRate(stats.minBuyPrice)),
      const SizedBox(height: 10),
      _buildDetailRow('加仓次数', '${stats.buyCount} 次'),
      const SizedBox(height: 10),
      _buildDetailRow('减仓次数', '${stats.sellCount} 次'),
    ];
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              height: 1.2,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  String _formatShares(double shares) {
    return CurrencyHelper.formatShares(shares);
  }
}
