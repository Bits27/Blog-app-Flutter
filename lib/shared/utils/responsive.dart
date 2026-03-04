// Responsive helpers for breakpoint checks and adaptive value selection.
import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

class Responsive {
  static ScreenSize of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;

    if (shortestSide < 600) return ScreenSize.compact;
    if (shortestSide < 900) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static bool isCompact(BuildContext context) =>
      of(context) == ScreenSize.compact;
  static bool isMedium(BuildContext context) =>
      of(context) == ScreenSize.medium;
  static bool isExpanded(BuildContext context) =>
      of(context) == ScreenSize.expanded;
  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static double value(
    BuildContext context, {
    required double compact,
    required double medium,
    required double expanded,
  }) {
    switch (of(context)) {
      case ScreenSize.compact:
        return compact;
      case ScreenSize.medium:
        return medium;
      case ScreenSize.expanded:
        return expanded;
    }
  }

  static double adaptiveImageHeight(
    BuildContext context, {
    required double compact,
    required double medium,
    required double expanded,
    double? compactLandscape,
  }) {
    final isCompactScreen = isCompact(context);
    if (isCompactScreen && isLandscape(context) && compactLandscape != null) {
      return compactLandscape;
    }
    return value(context, compact: compact, medium: medium, expanded: expanded);
  }
}
