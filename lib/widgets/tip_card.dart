import 'package:flutter/material.dart';

import '../models/safety_tip.dart';
import '../theme/app_theme.dart';

/// One safety tip. A StatelessWidget (Experiment 5a): it owns no state, the
/// parent passes `isFavorite` and gets a callback.
class TipCard extends StatelessWidget {
  const TipCard({
    super.key,
    required this.tip,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final SafetyTip tip;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: AppStyles.cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(tip.category),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isFavorite ? 'Remove from favourites' : 'Add to favourites',
                  onPressed: onToggleFavorite,
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                ),
              ],
            ),
            Text(tip.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(tip.body),
          ],
        ),
      ),
    );
  }
}