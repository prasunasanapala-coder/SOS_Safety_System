import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/responsive_layout.dart';

/// Splash + onboarding (Experiment 2a: Text, Image, Container, Icon, Card).
///
/// First launch: explains the app and waits for "Get started".
/// Later launches: shows the logo briefly, then continues automatically.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _autoContinue;
  bool _seenBefore = false;

  @override
  void initState() {
    super.initState();
    final storage = context.read<LocalStorageService>();
    _seenBefore = storage.onboardingSeen;
    if (_seenBefore) {
      _autoContinue = Timer(const Duration(milliseconds: 1500), _continue);
    }
  }

  @override
  void dispose() {
    _autoContinue?.cancel();
    super.dispose();
  }

  void _continue() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.gate);
  }

  Future<void> _getStarted() async {
    await context.read<LocalStorageService>().setOnboardingSeen(true);
    _continue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxWidth: 640,
            child: FadeSlideIn(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  // Image widget with a safe fallback if the asset is missing.
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      semanticLabel: 'SOS Safety System logo',
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'SOS Safety System',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Quick access to your emergency contacts, location and safety tips.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!_seenBefore) ...[
                    const _InfoRow(
                      icon: Icons.contacts_outlined,
                      title: 'Keep contacts ready',
                      text: 'Store the people you trust and pick a primary contact.',
                    ),
                    const _InfoRow(
                      icon: Icons.timer_outlined,
                      title: 'Cancellable SOS countdown',
                      text: 'A countdown prevents accidental alerts and can be cancelled.',
                    ),
                    const _InfoRow(
                      icon: Icons.location_on_outlined,
                      title: 'Share location on your terms',
                      text: 'Location is read only after you allow it and choose to share.',
                    ),
                    const _InfoRow(
                      icon: Icons.science_outlined,
                      title: 'Academic prototype',
                      text:
                          'Demo mode is on by default. This app is not a real emergency service and never contacts emergency services by itself.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _getStarted,
                      child: const Text('Get started'),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      shape: AppStyles.cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}