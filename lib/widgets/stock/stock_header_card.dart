import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../utils/currency_helper.dart';
import '../common/profit_chart.dart';
import '../common/dialog_utils.dart';
import '../common/currency_selector.dart';

class StockHeaderCard extends StatefulWidget {
  final String selectedCurrency;
  final double totalAssets;
  final double totalMarketValue;
  final double totalCost;
  final double totalProfit;
  final double totalRealizedPL;
  final double totalProfitPercent;
  final double totalAfterTaxDividends;
  final double totalSellAmount;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback? onCollapse;

  const StockHeaderCard({
    super.key,
    required this.selectedCurrency,
    required this.totalAssets,
    required this.totalMarketValue,
    required this.totalCost,
    required this.totalProfit,
    required this.totalRealizedPL,
    required this.totalProfitPercent,
    required this.totalAfterTaxDividends,
    required this.totalSellAmount,
    required this.onCurrencyChanged,
    this.onCollapse,
  });

  @override
  State<StockHeaderCard> createState() => _StockHeaderCardState();
}

class _StockHeaderCardState extends State<StockHeaderCard> {
  void _toggleDropdown() {
    CurrencySelector.show(
      context: context,
      selectedCurrency: widget.selectedCurrency,
      onCurrencyChanged: widget.onCurrencyChanged,
      onOpen: widget.onCollapse,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 总资产和货币选择
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    StockConfig.assetTotalAssets,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _showTotalAssetsHelpDialog,
                    child: const Icon(
                      Icons.help_outline,
                      size: 14,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              _buildCurrencyButton(),
            ],
          ),
          const SizedBox(height: 4),
          // 总金额（已经是目标币种，直接格式化）
          Text(
            '${CurrencyHelper.getSymbol(widget.selectedCurrency)}${CurrencyHelper.formatCompact(widget.totalAssets)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          // 总成本、总盈亏和总股息
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildTotalCostSummaryCard()),
                const SizedBox(width: 8),
                Expanded(child: _buildProfitSummaryCard()),
                const SizedBox(width: 8),
                Expanded(child: _buildDividendSummaryCard()),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ProfitChartWidget(
            totalProfit: widget.totalProfit,
            targetCurrency: widget.selectedCurrency,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyButton() {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.selectedCurrency,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCostSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                StockConfig.assetTotalCost,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: _showTotalCostHelpDialog,
                child: const Icon(
                  Icons.help_outline,
                  size: 12,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          _buildTotalMarketText(),
          _buildTotalMarketPercent(),
        ],
      ),
    );
  }

  void _showTotalAssetsHelpDialog() {
    final sellText = '${CurrencyHelper.formatCompact(widget.totalSellAmount)}';
    _helpDialogFrame(
      title: StockConfig.assetTotalAssets,
      icon: Icons.account_balance_wallet,
      children: [
        _helpLine(StockConfig.assetTotalSellAmount, sellText, Colors.white),
      ],
    );
  }

  void _showTotalCostHelpDialog() {
    final costText = '${CurrencyHelper.formatCompact(widget.totalCost)}';
    final floatPL = widget.totalMarketValue - widget.totalCost;
    final floatText =
        '${floatPL >= 0 ? '+' : ''}${CurrencyHelper.formatCompact(floatPL)}';
    _helpDialogFrame(
      title: StockConfig.assetTotalCost,
      icon: Icons.account_balance,
      children: [
        _helpLine(StockConfig.assetCostDetailLabel, costText, Colors.white),
        const SizedBox(height: 6),
        _helpLine(
          StockConfig.assetFloatProfitLabel,
          floatText,
          floatPL >= 0 ? const Color(0xFFFF5252) : const Color(0xFF69F0AE),
        ),
      ],
    );
  }

  Widget _buildProfitSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                StockConfig.assetTotalProfit,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: _showProfitHelpDialog,
                child: const Icon(
                  Icons.help_outline,
                  size: 12,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          _buildProfitText(),
          _buildProfitPercent(),
        ],
      ),
    );
  }

  void _showProfitHelpDialog() {
    final realizedText =
        '${widget.totalRealizedPL >= 0 ? '+' : ''}${CurrencyHelper.formatCompact(widget.totalRealizedPL)}';
    _helpDialogFrame(
      title: StockConfig.assetTotalProfit,
      icon: Icons.trending_up,
      children: [
        _helpLine(
          StockConfig.assetTotalRealizedPL,
          realizedText,
          widget.totalRealizedPL >= 0
              ? const Color(0xFFFF5252)
              : const Color(0xFF69F0AE),
        ),
      ],
    );
  }

  Widget _buildTotalMarketText() {
    return Text(
      '${CurrencyHelper.formatCompact(widget.totalMarketValue)}',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.1,
      ),
    );
  }

  Widget _buildTotalMarketPercent() {
    final percent = widget.totalAssets > 0
        ? (widget.totalMarketValue / widget.totalAssets * 100)
        : 0.0;
    return Text(
      '${percent.toStringAsFixed(2)}%',
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }

  Widget _buildProfitText() {
    return Text(
      '${widget.totalProfit >= 0 ? '+' : ''}${CurrencyHelper.formatCompact(widget.totalProfit)}',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: widget.totalProfit >= 0
            ? const Color(0xFFFF5252)
            : const Color(0xFF69F0AE),
        height: 1.1,
      ),
    );
  }

  Widget _buildProfitPercent() {
    return Text(
      '${widget.totalProfit >= 0 ? '+' : '-'}${widget.totalProfitPercent.abs().toStringAsFixed(2)}%',
      style: TextStyle(
        fontSize: 11,
        color: widget.totalProfit >= 0
            ? const Color(0xFFFF5252)
            : const Color(0xFF69F0AE),
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
  }

  Widget _buildDividendSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
              const Text(
                StockConfig.assetTotalDividends,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 2),
            ],
          ),
          const SizedBox(height: 2),
          _buildDividendText(),
          _buildDividendPercent(),
        ],
      ),
    );
  }

  Widget _helpLine(String label, String value, [Color? valueColor]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _helpDialogFrame({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    InfoDialog.show(
      context,
      title: Column(
        children: [
          Icon(icon, color: Colors.amber, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDividendPercent() {
    final percent = widget.totalAssets > 0
        ? (widget.totalAfterTaxDividends / widget.totalAssets * 100)
        : 0.0;
    return Text(
      '${percent.toStringAsFixed(2)}%',
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }

  Widget _buildDividendText() {
    return Text(
      '${CurrencyHelper.formatCompact(widget.totalAfterTaxDividends)}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.1,
      ),
    );
  }
}
