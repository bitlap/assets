import 'package:flutter/material.dart';

class DraggableFab extends StatefulWidget {
  final VoidCallback onTap;
  final double maxHeight;

  const DraggableFab({super.key, required this.onTap, required this.maxHeight});

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  late double _fabY;
  bool _initialized = false;
  static const double _fabSize = 56.0;

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _fabY = (widget.maxHeight - _fabSize) / 2;
      _initialized = true;
    }

    return Positioned(
      right: 16,
      top: _fabY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _fabY = (_fabY + details.delta.dy).clamp(
              20,
              widget.maxHeight - _fabSize - 20,
            );
          });
        },
        onTap: widget.onTap,
        child: Container(
          width: _fabSize,
          height: _fabSize,
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
    );
  }
}
