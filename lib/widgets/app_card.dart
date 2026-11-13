import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Карточка приложения: тёмная, со скруглёнными углами.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color = surfaceColor,
    this.gradient,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
