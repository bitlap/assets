import 'package:flutter/material.dart';
import '../utils/currency_helper.dart';
import '../services/settings_service.dart';
import '../config/app_config.dart';
import 'common/settings_expansion_card.dart';

/// 全屏设置页面
class SettingsPage extends StatefulWidget {
  final String currentCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onSortChanged;

  const SettingsPage({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
    required this.onSortChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _selectedCurrency;
  bool _isCurrencyExpanded = false;
  bool _isSortExpanded = false;
  bool _keepStockAfterClose = false;
  String _selectedSortColumn = 'profit';

  // 排序选项映射
  static const List<Map<String, String>> sortOptions = [
    {'key': 'profit', 'label': '按盈亏'},
    {'key': 'holdings', 'label': '按持仓'},
    {'key': 'name', 'label': '按名称'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
    _loadSettings();
  }

  void _loadSettings() async {
    final keepStock = await SettingsService.getKeepStockAfterClose();
    final sortColumn = await SettingsService.getSortColumn();
    if (mounted) {
      setState(() {
        _keepStockAfterClose = keepStock;
        _selectedSortColumn = sortColumn;
      });
    }
  }

  void _onSortChanged(String column) {
    setState(() => _selectedSortColumn = column);
    widget.onSortChanged(column);
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
        toolbarHeight: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        children: [
          _buildSectionHeader('本地货币'),
          const SizedBox(height: 4),
          _buildCurrencySection(),
          const SizedBox(height: 12),
          _buildSectionHeader('股票设置'),
          const SizedBox(height: 4),
          _buildKeepStockSetting(),
          const SizedBox(height: 8),
          _buildSortSetting(),
          const SizedBox(height: 12),
          _buildSectionHeader('其他'),
          const SizedBox(height: 4),
          _buildFeedbackItem(),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.info_outline,
            label: '版本',
            value: DevConfig.appVersion,
          ),
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
    return SettingsExpansionCard(
      initiallyExpanded: _isCurrencyExpanded,
      onExpansionChanged: (expanded) =>
          setState(() => _isCurrencyExpanded = expanded),
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
        return SettingsSelectableItem(
          label: currency,
          trailingText: '$symbol ${CurrencyHelper.formatRate(rate)}',
          isSelected: isSelected,
          isLast: isLast,
          onTap: () => _onCurrencySelected(currency),
        );
      }).toList(),
    );
  }

  Widget _buildFeedbackItem() {
    return GestureDetector(
      onTap: () => _showFeedbackDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF303631)),
        ),
        child: Row(
          children: [
            Icon(Icons.rate_review_outlined, size: 20, color: Colors.grey[500]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '意见反馈',
                style: TextStyle(fontSize: 15, color: Colors.grey[300]),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          DevConfig.feedbackTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DevConfig.feedbackHint,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactRow(
              Icons.email_outlined,
              '邮箱',
              DevConfig.developerEmail,
            ),
            const SizedBox(height: 12),
            _buildContactRow(
              Icons.chat_bubble_outline,
              '微信',
              DevConfig.developerWechat,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭', style: TextStyle(color: Color(0xFF5B9CF6))),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          '$label：',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  /// 获取当前排序标签
  String get _selectedSortLabel {
    final option = sortOptions.firstWhere(
      (o) => o['key'] == _selectedSortColumn,
      orElse: () => sortOptions.first,
    );
    return option['label']!;
  }

  /// 排序规则折叠式
  Widget _buildSortSetting() {
    return SettingsExpansionCard(
      initiallyExpanded: _isSortExpanded,
      onExpansionChanged: (expanded) =>
          setState(() => _isSortExpanded = expanded),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.sort, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          const Text(
            '默认排序',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _selectedSortLabel,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              height: 1.2,
            ),
          ),
        ],
      ),
      trailing: Icon(
        _isSortExpanded ? Icons.expand_less : Icons.expand_more,
        color: Colors.grey[500],
        size: 22,
      ),
      children: sortOptions.map((option) {
        final key = option['key']!;
        final label = option['label']!;
        final isSelected = _selectedSortColumn == key;
        final isLast = key == sortOptions.last['key'];
        return SettingsSelectableItem(
          label: label,
          isSelected: isSelected,
          isLast: isLast,
          onTap: () => _onSortChanged(key),
        );
      }).toList(),
    );
  }

  /// 平仓后是否保留持仓股票设置项
  /// 若选择删除，则清空数据，效果等同直接删除股票
  Widget _buildKeepStockSetting() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                activeThumbColor: const Color(0xFF5B9CF6),
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[800],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              _keepStockAfterClose
                  ? '平仓后保留股票在列表中，但持仓数量和金额均变为 0'
                  : '平仓后删除股票，清空数据（等同直接删除股票和记录）',
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
