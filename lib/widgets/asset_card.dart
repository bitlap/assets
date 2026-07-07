import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/currency_helper.dart';

/// 资产总额卡片组件（纯UI展示）
class AssetCard extends StatefulWidget {
  final String selectedCurrency;
  final double totalAssets;
  final double totalProfit;
  final double totalDividends;
  final double exchangeRate;
  final bool isExchangeRateExpanded;
  final VoidCallback onToggleExchangeRate;
  final ValueChanged<String> onCurrencyChanged;

  const AssetCard({
    super.key,
    required this.selectedCurrency,
    required this.totalAssets,
    required this.totalProfit,
    required this.totalDividends,
    required this.exchangeRate,
    required this.isExchangeRateExpanded,
    required this.onToggleExchangeRate,
    required this.onCurrencyChanged,
  });

  @override
  State<AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<AssetCard> {
  final GlobalKey _dropdownKey = GlobalKey();
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    // 列表从按钮正下方开始，最大高度不超过屏幕底部安全区
    final topPosition = position.dy + size.height + 4;
    final maxHeight = screenHeight - topPosition - 40;

    setState(() => _isDropdownOpen = true);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 点击外部关闭
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          // 下拉列表
          Positioned(
            left: position.dx,
            top: topPosition,
            width: size.width,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight.clamp(100, 220)),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF303631)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: CurrencyHelper.exchangeRates.keys.map((currency) {
                      final isSelected = currency == widget.selectedCurrency;
                      return InkWell(
                        onTap: () {
                          widget.onCurrencyChanged(currency);
                          _closeDropdown();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                          child: Text(
                            currency,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.blue : Colors.white,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
    final format = NumberFormat('#,##0.00');

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
          // 资产总额和货币选择
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '资产总额',
                style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.2),
              ),
              _buildCurrencyButton(),
            ],
          ),
          const SizedBox(height: 4),
          // 汇率信息
          Text(
            '1 USD = ${CurrencyHelper.formatRate(widget.exchangeRate)} ${widget.selectedCurrency}',
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500, height: 1.2),
          ),
          const SizedBox(height: 8),
          // 总金额
          Text(
            '${CurrencyHelper.getSymbol(widget.selectedCurrency)}${format.format(CurrencyHelper.convertFromUSD(widget.totalAssets, widget.selectedCurrency))}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
          ),
          const SizedBox(height: 8),
          // 总盈亏和总股息
          Row(
            children: [
              Expanded(child: _buildSummaryCard('总盈亏', _buildProfitText(format), _buildProfitPercent())),
              const SizedBox(width: 8),
              Expanded(child: _buildSummaryCard('总股息', _buildDividendText(format), const Text('4.17%', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500, height: 1.2)))),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.selectedCurrency,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
            ),
            const SizedBox(width: 2),
            AnimatedRotation(
              turns: _isDropdownOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 150),
              child: const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.2)),
          const SizedBox(height: 2),
          valueText,
          percentText,
        ],
      ),
    );
  }

  Widget _buildProfitText(NumberFormat format) {
    final converted = CurrencyHelper.convertFromUSD(widget.totalProfit, widget.selectedCurrency);
    return Text(
      '${widget.totalProfit >= 0 ? '+' : ''}${format.format(converted)}',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: widget.totalProfit >= 0 ? const Color(0xFFFF5252) : const Color(0xFF69F0AE),
        height: 1.1,
      ),
    );
  }

  Widget _buildProfitPercent() {
    return Text(
      '${widget.totalProfit >= 0 ? '+' : ''}12.4%',
      style: TextStyle(
        fontSize: 11,
        color: widget.totalProfit >= 0 ? const Color(0xFFFF5252) : const Color(0xFF69F0AE),
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }

  Widget _buildDividendText(NumberFormat format) {
    final converted = CurrencyHelper.convertFromUSD(widget.totalDividends, widget.selectedCurrency);
    return Text(
      '${CurrencyHelper.getSymbol(widget.selectedCurrency)}${format.format(converted)}',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
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
              const Text('汇率', style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.2)),
              const Spacer(),
              Icon(
                widget.isExchangeRateExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: CurrencyHelper.exchangeRates.keys.take(5).map((currency) {
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
          if (widget.isExchangeRateExpanded) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: CurrencyHelper.exchangeRates.keys.skip(5).map((currency) {
                final rate = CurrencyHelper.exchangeRates[currency]!;
                return _buildExchangeRateChip(
                  currency,
                  CurrencyHelper.formatRate(rate),
                  isSelected: widget.selectedCurrency == currency,
                  onTap: () => widget.onCurrencyChanged(currency),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExchangeRateChip(String currency, String rate, {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 1.5) : null,
        ),
        child: Text(
          '$currency $rate',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white, height: 1.2),
        ),
      ),
    );
  }
}
