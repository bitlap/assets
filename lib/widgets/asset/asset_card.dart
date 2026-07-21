import 'package:flutter/material.dart';

class AssetCardFrame extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Widget trailing;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Widget? leading;

  const AssetCardFrame({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.name,
    this.createdAt,
    this.updatedAt,
    required this.trailing,
    required this.onTap,
    required this.onLongPress,
    this.leading,
  });

  String _f(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _timestamps(DateTime? c, DateTime? u) {
    return SizedBox(
      height: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (c != null)
            Text(
              '创建:${_f(c)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          if (c != null && u != null) const SizedBox(height: 2),
          if (u != null)
            Text(
              '更新:${_f(u)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF303631)),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              leading ?? const SizedBox(width: 4),
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
                          _timestamps(createdAt, updatedAt),
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
}
