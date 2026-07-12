import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../utils/currency_helper.dart';
import '../utils/stock_calculator.dart';

/// 资产总额卡片组件（纯UI展示）
class AssetCard extends StatefulWidget {
  final String selectedCurrency;
  final double totalAssets;
  final double totalCost;
  final double totalProfit;
  final double totalProfitPercent;
  final double totalDividends;
  final double exchangeRate;
  final bool isExchangeRateExpanded;
  final VoidCallback onToggleExchangeRate;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback? onCollapse;

  const AssetCard({
    super.key,
    required this.selectedCurrency,
    required this.totalAssets,
    required this.totalCost,
    required this.totalProfit,
    required this.totalProfitPercent,
    required this.totalDividends,
    required this.exchangeRate,
    required this.isExchangeRateExpanded,
    required this.onToggleExchangeRate,
    required this.onCurrencyChanged,
    this.onCollapse,
  });

  @override
  State<AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<AssetCard> {
  final GlobalKey _dropdownKey = GlobalKey();
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;

  void _toggleDropdown() {
    widget.onCollapse?.call();
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dropdownWidth = screenWidth * 2 / 3;

    setState(() => _isDropdownOpen = true);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 半透明遮罩，点击关闭
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
          // 居中浮动窗口
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: dropdownWidth,
                constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF303631)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题栏
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Row(
                        children: [
                          const Text(
                            DevConfig.assetSelectCurrency,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _closeDropdown,
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[800]),
                    // 货币列表
                    Flexible(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: CurrencyHelper.exchangeRates.keys.map((
                          currency,
                        ) {
                          final isSelected =
                              currency == widget.selectedCurrency;
                          final rate = CurrencyHelper.exchangeRates[currency]!;
                          final symbol = CurrencyHelper.getSymbol(currency);
                          return InkWell(
                            onTap: () {
                              widget.onCurrencyChanged(currency);
                              _closeDropdown();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              color: isSelected
                                  ? Colors.blue.withOpacity(0.15)
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Color(0xFF5B9CF6),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      currency,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isSelected
                                            ? const Color(0xFF5B9CF6)
                                            : Colors.white,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$symbol ${CurrencyHelper.formatRate(rate)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected
                                          ? const Color(0xFF5B9CF6)
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isDropdownOpen = false);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
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
              const Text(
                DevConfig.assetTotalAssets,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.2,
                ),
              ),
              _buildCurrencyButton(),
            ],
          ),
          const SizedBox(height: 4),
          // 总金额（已经是目标币种，直接格式化）
          Text(
            '${CurrencyHelper.getSymbol(widget.selectedCurrency)}${StockCalculator.formatCompact(widget.totalAssets)}',
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
                Expanded(
                  child: _buildSummaryCard(
                    DevConfig.assetTotalCost,
                    _buildTotalCostText(),
                    const Text(
                      ' ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    DevConfig.assetTotalProfit,
                    _buildProfitText(),
                    _buildProfitPercent(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    DevConfig.assetTotalDividends,
                    _buildDividendText(),
                    const Text(
                      '0.00%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 汇率展开区域
          _buildExchangeRateSection(),
        ],
      ),
    );
  }

  Widget _buildCurrencyButton() {
    return GestureDetector(
      key: _dropdownKey,
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
            AnimatedRotation(
              turns: _isDropdownOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 150),
              child: const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, Widget valueText, Widget percentText) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          valueText,
          percentText,
        ],
      ),
    );
  }

  Widget _buildTotalCostText() {
    return Text(
      '${CurrencyHelper.getSymbol(widget.selectedCurrency)}${StockCalculator.formatCompact(widget.totalCost)}',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.1,
      ),
    );
  }

  Widget _buildProfitText() {
    return Text(
      '${widget.totalProfit >= 0 ? '+' : ''}${StockCalculator.formatCompact(widget.totalProfit)}',
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

  Widget _buildDividendText() {
    return Text(
      '${StockCalculator.formatCompact(widget.totalDividends)}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.1,
      ),
    );
  }

  Widget _buildExchangeRateSection() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onToggleExchangeRate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                DevConfig.assetExchangeRate,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Icon(
                widget.isExchangeRateExpanded
                    ? Icons.expand_less
                    : Icons.expand_more,
                size: 16,
                color: Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (widget.isExchangeRateExpanded)
            ..._buildExpandedRateRows()
          else
            _buildCollapsedRateRow(),
        ],
      ),
    );
  }

  /// 收起时：一行显示所有币种，可滑动
  Widget _buildCollapsedRateRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: CurrencyHelper.exchangeRates.keys.map((currency) {
          final rate = CurrencyHelper.exchangeRates[currency]!;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _buildExchangeRateChip(
              currency,
              CurrencyHelper.formatRate(rate),
              isSelected: widget.selectedCurrency == currency,
              onTap: () => widget.onCurrencyChanged(currency),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 展开后的汇率行，每行5个，每行可滑动
  List<Widget> _buildExpandedRateRows() {
    final keys = CurrencyHelper.exchangeRates.keys.toList();
    final rows = <Widget>[];
    for (int i = 0; i < keys.length; i += 5) {
      final rowKeys = keys.skip(i).take(5);
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i > 0 ? 6 : 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: rowKeys.map((currency) {
                final rate = CurrencyHelper.exchangeRates[currency]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildExchangeRateChip(
                    currency,
                    CurrencyHelper.formatRate(rate),
                    isSelected: widget.selectedCurrency == currency,
                    onTap: () => widget.onCurrencyChanged(currency),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }
    return rows;
  }

  Widget _buildExchangeRateChip(
    String currency,
    String rate, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withOpacity(0.3)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 1.5)
              : null,
        ),
        child: Text(
          '$currency $rate',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
