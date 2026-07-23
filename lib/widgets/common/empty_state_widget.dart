import 'package:flutter/material.dart';

/// 通用空状态组件 - 居中显示图标 + 标题 + 副标题
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final double iconSize;
  final EdgeInsets padding;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconSize = 48,
    this.padding = const EdgeInsets.all(40),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: Color(0xFF48484A)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(color: Color(0xFF636366), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
