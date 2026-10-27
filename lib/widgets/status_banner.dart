import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum BannerKind { info, success, warning, error }

/// Coloured message strip used for mode notices, errors and results.
/// Always pairs colour with an icon and text so it does not rely on colour alone.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.kind = BannerKind.info,
    this.title,
  });

  final String message;
  final String? title;
  final BannerKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color color, IconData icon) = switch (kind) {
      BannerKind.info => (scheme.primary, Icons.info_outline),
      BannerKind.success => (AppColors.success, Icons.check_circle_outline),
      BannerKind.warning => (AppColors.warning, Icons.warning_amber_outlined),
      BannerKind.error => (scheme.error, Icons.error_outline),
    };

    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}