import 'package:flutter/material.dart';
import '../utils/currency_helper.dart';
import '../services/settings_service.dart';

/// 全屏设置页面
class SettingsPage extends StatefulWidget {
  final String currentCurrency;
  final ValueChanged<String> onCurrencyChanged;

  const SettingsPage({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _selectedCurrency;
  bool _isCurrencyExpanded = false;
  bool _keepStockAfterClose = false;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
    _loadSettings();
  }

  void _loadSettings() async {
    final keepStock = await SettingsService.getKeepStockAfterClose();
    if (mounted) setState(() => _keepStockAfterClose = keepStock);
  }

  void _onKeepStockChanged(bool value) {
    setState(() => _keepStockAfterClose = value);
    SettingsService.setKeepStockAfterClose(value);
  }

  void _onCurrencySelected(String currency) {
    setState(() => _selectedCurrency = currency);
    widget.onCurrencyChanged(currency);
    SettingsService.setDefaultCurrency(currency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader('本地货币'),
          const SizedBox(height: 8),
          _buildCurrencySection(),
          const SizedBox(height: 24),
          _buildSectionHeader('股票设置'),
          const SizedBox(height: 8),
          _buildKeepStockSetting(),
          const SizedBox(height: 24),
          _buildInfoItem(icon: Icons.info_outline, label: '版本', value: '1.0.0'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCurrencySection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF303631)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: _isCurrencyExpanded,
            onExpansionChanged: (expanded) =>
                setState(() => _isCurrencyExpanded = expanded),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
            childrenPadding: EdgeInsets.zero,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _selectedCurrency,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${CurrencyHelper.getSymbol(_selectedCurrency)} ${CurrencyHelper.formatRate(CurrencyHelper.getExchangeRate(_selectedCurrency))}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    height: 1.2,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              _isCurrencyExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[500],
              size: 22,
            ),
            children: CurrencyHelper.exchangeRates.keys.map((currency) {
              final isSelected = currency == _selectedCurrency;
              final rate = CurrencyHelper.exchangeRates[currency]!;
              final symbol = CurrencyHelper.getSymbol(currency);
              final isLast = currency == CurrencyHelper.exchangeRates.keys.last;

              return InkWell(
                onTap: () => _onCurrencySelected(currency),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: Colors.grey[800]!,
                              width: 0.5,
                            ),
                          ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                size: 20,
                                color: Color(0xFF5B9CF6),
                              )
                            : Icon(
                                Icons.circle_outlined,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currency,
                          style: TextStyle(
                            fontSize: 15,
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            height: 1.2,
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
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF303631)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: Colors.grey[300]),
            ),
          ),
          Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  /// 平仓后是否保留持仓股票设置项
  /// 若选择删除，则清空数据，效果等同直接删除股票
  Widget _buildKeepStockSetting() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF303631)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 20, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '平仓后保留持仓',
                  style: TextStyle(fontSize: 15, color: Colors.grey[300]),
                ),
              ),
              Switch(
                value: _keepStockAfterClose,
                onChanged: _onKeepStockChanged,
                activeColor: const Color(0xFF5B9CF6),
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[800],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              _keepStockAfterClose
                  ? '平仓后保留股票在列表中，持仓数量变为 0'
                  : '平仓后删除股票，清空所有数据（等同直接删除）',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
