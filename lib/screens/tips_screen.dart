import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tips_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/state_views.dart';
import '../widgets/tip_card.dart';

/// Safety tips fetched from the REST API (Experiment 9).
/// Handles loading, success, empty and error states.
class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  @override
  void initState() {
    super.initState();
    // Load once when the screen opens (after the first frame, so we are not
    // notifying listeners while the tree is building).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tips = context.read<TipsProvider>();
      if (tips.status == TipsStatus.idle || tips.status == TipsStatus.error) {
        tips.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tips = context.watch<TipsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety tips'),
        actions: [
          IconButton(
            tooltip: 'Reload tips',
            icon: const Icon(Icons.refresh),
            onPressed: tips.status == TipsStatus.loading
                ? null
                : () => context.read<TipsProvider>().load(),
          ),
        ],
      ),
      body: SafeArea(child: _body(context, tips)),
    );
  }

  Widget _body(BuildContext context, TipsProvider tips) {
    switch (tips.status) {
      case TipsStatus.idle:
      case TipsStatus.loading:
        return const LoadingView(label: 'Loading tips...');
      case TipsStatus.error:
        return ErrorView(
          message: tips.error ?? 'Could not load tips.',
          onRetry: () => context.read<TipsProvider>().load(),
        );
      case TipsStatus.empty:
        return EmptyState(
          icon: Icons.tips_and_updates_outlined,
          title: 'No tips available',
          message: 'The tips service returned an empty list.',
          actionLabel: 'Reload',
          onAction: () => context.read<TipsProvider>().load(),
        );
      case TipsStatus.loaded:
        final visible = tips.visibleTips;
        return SingleChildScrollView(
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: tips.selectedCategory == null,
                      onSelected: (_) =>
                          context.read<TipsProvider>().selectCategory(null),
                    ),
                    for (final category in tips.categories)
                      ChoiceChip(
                        label: Text(category),
                        selected: tips.selectedCategory == category,
                        onSelected: (_) => context
                            .read<TipsProvider>()
                            .selectCategory(category),
                      ),
                    FilterChip(
                      key: const Key('favorites_filter'),
                      avatar: const Icon(Icons.favorite, size: 18),
                      label: const Text('Favourites'),
                      selected: tips.favoritesOnly,
                      onSelected: (value) =>
                          context.read<TipsProvider>().setFavoritesOnly(value),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: Text('No tips match this filter.')),
                  )
                else
                  ResponsiveWrap(
                    minItemWidth: 340,
                    children: [
                      for (final tip in visible)
                        TipCard(
                          key: ValueKey(tip.id),
                          tip: tip,
                          isFavorite: tips.isFavorite(tip.id),
                          onToggleFavorite: () => context
                              .read<TipsProvider>()
                              .toggleFavorite(tip.id),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
    }
  }
}
