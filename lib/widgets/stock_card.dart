import 'package:flutter/material.dart';
import '../models/stock_model.dart';
import '../config/app_config.dart';
import '../utils/currency_helper.dart';
import '../utils/stock_calculator.dart';
import '../utils/logo_cacher.dart';

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
    return AnimatedContainer(
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
          // 头部可点击区域：点击展开/收缩
          GestureDetector(
            onTap: onExpandTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: stock.marketType == DevConfig.searchMarketUS
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
                      DevConfig.stockTotalValue,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${CurrencyHelper.getSymbol(stock.currency)}${CurrencyHelper.formatCompact(stock.totalValue)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
              ],
            ),
          ),
          // 非点击区域：分割线 + 展开详情 + 底部按钮行
          const SizedBox(height: 4),
          Divider(height: 1, color: const Color(0xFF303631)),
          const SizedBox(height: 4),
          if (isExpanded) ..._buildExpandedDetails(),
          if (isExpanded) const SizedBox(height: 4),
          if (isExpanded) Divider(height: 1, color: const Color(0xFF303631)),
          if (isExpanded) const SizedBox(height: 4),
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
    );
  }

  Widget _buildLogo() {
    final fallbackChar = stock.companyName.isNotEmpty
        ? stock.companyName[0]
        : stock.symbol[0];
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _buildLogoContent(fallbackChar),
      ),
    );
  }

  Widget _buildLogoContent(String fallbackChar) {
    if (stock.logoUrl == null) return _buildFallbackChar(fallbackChar);

    final cached = LogoCacher.syncCached(stock.symbol);
    if (cached != null) {
      return Image(
        image: cached,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackChar(fallbackChar),
      );
    }
    final logoFuture = LogoCacher.getLogo(stock.symbol, stock.logoUrl!);
    return FutureBuilder<ImageProvider>(
      future: logoFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return Image(
              image: snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackChar(fallbackChar),
            );
          }
          return _buildFallbackChar(fallbackChar);
        }
        return Container(color: const Color(0xFF2A3040));
      },
    );
  }

  Widget _buildFallbackChar(String char) {
    return Center(
      child: Text(
        char,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${CurrencyHelper.formatRate(stock.shares)}${DevConfig.stockSharesSuffix}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
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
                '${stock.changePercent >= 0 ? '+' : '-'}${stock.changePercent.abs().toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 10, color: changeColor, height: 1.2),
              ),
              const SizedBox(width: 14), // 与表头排序指示器对齐
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfitLoss() {
    final isZero = stock.profitLossAmount.abs() < 0.0001;
    final profitColor = isZero
        ? Colors.grey
        : (stock.isPositive ? Colors.redAccent : Colors.greenAccent);
    final isPositive = isZero ? '' : (stock.isPositive ? '+' : '-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            '${isPositive}${CurrencyHelper.formatCompact(stock.profitLossAmount.abs())}',
            style: TextStyle(
              fontSize: 12,
              color: profitColor,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            '${isPositive}${stock.profitLossPercent.abs().toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: profitColor,
              height: 1.2,
            ),
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
              DevConfig.stockRecord,
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
          color: const Color(0xFF1A1F26),
          border: Border.all(color: const Color(0xFF303631)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              DevConfig.stockMore,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建展开详情区域（每行3个）
  List<Widget> _buildExpandedDetails() {
    final stats = StockCalculator.calculateRecordStats(operationRecords);
    final totalCost = stats.totalBuyAmount - stats.totalSellAmount;

    final items = [
      _DetailItem(
        DevConfig.stockDetailTotalCost,
        CurrencyHelper.formatCompact(totalCost),
      ),
      _DetailItem(
        DevConfig.stockDetailAvgPrice,
        CurrencyHelper.formatRate(stats.avgBuyPrice),
      ),
      _DetailItem(
        DevConfig.stockDetailMaxPrice,
        CurrencyHelper.formatRate(stats.maxBuyPrice),
      ),
      _DetailItem(
        DevConfig.stockDetailMinPrice,
        CurrencyHelper.formatRate(stats.minBuyPrice),
      ),
      _DetailItem(
        DevConfig.stockDetailBuyCount,
        '${stats.buyCount} ${DevConfig.suffixCount}',
      ),
      _DetailItem(
        DevConfig.stockDetailSellCount,
        '${stats.sellCount} ${DevConfig.suffixCount}',
      ),
    ];

    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 3) {
      final rowItems = items.skip(i).take(3).toList();
      rows.add(
        Row(
          children: [
            for (int j = 0; j < 3; j++)
              Expanded(
                child: j < rowItems.length
                    ? _buildDetailCell(
                        rowItems[j].label,
                        rowItems[j].value,
                        j == 0
                            ? CrossAxisAlignment.start
                            : j == 1
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.end,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      );
      if (i + 3 < items.length) {
        rows.add(const SizedBox(height: 8));
      }
    }
    return rows;
  }

  Widget _buildDetailCell(
    String label,
    String value,
    CrossAxisAlignment alignment,
  ) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.2),
        ),
        const SizedBox(height: 2),
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
}

class _DetailItem {
  final String label;
  final String value;
  _DetailItem(this.label, this.value);
}
