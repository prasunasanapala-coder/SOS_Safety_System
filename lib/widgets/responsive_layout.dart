import 'package:flutter/material.dart';

import '../utils/breakpoints.dart';

/// Centers page content and limits its width on large screens (Experiment 3).
/// Padding comes from the MediaQuery-based breakpoint.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 1000});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final padding = Breakpoints.pagePadding(Breakpoints.of(context));
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
    );
  }
}

/// Lays children out in as many equal-width columns as fit (LayoutBuilder).
/// A phone gets one or two columns, a desktop browser gets many.
class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({
    super.key,
    required this.children,
    this.minItemWidth = 160,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        var columns = ((available + spacing) / (minItemWidth + spacing)).floor();
        if (columns < 1) columns = 1;
        final itemWidth = (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}