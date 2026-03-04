// Reusable elevated card with the app's ink-like border/shadow style.
import 'package:flutter/material.dart';

class InkCard extends StatelessWidget {
  const InkCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1F231F20), width: 2),
      ),
      child: child,
    );
  }
}
