import 'package:flutter/material.dart';

/// Fades a child in while sliding it up slightly (Experiment 8).
/// Implemented with [TweenAnimationBuilder], which needs no controller.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.offset = 20,
  });

  final Widget child;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * offset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
