import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/currency_helper.dart';
import '../utils/center_toast.dart';
import '../services/settings_service.dart';
import '../config/app_config.dart';
import 'common/settings_expansion_card.dart';

/// 全屏设置页面
class SettingsPage extends StatefulWidget {
  final String currentCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<bool> onSortDirectionChanged;
  final VoidCallback? onSyncToggled;

  const SettingsPage({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
    required this.onSortChanged,
    required this.onSortDirectionChanged,
    this.onSyncToggled,
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
  bool _isSortAscending = false;
  bool _syncSettings = false;

  static const List<Map<String, String>> sortOptions = [
    {'key': 'profit', 'label': DevConfig.sortByProfit},
    {'key': 'holdings', 'label': DevConfig.sortByHoldings},
    {'key': 'name', 'label': DevConfig.sortByName},
  ];

  static const List<_OpenSourceLib> _openSourceLibs = [
    _OpenSourceLib('Flutter', 'Google', 'BSD 3-Clause', '跨平台 UI 框架'),
    _OpenSourceLib('Dart', 'Google', 'BSD 3-Clause', '编程语言 / 运行时'),
    _OpenSourceLib('cupertino_icons', 'Flutter Team', 'MIT', 'iOS 风格图标集'),
    _OpenSourceLib('intl', 'Dart Team', 'BSD 3-Clause', '国际化与日期格式化'),
    _OpenSourceLib('http', 'Dart Team', 'BSD 3-Clause', 'HTTP 网络请求库'),
    _OpenSourceLib(
      'shared_preferences',
      'Flutter Team',
      'BSD 3-Clause',
      '本地键值存储',
    ),
    _OpenSourceLib(
      'url_launcher',
      'Flutter Team',
      'BSD 3-Clause',
      'URL 启动 / 邮件调用',
    ),
  ];

  static const List<_OpenSourceLib> _dataSources = [
    _OpenSourceLib('东方财富 API', '东方财富', '—', '股票搜索 / 代码查询'),
    _OpenSourceLib('腾讯股票行情', '腾讯', '—', '实时股价 / 涨跌幅'),
    _OpenSourceLib('ExchangeRate-API', 'exchangerate-api.com', '—', '实时汇率数据'),
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
    final sortAscending = await SettingsService.getSortAscending();
    final syncSettings = await SettingsService.getSyncSettings();
    if (mounted) {
      setState(() {
        _keepStockAfterClose = keepStock;
        _selectedSortColumn = sortColumn;
        _isSortAscending = sortAscending;
        _syncSettings = syncSettings;
      });
    }
  }

  void _onSortChanged(String column) {
    setState(() => _selectedSortColumn = column);
    widget.onSortChanged(column);
    widget.onSortDirectionChanged(_isSortAscending);
  }

  void _toggleSortDirection() {
    final newAscending = !_isSortAscending;
    setState(() => _isSortAscending = newAscending);
    widget.onSortDirectionChanged(newAscending);
  }

  void _onKeepStockChanged(bool value) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value ? DevConfig.keepStockOnLabel : DevConfig.keepStockOffLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value ? DevConfig.keepStockOnDesc : DevConfig.keepStockOffDesc,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              DevConfig.btnCancel,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _keepStockAfterClose = value);
              SettingsService.setKeepStockAfterClose(value);
            },
            child: const Text(
              DevConfig.btnClose,
              style: TextStyle(color: Color(0xFF5B9CF6)),
            ),
          ),
        ],
      ),
    );
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
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          DevConfig.settingsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: Color(0xFF1E2430)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildSectionHeader(
            Icons.currency_exchange,
            DevConfig.sectionCurrency,
          ),
          const SizedBox(height: 8),
          _buildCurrencySection(),
          const SizedBox(height: 24),
          _buildSectionHeader(Icons.trending_up, DevConfig.sectionStock),
          const SizedBox(height: 8),
          _buildStockSettingsGroup(),
          const SizedBox(height: 24),
          _buildSectionHeader(Icons.cloud_outlined, DevConfig.sectionSync),
          const SizedBox(height: 8),
          _buildSyncGroup(),
          const SizedBox(height: 24),
          _buildSectionHeader(Icons.more_horiz, DevConfig.sectionOther),
          const SizedBox(height: 8),
          _buildOtherGroup(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5B9CF6)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5B9CF6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF5B9CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _selectedCurrency.substring(0, 1),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B9CF6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
              fontSize: 12,
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

  Widget _buildStockSettingsGroup() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF303631)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildKeepStockTile(),
            _buildGroupDivider(),
            _buildSortTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 48),
      child: Divider(height: 1, color: Color(0xFF303631)),
    );
  }

  Widget _buildKeepStockTile() {
    return InkWell(
      onTap: () => _onKeepStockChanged(!_keepStockAfterClose),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.swap_horiz,
                size: 18,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      DevConfig.keepStockLabel,
                      style: TextStyle(fontSize: 15, color: Colors.grey[300]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _showKeepStockHint,
                    child: Icon(
                      Icons.help_outline,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _keepStockAfterClose,
              onChanged: _onKeepStockChanged,
              activeTrackColor: const Color(0xFF5B9CF6).withValues(alpha: 0.4),
              activeThumbColor: const Color(0xFF5B9CF6),
              inactiveThumbColor: Colors.grey[600],
              inactiveTrackColor: Colors.grey[800],
            ),
          ],
        ),
      ),
    );
  }

  void _showKeepStockHint() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: Color(0xFF5B9CF6)),
            SizedBox(width: 8),
            Text(
              DevConfig.keepStockLabel,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHintRow(
              Icons.check_circle_outline,
              Colors.greenAccent,
              DevConfig.keepStockOnLabel,
              DevConfig.keepStockOnDesc,
            ),
            const SizedBox(height: 12),
            _buildHintRow(
              Icons.cancel_outlined,
              Colors.redAccent,
              DevConfig.keepStockOffLabel,
              DevConfig.keepStockOffDesc,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              DevConfig.btnClose,
              style: TextStyle(color: Color(0xFF5B9CF6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintRow(IconData icon, Color color, String label, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label：',
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortTile() {
    final sortLabel = sortOptions.firstWhere(
      (o) => o['key'] == _selectedSortColumn,
      orElse: () => sortOptions.first,
    )['label']!;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _isSortExpanded,
        onExpansionChanged: (expanded) =>
            setState(() => _isSortExpanded = expanded),
        tilePadding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sort,
                size: 18,
                color: Colors.purpleAccent,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              DevConfig.sortLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              sortLabel,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Icon(
          _isSortExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.grey[500],
          size: 22,
        ),
        children: [
          ...sortOptions.map((option) {
            final key = option['key']!;
            final label = option['label']!;
            final isSelected = _selectedSortColumn == key;
            return InkWell(
              onTap: () => _onSortChanged(key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5B9CF6).withValues(alpha: 0.08)
                      : null,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 42),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? const Color(0xFF5B9CF6)
                              : Colors.grey[300],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: Color(0xFF5B9CF6),
                      ),
                  ],
                ),
              ),
            );
          }),
          // 排序方向切换
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1, color: Color(0xFF303631)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                const SizedBox(width: 42),
                const Text(
                  DevConfig.sortDirectionLabel,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Spacer(),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _isSortAscending ? null : _toggleSortDirection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _isSortAscending
                              ? const Color(0xFF5B9CF6).withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: _isSortAscending
                                ? const Color(0xFF5B9CF6).withValues(alpha: 0.5)
                                : const Color(0xFF303631),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              size: 14,
                              color: _isSortAscending
                                  ? const Color(0xFF5B9CF6)
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DevConfig.sortAscending,
                              style: TextStyle(
                                fontSize: 13,
                                color: _isSortAscending
                                    ? const Color(0xFF5B9CF6)
                                    : Colors.grey[500],
                                fontWeight: _isSortAscending
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isSortAscending ? _toggleSortDirection : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: !_isSortAscending
                              ? const Color(0xFF5B9CF6).withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: !_isSortAscending
                                ? const Color(0xFF5B9CF6).withValues(alpha: 0.5)
                                : const Color(0xFF303631),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: 14,
                              color: !_isSortAscending
                                  ? const Color(0xFF5B9CF6)
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DevConfig.sortDescending,
                              style: TextStyle(
                                fontSize: 13,
                                color: !_isSortAscending
                                    ? const Color(0xFF5B9CF6)
                                    : Colors.grey[500],
                                fontWeight: !_isSortAscending
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncGroup() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF303631)),
      ),
      child: Column(
        children: [
          _buildSyncTile(
            Icons.cloud_outlined,
            Colors.blueAccent,
            DevConfig.syncSettingsLabel,
            _syncSettings,
            (v) => setState(() {
              _syncSettings = v;
              SettingsService.setSyncSettings(v);
              if (v) {
                // 开启同步：立即拉取云端数据
                SettingsService.pushToCloud();
                widget.onSyncToggled?.call();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncTile(
    IconData icon,
    Color iconColor,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: Colors.grey[300]),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF5B9CF6).withValues(alpha: 0.4),
            activeThumbColor: const Color(0xFF5B9CF6),
            inactiveThumbColor: Colors.grey[600],
            inactiveTrackColor: Colors.grey[800],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherGroup() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF303631)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildGroupItem(
              icon: Icons.rate_review_outlined,
              iconColor: Colors.amber,
              label: DevConfig.feedbackLabel,
              onTap: _showFeedbackDialog,
            ),
            _buildGroupDivider(),
            _buildGroupItem(
              icon: Icons.code,
              iconColor: const Color(0xFF64B5F6),
              label: DevConfig.openSourceLabel,
              onTap: _showOpenSourceDialog,
            ),
            _buildGroupDivider(),
            _buildGroupItem(
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              label: DevConfig.versionLabel,
              trailing: DevConfig.appVersion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: Colors.grey[300]),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              )
            else if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[600]),
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
              DevConfig.contactEmail,
              DevConfig.developerEmail,
              onTap: () => _launchEmail(DevConfig.developerEmail),
            ),
            const SizedBox(height: 12),
            _buildContactRow(
              Icons.chat_bubble_outline,
              DevConfig.contactWechat,
              DevConfig.developerWechat,
              onTap: () => _copyToClipboard(
                DevConfig.developerWechat,
                DevConfig.toastWechatCopied,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              DevConfig.btnClose,
              style: TextStyle(color: Color(0xFF5B9CF6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            '$label：',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: onTap != null ? const Color(0xFF5B9CF6) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}
    _copyToClipboard(email, DevConfig.toastEmailCopied);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      CenterToast.success(context, '$label${DevConfig.toastClipboardSuffix}');
    }
  }

  void _showOpenSourceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0C1117),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF303631)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                DevConfig.openSourceTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DevConfig.openSourceDesc,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildLicenseSection(
                      DevConfig.licenseSectionLibs,
                      _openSourceLibs,
                    ),
                    const SizedBox(height: 12),
                    _buildLicenseSection(
                      DevConfig.licenseSectionData,
                      _dataSources,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56DB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    DevConfig.btnClose,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseSection(String title, List<_OpenSourceLib> libs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF303631)),
          ),
          child: Column(
            children: libs.map((lib) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lib.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lib.license,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF5B9CF6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lib.author} · ${lib.description}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _OpenSourceLib {
  final String name;
  final String author;
  final String license;
  final String description;
  const _OpenSourceLib(this.name, this.author, this.license, this.description);
}
