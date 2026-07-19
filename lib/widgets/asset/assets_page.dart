import 'package:flutter/material.dart';
import '../../models/asset_account.dart';
import '../../utils/currency_helper.dart';
import '../../utils/center_toast.dart';
import '../../config/app_config.dart';
import '../../services/icloud_storage.dart';
import '../common/app_number_field.dart';
import '../common/dialog_utils.dart';
import '../common/confirm_delete_dialog.dart';
import '../common/currency_selector.dart';
import '../common/empty_state_widget.dart';

class AssetsPage extends StatefulWidget {
  final double stockTotalValue;
  final String currency;
  final ValueChanged<String>? onCurrencyChanged;

  const AssetsPage({
    super.key,
    required this.stockTotalValue,
    required this.currency,
    this.onCurrencyChanged,
  });

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  List<AssetBase> _assets = [];
  AssetType? _filterType;
  double _fabY = 0;
  bool _fabInitialized = false;

  List<AssetBase> get _filteredAssets => _filterType == null
      ? _assets
      : _assets.where((a) => a.type == _filterType).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final assets = await IcloudStorage.loadAssets();
    if (!mounted) return;
    setState(() => _assets = assets);
  }

  Future<void> _save() async {
    await IcloudStorage.saveAssets(_assets);
  }

  void _addAsset(AssetBase asset) {
    setState(() => _assets.add(asset));
    _save();
  }

  void _updateAsset(String id, AssetBase asset) {
    final idx = _assets.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    setState(() => _assets[idx] = asset);
    _save();
  }

  void _deleteAsset(String id) {
    final idx = _assets.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final name = _assets[idx].name;
    setState(() => _assets.removeAt(idx));
    _save();
    CenterToast.success(context, '已删除 $name');
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final filtered = _filteredAssets;
    final item = filtered[oldIndex];
    final oldFull = _assets.indexOf(item);
    setState(() {
      _assets.removeAt(oldFull);
      final target = newIndex < filtered.length ? filtered[newIndex] : null;
      final newFull = target != null ? _assets.indexOf(target) : _assets.length;
      _assets.insert(newFull, item);
      for (int i = 0; i < _assets.length; i++) {
        _assets[i].sortOrder = i;
      }
    });
    _save();
  }

  double get _totalAssets {
    double sum = widget.stockTotalValue;
    for (final a in _assets) {
      switch (a) {
        case CashAccount c:
          sum += CurrencyHelper.convertCurrency(
            c.balance,
            c.currency,
            widget.currency,
          );
        case TimeDeposit t:
          sum += CurrencyHelper.convertCurrency(
            t.totalValue,
            t.currency,
            widget.currency,
          );
        case WealthProduct w:
          sum += CurrencyHelper.convertCurrency(
            w.totalValue,
            w.currency,
            widget.currency,
          );
      }
    }
    return sum;
  }

  void _showCurrencyMenu() {
    CurrencySelector.show(
      context: context,
      selectedCurrency: widget.currency,
      onCurrencyChanged: (c) => widget.onCurrencyChanged?.call(c),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final usableHeight = constraints.maxHeight;
          final fabSize = 56.0;
          if (!_fabInitialized) {
            _fabY = (usableHeight - fabSize) / 2;
            _fabInitialized = true;
          }
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _load,
                color: Colors.blue,
                backgroundColor: const Color(0xFF1A1F26),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSectionTitle()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _buildHeader(),
                      ),
                    ),
                    if (_filteredAssets.isEmpty) ...[
                      if (_assets.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateWidget(
                            icon: Icons.account_balance_wallet_outlined,
                            title: '还没有资产',
                            subtitle: '点击右下角 + 添加现金、存款或理财',
                            iconSize: 64,
                            padding: EdgeInsets.symmetric(vertical: 40),
                          ),
                        )
                      else
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateWidget(
                            icon: Icons.filter_alt_off,
                            title: '没有匹配的资产',
                            subtitle: '尝试其他筛选条件',
                            iconSize: 64,
                            padding: EdgeInsets.symmetric(vertical: 40),
                          ),
                        ),
                    ] else ...[
                      SliverToBoxAdapter(child: _buildListHeader()),
                      const SliverToBoxAdapter(child: SizedBox(height: 2)),
                      SliverReorderableList(
                        itemCount: _filteredAssets.length,
                        onReorder: _onReorder,
                        itemBuilder: (context, index) => _buildAssetItem(index),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: _fabY,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _fabY = (_fabY + details.delta.dy).clamp(
                        20,
                        usableHeight - fabSize - 20,
                      );
                    });
                  },
                  onTap: _showAddSheet,
                  child: Container(
                    width: fabSize,
                    height: fabSize,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────

  Widget _buildHeader() {
    final stockVal = widget.stockTotalValue;
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '总资产',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showCurrencyMenu,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.currency,
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
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyHelper.getSymbol(widget.currency)}${CurrencyHelper.formatCompact(_totalAssets)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSummaryChip(
                Icons.show_chart,
                '股票',
                CurrencyHelper.formatCompact(stockVal),
              ),
              const SizedBox(width: 8),
              _buildSummaryChip(
                Icons.account_balance,
                '存款理财',
                CurrencyHelper.formatCompact(_totalAssets - stockVal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── List Header ───────────────────────────────────────

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 28, 2),
      child: Row(
        children: [
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _showFilterMenu,
            child: Container(
              width: 24,
              alignment: Alignment.center,
              child: Icon(
                _filterType != null
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                size: 18,
                color: _filterType != null ? Colors.blue : Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 44),
                Expanded(
                  child: Text(
                    '名称',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '金额',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterMenu() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '筛选资产类型',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _filterOption(ctx, null, '全部', Icons.all_inclusive, null),
            const SizedBox(height: 4),
            _filterOption(
              ctx,
              AssetType.cash,
              '现金',
              Icons.payments,
              Colors.teal,
            ),
            const SizedBox(height: 4),
            _filterOption(
              ctx,
              AssetType.timeDeposit,
              '定期存款',
              Icons.savings,
              Colors.orange,
            ),
            const SizedBox(height: 4),
            _filterOption(
              ctx,
              AssetType.wealthProduct,
              '理财/基金',
              Icons.trending_up,
              Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(
    BuildContext ctx,
    AssetType? type,
    String label,
    IconData icon,
    Color? color,
  ) {
    final selected = _filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = type);
        Navigator.pop(ctx);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.blue : (color ?? Colors.grey[400]),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: selected ? Colors.blue : Colors.white,
              ),
            ),
            if (selected) const Spacer(),
            if (selected) const Icon(Icons.check, size: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  // ─── Section ───────────────────────────────────────────

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                DevConfig.tabAsset,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '共 ${_assets.length} 项资产',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                  height: 1.2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _showAddSheet,
                icon: const Icon(Icons.add, color: Color(0xFF5B9CF6), size: 30),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Asset Item ────────────────────────────────────────

  Widget _buildAssetItem(int index) {
    final asset = _filteredAssets[index];
    return ReorderableDelayedDragStartListener(
      key: ValueKey(asset.id),
      index: index,
      child: _buildAssetCard(asset, index),
    );
  }

  Widget _buildAssetCard(AssetBase asset, int index) {
    return switch (asset) {
      CashAccount c => _buildCashCard(c, index),
      TimeDeposit t => _buildTimeDepositCard(t, index),
      WealthProduct w => _buildWealthProductCard(w, index),
    };
  }

  // ─── Cash Card ──────────────────────────────────────────

  Widget _buildCashCard(CashAccount cash, int index) {
    final sym = CurrencyHelper.getSymbol(cash.currency);
    return _cardFrame(
      index: index,
      icon: Icons.payments,
      iconColor: Colors.teal,
      name: cash.name.isNotEmpty ? cash.name : '现金 ($cash.currency)',
      createdAt: cash.createdAt,
      updatedAt: cash.updatedAt,
      trailing: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$sym${CurrencyHelper.formatCompact(cash.balance)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      onTap: () => _showCashDialog(index: index, cash: cash),
      onLongPress: () {},
    );
  }

  // ─── Time Deposit Card ─────────────────────────────────

  Widget _buildTimeDepositCard(TimeDeposit td, int index) {
    final remaining = td.endDate.difference(DateTime.now());
    final daysLeft = remaining.inDays > 0 ? remaining.inDays : 0;
    return _cardFrame(
      index: index,
      icon: Icons.savings,
      iconColor: Colors.orange,
      name: td.name.isNotEmpty ? td.name : '定期存款',
      createdAt: td.createdAt,
      updatedAt: td.updatedAt,
      trailing: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${CurrencyHelper.getSymbol(td.currency)}${CurrencyHelper.formatCompact(td.totalValue)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              daysLeft > 0 ? '还剩 ${daysLeft}天' : '已到期',
              style: TextStyle(
                fontSize: 11,
                color: daysLeft > 0 ? Colors.grey[500] : Colors.orange,
              ),
            ),
          ],
        ),
      ),
      onTap: () => _showTimeDepositDialog(index: index, td: td),
      onLongPress: () {},
    );
  }

  // ─── Wealth Product Card ───────────────────────────────

  Widget _buildWealthProductCard(WealthProduct wp, int index) {
    return _cardFrame(
      index: index,
      icon: Icons.trending_up,
      iconColor: Colors.blueAccent,
      name: wp.name.isNotEmpty ? wp.name : '理财产品',
      createdAt: wp.createdAt,
      updatedAt: wp.updatedAt,
      trailing: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '${CurrencyHelper.getSymbol(wp.currency)}${CurrencyHelper.formatCompact(wp.totalValue)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      onTap: () => _showWealthProductDialog(index: index, wp: wp),
      onLongPress: () {},
    );
  }

  // ─── Card Frame ────────────────────────────────────────

  Widget _cardFrame({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String name,
    DateTime? createdAt,
    DateTime? updatedAt,
    required Widget trailing,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    String _f(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Dismissible(
      key: ValueKey('del_${_filteredAssets[index].id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.4)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
      ),
      confirmDismiss: (_) => _confirmDelete(index),
      onDismissed: (_) => _deleteAsset(_filteredAssets[index].id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF303631)),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: Colors.grey[700],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (createdAt != null || updatedAt != null) ...[
                            const SizedBox(height: 2),
                            if (createdAt != null)
                              Text(
                                '创建:${_f(createdAt)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (createdAt != null && updatedAt != null)
                              const SizedBox(height: 2),
                            if (updatedAt != null)
                              Text(
                                '更新:${_f(updatedAt)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 2, child: trailing),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(int index) async {
    final asset = _filteredAssets[index];
    final name = asset.name.isNotEmpty ? asset.name : '此项';
    return ConfirmDeleteDialog.show(
      context,
      title: DevConfig.btnConfirm,
      content: '确定删除 $name 吗？',
    );
  }

  // ─── Add Sheet ──────────────────────────────────────────

  void _showAddSheet() {
    showDialog(
      context: context,
      builder: (ctx) => dialogFrame(
        context: ctx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '添加资产',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _addOption(Icons.payments, Colors.teal, '现金', () {
              Navigator.pop(ctx);
              _showCashDialog();
            }),
            _addOption(Icons.savings, Colors.orange, '定期存款', () {
              Navigator.pop(ctx);
              _showTimeDepositDialog();
            }),
            _addOption(Icons.trending_up, Colors.blueAccent, '理财/基金', () {
              Navigator.pop(ctx);
              _showWealthProductDialog();
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _addOption(
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[600]),
      onTap: onTap,
    );
  }

  // ─── Cash Dialog ────────────────────────────────────────

  void _showCashDialog({int? index, CashAccount? cash}) {
    final isEdit = cash != null;
    final nameCtrl = TextEditingController(text: cash?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: cash != null ? CurrencyHelper.formatRate(cash.balance) : '',
    );
    String currency = cash?.currency ?? widget.currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => dialogFrame(
          context: ctx,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  isEdit ? '编辑现金' : '添加现金',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '名称',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  hintText: '例：活期账户、钱包',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF303631)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF303631)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '余额',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: AppNumberField(
                      controller: balanceCtrl,
                      hintText: '0.00',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCurrencySelector(
                    currency,
                    (c) => setDState(() => currency = c),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              actionButtonRow(
                onCancel: () => Navigator.pop(ctx),
                onConfirm: () {
                  final balance = double.tryParse(balanceCtrl.text);
                  if (balance == null || balance < 0) {
                    CenterToast.error(ctx, '请输入有效金额');
                    return;
                  }
                  final updated = CashAccount(
                    id:
                        cash?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    sortOrder: cash?.sortOrder ?? _assets.length,
                    currency: currency,
                    name: nameCtrl.text.trim(),
                    balance: balance,
                    createdAt: cash?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  if (isEdit && index != null) {
                    _updateAsset(cash.id, updated);
                  } else {
                    _addAsset(updated);
                  }
                  CenterToast.success(ctx, isEdit ? '已编辑' : '已添加');
                  Navigator.pop(ctx);
                },
                confirmText: isEdit ? DevConfig.btnClose : '添加',
                confirmGradient: const LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Time Deposit Dialog ────────────────────────────────

  void _showTimeDepositDialog({int? index, TimeDeposit? td}) {
    final isEdit = td != null;
    final nameCtrl = TextEditingController(text: td?.name ?? '');
    final principalCtrl = TextEditingController(
      text: td != null ? CurrencyHelper.formatRate(td.principal) : '',
    );
    final rateCtrl = TextEditingController(
      text: td != null ? td.annualRate.toString() : '',
    );
    DateTime startDate = td?.startDate ?? DateTime.now();
    int durationMonths = td?.durationMonths ?? 12;
    String currency = td?.currency ?? widget.currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => dialogFrame(
          context: ctx,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    isEdit ? '编辑定期存款' : '添加定期存款',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label('名称'),
                const SizedBox(height: 6),
                _textField(nameCtrl, '例：一年定期'),
                const SizedBox(height: 12),
                const Text(
                  '本金',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: AppNumberField(
                        controller: principalCtrl,
                        hintText: '0.00',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCurrencySelector(
                      currency,
                      (c) => setDState(() => currency = c),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '年利率 (%)',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                AppNumberField(controller: rateCtrl, hintText: '2.5'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _label('存入日期')),
                    const SizedBox(width: 16),
                    Expanded(child: _label('期限 (月)')),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _dateButton(startDate, () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF5B9CF6),
                                onPrimary: Colors.white,
                                surface: Color(0xFF1A1F26),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setDState(() => startDate = picked);
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _durationSelector(
                        durationMonths,
                        (v) => setDState(() => durationMonths = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                actionButtonRow(
                  onCancel: () => Navigator.pop(ctx),
                  onConfirm: () {
                    final principal = double.tryParse(principalCtrl.text);
                    final rate = double.tryParse(rateCtrl.text);
                    if (principal == null || principal <= 0) {
                      CenterToast.error(ctx, '请输入有效本金');
                      return;
                    }
                    if (rate == null || rate < 0) {
                      CenterToast.error(ctx, '请输入有效利率');
                      return;
                    }
                    final updated = TimeDeposit(
                      id:
                          td?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      sortOrder: td?.sortOrder ?? _assets.length,
                      currency: currency,
                      name: nameCtrl.text.trim(),
                      principal: principal,
                      annualRate: rate,
                      startDate: startDate,
                      durationMonths: durationMonths,
                      createdAt: td?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    if (isEdit && index != null)
                      _updateAsset(td.id, updated);
                    else
                      _addAsset(updated);
                    CenterToast.success(ctx, isEdit ? '已编辑' : '已添加');
                    Navigator.pop(ctx);
                  },
                  confirmText: isEdit ? DevConfig.btnClose : '添加',
                  confirmGradient: const LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Wealth Product Dialog ──────────────────────────────

  void _showWealthProductDialog({int? index, WealthProduct? wp}) {
    final isEdit = wp != null;
    final nameCtrl = TextEditingController(text: wp?.name ?? '');
    final sharesCtrl = TextEditingController(
      text: wp != null ? CurrencyHelper.formatRate(wp.shares) : '',
    );
    final navCtrl = TextEditingController(
      text: wp != null ? CurrencyHelper.formatRate(wp.nav) : '',
    );
    String currency = wp?.currency ?? widget.currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => dialogFrame(
          context: ctx,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  isEdit ? '编辑理财/基金' : '添加理财/基金',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('名称'),
              const SizedBox(height: 6),
              _textField(nameCtrl, '例：余额宝、某某基金'),
              const SizedBox(height: 12),
              const Text(
                '持有份额',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              AppNumberField(controller: sharesCtrl, hintText: '0.00'),
              const SizedBox(height: 12),
              const Text(
                '最新净值',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: AppNumberField(
                      controller: navCtrl,
                      hintText: '1.0000',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCurrencySelector(
                    currency,
                    (c) => setDState(() => currency = c),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              actionButtonRow(
                onCancel: () => Navigator.pop(ctx),
                onConfirm: () {
                  final shares = double.tryParse(sharesCtrl.text);
                  final nav = double.tryParse(navCtrl.text);
                  if (shares == null || shares <= 0) {
                    CenterToast.error(ctx, '请输入有效份额');
                    return;
                  }
                  if (nav == null || nav <= 0) {
                    CenterToast.error(ctx, '请输入有效净值');
                    return;
                  }
                  final updated = WealthProduct(
                    id:
                        wp?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    sortOrder: wp?.sortOrder ?? _assets.length,
                    currency: currency,
                    name: nameCtrl.text.trim(),
                    shares: shares,
                    nav: nav,
                    createdAt: wp?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  if (isEdit && index != null)
                    _updateAsset(wp.id, updated);
                  else
                    _addAsset(updated);
                  CenterToast.success(ctx, isEdit ? '已编辑' : '已添加');
                  Navigator.pop(ctx);
                },
                confirmText: isEdit ? DevConfig.btnClose : '添加',
                confirmGradient: const LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF2962FF)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Common Widgets ────────────────────────────────────

  Widget _label(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey));
  }

  Widget _textField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.text,
      style: const TextStyle(fontSize: 16, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFF161B22),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF303631)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF303631)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildCurrencySelector(
    String selected,
    ValueChanged<String> onChanged,
  ) {
    final currencies = CurrencyHelper.exchangeRates.keys.toList();
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF303631)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: const Color(0xFF1A1F26),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: currencies
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _dateButton(DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF303631)),
        ),
        child: Row(
          children: [
            Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const Spacer(),
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _durationSelector(int selected, ValueChanged<int> onChanged) {
    const options = [1, 3, 6, 12, 24, 36, 60];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF303631)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected,
          dropdownColor: const Color(0xFF1A1F26),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: options
              .map((m) => DropdownMenuItem(value: m, child: Text('${m}个月')))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
