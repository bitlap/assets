import 'package:flutter/material.dart';
import '../../models/asset_account.dart';
import '../../utils/currency_helper.dart';
import '../../utils/center_toast.dart';
import '../../utils/asset_calculator.dart';
import '../../config/app_config.dart';
import '../../services/icloud_storage.dart';
import '../../services/settings_service.dart';
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

sealed class _FlatItem {
  const _FlatItem();
}

class _SectionHeader extends _FlatItem {
  final AssetType type;
  final bool expanded;
  const _SectionHeader(this.type, this.expanded);
}

class _AssetCardItem extends _FlatItem {
  final AssetBase asset;
  const _AssetCardItem(this.asset);
}

class _AssetsPageState extends State<AssetsPage> {
  List<AssetBase> _assets = [];
  bool _isLoading = false;
  final Set<AssetType> _expandedTypes = {};
  List<AssetType> _sectionOrder = [
    AssetType.cash,
    AssetType.timeDeposit,
    AssetType.wealthProduct,
  ];
  List<_FlatItem> _flatItems = [];

  double get _totalAssets => AssetCalculator.calculateTotalAssets(
    _assets,
    widget.stockTotalValue,
    widget.currency,
  );

  Map<AssetType, double> _totalByType(String currency) {
    final totals = <AssetType, double>{};
    for (final a in _assets) {
      totals.update(
        a.type,
        (v) => v + AssetCalculator.getAssetValue(a, currency),
        ifAbsent: () => AssetCalculator.getAssetValue(a, currency),
      );
    }
    return totals;
  }

