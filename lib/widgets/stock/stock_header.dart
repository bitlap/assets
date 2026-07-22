import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class StockSectionTitle extends StatelessWidget {
  final int stockCount;
  final VoidCallback onAddTap;
  final VoidCallback onSettingsTap;

  const StockSectionTitle({
    super.key,
    required this.stockCount,
    required this.onAddTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                StockConfig.homeTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                StockConfig.homeSubtitle.replaceAll('{count}', '$stockCount'),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: onAddTap,
                icon: const Icon(Icons.add, color: Color(0xFF5B9CF6), size: 30),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                onPressed: onSettingsTap,
                icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
