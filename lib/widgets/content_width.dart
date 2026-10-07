import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

/// Ограничивает ширину содержимого на широких экранах (≥1920).
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMax,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isWideDesktop) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
