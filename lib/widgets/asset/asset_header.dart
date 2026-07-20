import 'package:flutter/material.dart';
import '../../utils/currency_helper.dart';
import '../../models/asset_account.dart';
import '../../config/app_config.dart';
import '../common/sort_indicator.dart';

// ─── Section Title ─────────────────────────────────────────

class AssetSectionTitle extends StatelessWidget {
  final int assetCount;
  final VoidCallback onAdd;

  const AssetSectionTitle({
    super.key,
    required this.assetCount,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
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
                '共 $assetCount 项资产',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                  height: 1.2,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Color(0xFF5B9CF6), size: 30),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}

// ─── Header (Summary Card) ─────────────────────────────────

class AssetHeader extends StatelessWidget {
  final double totalAssets;
  final double stockTotalValue;
  final String currency;
  final VoidCallback onCurrencyTap;

  const AssetHeader({
    super.key,
    required this.totalAssets,
    required this.stockTotalValue,
    required this.currency,
    required this.onCurrencyTap,
  });

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '总资产',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.2,
                ),
              ),
              GestureDetector(
                onTap: onCurrencyTap,
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
                        currency,
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
            '${CurrencyHelper.getSymbol(currency)}${CurrencyHelper.formatCompact(totalAssets)}',
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
              _summaryChip(
                Icons.show_chart,
                '股票',
                CurrencyHelper.formatCompact(stockTotalValue),
              ),
              const SizedBox(width: 8),
              _summaryChip(
                Icons.account_balance,
                '存款理财',
                CurrencyHelper.formatCompact(totalAssets - stockTotalValue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _summaryChip(IconData icon, String label, String value) {
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

// ─── List Header (Sort/Filter) ─────────────────────────────

class AssetListHeader extends StatelessWidget {
  final AssetType? filterType;
  final String? sortColumn;
  final bool sortAscending;
  final VoidCallback onFilterTap;
  final ValueChanged<String> onSortTap;

  const AssetListHeader({
    super.key,
    this.filterType,
    this.sortColumn,
    this.sortAscending = true,
    required this.onFilterTap,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 28, 2),
      child: Row(
        children: [
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 24,
              alignment: Alignment.center,
              child: Icon(
                filterType != null
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                size: 18,
                color: filterType != null ? Colors.blue : Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => onSortTap('name'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 44),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '名称',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: sortColumn == 'name'
                                ? const Color(0xFF5B9CF6)
                                : Colors.grey[500],
                            height: 1.2,
                          ),
                        ),
                        SortIndicator(
                          isActive: sortColumn == 'name',
                          isAscending: sortAscending,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => onSortTap('amount'),
              behavior: HitTestBehavior.opaque,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '金额',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: sortColumn == 'amount'
                              ? const Color(0xFF5B9CF6)
                              : Colors.grey[500],
                          height: 1.2,
                        ),
                      ),
                      SortIndicator(
                        isActive: sortColumn == 'amount',
                        isAscending: sortAscending,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Menu ───────────────────────────────────────────

void showAssetFilterMenu(
  BuildContext context, {
  required AssetType? currentFilter,
  required ValueChanged<AssetType?> onFilterChanged,
}) {
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
          _filterOption(
            ctx,
            currentFilter,
            null,
            '全部',
            Icons.all_inclusive,
            null,
            onFilterChanged,
          ),
          const SizedBox(height: 4),
          _filterOption(
            ctx,
            currentFilter,
            AssetType.cash,
            '现金',
            Icons.payments,
            Colors.teal,
            onFilterChanged,
          ),
          const SizedBox(height: 4),
          _filterOption(
            ctx,
            currentFilter,
            AssetType.timeDeposit,
            '定期存款',
            Icons.savings,
            Colors.orange,
            onFilterChanged,
          ),
          const SizedBox(height: 4),
          _filterOption(
            ctx,
            currentFilter,
            AssetType.wealthProduct,
            '理财/基金',
            Icons.trending_up,
            Colors.blueAccent,
            onFilterChanged,
          ),
        ],
      ),
    ),
  );
}

Widget _filterOption(
  BuildContext ctx,
  AssetType? currentFilter,
  AssetType? type,
  String label,
  IconData icon,
  Color? color,
  ValueChanged<AssetType?> onChanged,
) {
  final selected = currentFilter == type;
  return GestureDetector(
    onTap: () {
      onChanged(type);
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
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: 12),
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
