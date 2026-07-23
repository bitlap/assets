import 'package:flutter/material.dart';
import '../../utils/currency_helper.dart';
import '../../config/app_config.dart';
import '../../config/asset_config.dart';

// Section Title

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
                StockConfig.tabAsset,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AssetConfig.assetCountLabel.replaceAll(
                  '{count}',
                  '$assetCount',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                  height: 1.2,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3A3A3C), width: 0.5),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// Header (Summary Card)

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
        color: Color(0xFF000000),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Color(0xFF1C1C1E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                StockConfig.assetTotalAssets,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                  height: 1.2,
                ),
              ),
              GestureDetector(
                onTap: onCurrencyTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF3A3A3C),
                    borderRadius: BorderRadius.circular(10),
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
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _summaryChip(
                Icons.show_chart,
                StockConfig.tabStock,
                CurrencyHelper.formatCompact(stockTotalValue),
                iconColor: const Color(0xFF5B9CF6),
              ),
              const SizedBox(width: 8),
              _summaryChip(
                Icons.account_balance,
                AssetConfig.depositWealthLabel,
                CurrencyHelper.formatCompact(totalAssets - stockTotalValue),
                iconColor: const Color(0xFFFF9F0A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _summaryChip(
  IconData icon,
  String label,
  String value, {
  Color iconColor = const Color(0xFF8E8E93),
}) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8E8E93),
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ],
    ),
  );
}