  void _rebuildFlatItems() {
    _flatItems = [];
    for (final type in _sectionOrder) {
      final items = _assets.where((a) => a.type == type).toList();
      if (items.isEmpty) continue;
      _flatItems.add(_SectionHeader(type, _expandedTypes.contains(type)));
      if (_expandedTypes.contains(type)) {
        for (final a in items) {
          _flatItems.add(_AssetCardItem(a));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      IcloudStorage.loadAssets(),
      SettingsService.getAssetSectionOrder(),
    ]);
    final assets = results[0] as List<AssetBase>;
    final savedOrder = results[1] as List<String>;
    if (!mounted) return;
    setState(() {
      _assets = assets;
      _expandedTypes.clear();
      _sectionOrder = savedOrder
          .map(
            (s) => AssetType.values.firstWhere(
              (t) => t.name == s,
              orElse: () => AssetType.cash,
            ),
          )
          .toList();
      for (final type in AssetType.values) {
        if (_assets.any((a) => a.type == type) &&
            !_sectionOrder.contains(type)) {
          _sectionOrder.add(type);
        }
      }
      _isLoading = false;
    });
    _rebuildFlatItems();
  }

  Future<void> _save() async {
    await IcloudStorage.saveAssets(_assets);
  }

  Future<void> _addAsset(AssetBase asset) async {
    if (!mounted) return;
    setState(() {
      _assets.add(asset);
      if (!_sectionOrder.contains(asset.type)) {
        _sectionOrder.add(asset.type);
      }
    });
    _rebuildFlatItems();
    try {
      await _save();
    } catch (_) {}
  }

  Future<void> _updateAsset(String id, AssetBase asset) async {
    if (!mounted) return;
    final idx = _assets.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    setState(() {
      _assets[idx] = asset;
      if (!_sectionOrder.contains(asset.type)) {
        _sectionOrder.add(asset.type);
      }
    });
    _rebuildFlatItems();
    try {
      await _save();
    } catch (_) {}
  }

  Future<void> _deleteAsset(String id) async {
    if (!mounted) return;
    final idx = _assets.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final name = _assets[idx].name;
    setState(() => _assets.removeAt(idx));
    _rebuildFlatItems();
    try {
      await _save();
    } catch (_) {}
    if (mounted) CenterToast.success(context, '已删除 $name');
  }

  void _onFlatReorder(int oldIndex, int newIndex) {
    try {
      if (newIndex > oldIndex) newIndex--;
      final item = _flatItems[oldIndex];

      if (item is _SectionHeader) {
        if (mounted) CenterToast.warning(context, '分类不可移动');
        return;
      }
      if (item is _AssetCardItem) {
        final type = item.asset.type;
        final typeAssetsLen = _assets.where((a) => a.type == type).length;

        int sameTypeCount = 0;
        bool crossSection = false;
        for (int i = 0; i < newIndex; i++) {
          final origIdx = i < oldIndex ? i : i + 1;
          if (origIdx >= _flatItems.length) break;
          final fi = _flatItems[origIdx];
          if (fi is _AssetCardItem && fi.asset.type == type) {
            sameTypeCount++;
          } else if (fi is _SectionHeader && fi.type != type) {
            crossSection = true;
          } else if (fi is _AssetCardItem && fi.asset.type != type) {
            crossSection = true;
          }
        }
        if (crossSection) {
          if (mounted) CenterToast.warning(context, '不能移动到其他分类');
          return;
        }
        if (typeAssetsLen <= 1) return;

        final newAssets = List<AssetBase>.from(_assets)
          ..removeAt(_assets.indexOf(item.asset));

        int insertAt = newAssets.length;
        int typeCount = 0;
        for (int i = 0; i < newAssets.length; i++) {
          if (newAssets[i].type == type) {
            if (typeCount == sameTypeCount) {
              insertAt = i;
              break;
            }
            typeCount++;
          }
        }
        if (insertAt == newAssets.length && typeCount > 0) {
          for (int i = newAssets.length - 1; i >= 0; i--) {
            if (newAssets[i].type == type) {
              insertAt = i + 1;
              break;
            }
          }
        }
        newAssets.insert(insertAt, item.asset);
        setState(() => _assets = newAssets);
      } else {
        return;
      }

      _rebuildFlatItems();
      _saveSectionOrder();
      _save();
    } catch (_) {
      _rebuildFlatItems();
    }
  }

  Future<void> _saveSectionOrder() async {
    await SettingsService.setAssetSectionOrder(
      _sectionOrder.map((t) => t.name).toList(),
    );
  }

  void _toggleSection(AssetType type) {
    setState(() {
      if (_expandedTypes.contains(type)) {
        _expandedTypes.remove(type);
      } else {
        _expandedTypes.add(type);
      }
    });
    _rebuildFlatItems();
  }

  void _showCurrencyMenu() {
    CurrencySelector.show(
      context: context,
      selectedCurrency: widget.currency,
      onCurrencyChanged: (c) => widget.onCurrencyChanged?.call(c),
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

  void _onEditCash(CashAccount cash) => _openDialog<CashAccount>(
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

  void _onEditTD(TimeDeposit td) => _openDialog<TimeDeposit>(
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

  void _onEditWP(WealthProduct wp) => _openDialog<WealthProduct>(
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
                    if (_flatItems.isEmpty)
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
                      SliverReorderableList(
                        itemCount: _flatItems.length,
                        onReorder: _onFlatReorder,
                        itemBuilder: (context, index) {
                          final item = _flatItems[index];
                          return switch (item) {
                            _SectionHeader(:final type, :final expanded) =>
                              _buildSectionHeader(type, expanded, index),
                            _AssetCardItem(:final asset) => _buildAssetCardItem(
                              asset,
                              index,
                            ),
                          };
                        },
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
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

  // ─── Section Header ─────────────────────────────────────

  Widget _buildSectionHeader(AssetType type, bool expanded, int index) {
    final items = _assets.where((a) => a.type == type).toList();
    final count = items.length;
    final total = _totalByType(widget.currency)[type] ?? 0;

    final (icon, iconColor, label) = switch (type) {
      AssetType.cash => (Icons.payments, Colors.teal, '现金'),
      AssetType.timeDeposit => (Icons.savings, Colors.orange, '定期存款'),
      AssetType.wealthProduct => (
        Icons.trending_up,
        Colors.blueAccent,
        '理财/基金',
      ),
    };

    final sym = CurrencyHelper.getSymbol(widget.currency);

    return ReorderableDelayedDragStartListener(
      key: ValueKey('section_${type.name}'),
      index: index,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: iconColor.withOpacity(0.5),
                ),
              ),
            ),
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => _toggleSection(type),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($count)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$sym${CurrencyHelper.formatCompact(total)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Asset Item ─────────────────────────────────────────

  Widget _buildAssetCardItem(AssetBase asset, int index) {
    return ReorderableDelayedDragStartListener(
      key: ValueKey('asset_${asset.id}'),
      index: index,
      child: Dismissible(
        key: ValueKey('del_${asset.id}'),
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
        confirmDismiss: (_) => _confirmDelete(asset),
        onDismissed: (_) => _deleteAsset(asset.id),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _buildAssetCard(asset, index),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(AssetBase asset) async {
    final name = asset.name.isNotEmpty ? asset.name : '此项';
    return ConfirmDeleteDialog.show(
      context,
      title: DevConfig.btnConfirm,
      content: '确定要删除 $name 吗？',
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
      leading: ReorderableDragStartListener(
        index: index,
        child: Container(
          width: 28,
          height: 50,
          alignment: Alignment.center,
          child: Icon(Icons.drag_indicator, size: 20, color: Colors.grey[700]),
        ),
      ),
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
      onTap: () => _onEditCash(cash),
      onLongPress: () {},
    );
  }

  Widget _buildTimeDepositCard(TimeDeposit td, int index) {
    final remaining = td.endDate.difference(DateTime.now());
    final daysLeft = remaining.inDays > 0 ? remaining.inDays : 0;
    return AssetCardFrame(
      leading: ReorderableDragStartListener(
        index: index,
        child: Container(
          width: 28,
          height: 50,
          alignment: Alignment.center,
          child: Icon(Icons.drag_indicator, size: 20, color: Colors.grey[700]),
        ),
      ),
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
      onTap: () => _onEditTD(td),
      onLongPress: () {},
    );
  }

  Widget _buildWealthProductCard(WealthProduct wp, int index) {
    return AssetCardFrame(
      leading: ReorderableDragStartListener(
        index: index,
        child: Container(
          width: 28,
          height: 50,
          alignment: Alignment.center,
          child: Icon(Icons.drag_indicator, size: 20, color: Colors.grey[700]),
        ),
      ),
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
      onTap: () => _onEditWP(wp),
      onLongPress: () {},
    );
  }
}
