import 'package:flutter/material.dart';
import '../../models/asset_account.dart';
import '../../utils/currency_helper.dart';
import '../../utils/center_toast.dart';
import '../../utils/asset_calculator.dart';
import '../../config/app_config.dart';
import '../../services/icloud_storage.dart';
import '../common/empty_state_widget.dart';
import '../common/currency_selector.dart';
import '../common/confirm_delete_dialog.dart';
import '../common/draggable_fab.dart';
import 'asset_card.dart';
import 'asset_header.dart';
import 'asset_dialogs.dart';

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
  bool _isLoading = false;

  String? _sortColumn = 'amount';
  bool _sortAscending = false;

  List<AssetBase> get _filteredAssets => _filterType == null
      ? _assets
      : _assets.where((a) => a.type == _filterType).toList();

  List<AssetBase> get _displayAssets => AssetCalculator.sortAssets(
    _filteredAssets,
    _sortColumn,
    _sortAscending,
    widget.currency,
  );

  double get _totalAssets => AssetCalculator.calculateTotalAssets(
    _assets,
    widget.stockTotalValue,
    widget.currency,
  );

  void _onSortColumnTap(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = column == 'amount' ? false : true;
    }
    _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final assets = await IcloudStorage.loadAssets();
    if (!mounted) return;
    setState(() {
      _assets = assets;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    await IcloudStorage.saveAssets(_assets);
  }

  Future<void> _addAsset(AssetBase asset) async {
    setState(() => _assets.add(asset));
    await _save();
  }

  Future<void> _updateAsset(String id, AssetBase asset) async {
    final idx = _assets.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    setState(() => _assets[idx] = asset);
    await _save();
  }

  Future<void> _deleteAsset(String id) async {
    final idx = _assets.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final name = _assets[idx].name;
    setState(() => _assets.removeAt(idx));
    await _save();
    if (mounted) CenterToast.success(context, '已删除 $name');
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_sortColumn != null) {
      if (newIndex > oldIndex) newIndex--;
      final display = _displayAssets;
      final item = display[oldIndex];
      final reordered = List<AssetBase>.from(display)
        ..remove(item)
        ..insert(newIndex, item);
      setState(() {
        _sortColumn = null;
        _assets = reordered;
        for (int i = 0; i < _assets.length; i++) {
          _assets[i].sortOrder = i;
        }
      });
      _save();
      return;
    }
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

  void _showCurrencyMenu() {
    CurrencySelector.show(
      context: context,
      selectedCurrency: widget.currency,
      onCurrencyChanged: (c) => widget.onCurrencyChanged?.call(c),
    );
  }

  Future<bool> _confirmDelete(int index) async {
    final asset = _displayAssets[index];
    final name = asset.name.isNotEmpty ? asset.name : '此项';
    return ConfirmDeleteDialog.show(
      context,
      title: DevConfig.btnConfirm,
      content: '确定要删除 $name 吗？',
    );
  }

  // ─── Dialogs ────────────────────────────────────────────

  void _onAddCash() => _openDialog<CashAccount>(
    showCashAssetDialog(
      context,
      defaultCurrency: widget.currency,
      assetCount: _assets.length,
    ),
    onAdd: (r) => _addAsset(r),
  );

  void _onEditCash(int index, CashAccount cash) => _openDialog<CashAccount>(
    showCashAssetDialog(
      context,
      cash: cash,
      defaultCurrency: widget.currency,
      assetCount: _assets.length,
    ),
    onUpdate: (r) => _updateAsset(cash.id, r),
  );

  void _onAddTD() => _openDialog<TimeDeposit>(
    showTimeDepositDialog(
      context,
      defaultCurrency: widget.currency,
      assetCount: _assets.length,
    ),
    onAdd: (r) => _addAsset(r),
  );

  void _onEditTD(int index, TimeDeposit td) => _openDialog<TimeDeposit>(
    showTimeDepositDialog(
      context,
      td: td,
      defaultCurrency: widget.currency,
      assetCount: _assets.length,
    ),
    onUpdate: (r) => _updateAsset(td.id, r),
  );

  void _onAddWP() => _openDialog<WealthProduct>(
    showWealthProductDialog(
      context,
      defaultCurrency: widget.currency,
      assetCount: _assets.length,
    ),
    onAdd: (r) => _addAsset(r),
  );

  void _onEditWP(int index, WealthProduct wp) => _openDialog<WealthProduct>(
    showWealthProductDialog(
      context,
      wp: wp,
      defaultCurrency: widget.currency,
      assetCount: _assets.length,
    ),
    onUpdate: (r) => _updateAsset(wp.id, r),
  );

  void _openDialog<T extends AssetBase>(
    Future<T?> dialog, {
    Future<void> Function(T)? onAdd,
    Future<void> Function(T)? onUpdate,
  }) async {
    final result = await dialog;
    if (result != null && mounted) {
      if (onAdd != null) await onAdd(result);
      if (onUpdate != null) await onUpdate(result);
      CenterToast.success(context, '已保存');
    }
  }

  // ─── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final usableHeight = constraints.maxHeight;
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _load,
                color: Colors.blue,
                backgroundColor: const Color(0xFF1A1F26),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: AssetSectionTitle(
                        assetCount: _assets.length,
                        onAdd: () async {
                          final action = await showAddAssetSheet(context);
                          if (action == 'cash') _onAddCash();
                          if (action == 'td') _onAddTD();
                          if (action == 'wp') _onAddWP();
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AssetHeader(
                          totalAssets: _totalAssets,
                          stockTotalValue: widget.stockTotalValue,
                          currency: widget.currency,
                          onCurrencyTap: _showCurrencyMenu,
                        ),
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
                      SliverToBoxAdapter(
                        child: AssetListHeader(
                          filterType: _filterType,
                          sortColumn: _sortColumn,
                          sortAscending: _sortAscending,
                          onFilterTap: () => showAssetFilterMenu(
                            context,
                            currentFilter: _filterType,
                            onFilterChanged: (t) {
                              _filterType = t;
                              _load();
                            },
                          ),
                          onSortTap: _onSortColumnTap,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 2)),
                      SliverReorderableList(
                        itemCount: _displayAssets.length,
                        onReorder: _onReorder,
                        itemBuilder: (context, index) => _buildAssetItem(index),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ],
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: Colors.blue),
                  ),
                ),
              DraggableFab(
                onTap: () async {
                  final action = await showAddAssetSheet(context);
                  if (action == 'cash') _onAddCash();
                  if (action == 'td') _onAddTD();
                  if (action == 'wp') _onAddWP();
                },
                maxHeight: usableHeight,
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Asset Item ─────────────────────────────────────────

  Widget _buildAssetItem(int index) {
    final asset = _displayAssets[index];
    return ReorderableDelayedDragStartListener(
      key: ValueKey(asset.id),
      index: index,
      child: Dismissible(
        key: ValueKey('del_${_displayAssets[index].id}'),
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
        onDismissed: (_) => _deleteAsset(_displayAssets[index].id),
        child: _buildAssetCard(asset, index),
      ),
    );
  }

  Widget _buildAssetCard(AssetBase asset, int index) {
    return switch (asset) {
      CashAccount c => _buildCashCard(c, index),
      TimeDeposit t => _buildTimeDepositCard(t, index),
      WealthProduct w => _buildWealthProductCard(w, index),
    };
  }

  Widget _buildCashCard(CashAccount cash, int index) {
    final sym = CurrencyHelper.getSymbol(cash.currency);
    return AssetCardFrame(
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
      onTap: () => _onEditCash(index, cash),
      onLongPress: () {},
    );
  }

  Widget _buildTimeDepositCard(TimeDeposit td, int index) {
    final remaining = td.endDate.difference(DateTime.now());
    final daysLeft = remaining.inDays > 0 ? remaining.inDays : 0;
    return AssetCardFrame(
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
      onTap: () => _onEditTD(index, td),
      onLongPress: () {},
    );
  }

  Widget _buildWealthProductCard(WealthProduct wp, int index) {
    return AssetCardFrame(
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
      onTap: () => _onEditWP(index, wp),
      onLongPress: () {},
    );
  }
}
