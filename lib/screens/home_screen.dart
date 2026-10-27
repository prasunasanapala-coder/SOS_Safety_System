import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/contacts_provider.dart';
import '../providers/settings_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/feature_tile.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/sos_button.dart';
import '../widgets/status_banner.dart';

/// Home dashboard: greeting, safety status, SOS button and shortcuts.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _go(BuildContext context, String route) =>
      Navigator.of(context).pushNamed(route);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final contacts = context.watch<ContactsProvider>();
    final theme = Theme.of(context);
    final name = settings.profile.displayName;
    final hasContacts = contacts.contacts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Safety System'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _go(context, AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            child: FadeSlideIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hello, $name',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Safety status. Mode and contact readiness are shown as text
                  // and icons, never colour alone.
                  StatusBanner(
                    kind: settings.demoMode ? BannerKind.info : BannerKind.warning,
                    title: settings.demoMode ? 'Demo mode is ON' : 'Live mode is ON',
                    message: settings.demoMode
                        ? 'Nothing is sent to anyone. Alerts are only recorded in your own history.'
                        : 'You can open the dialer and message app from the SOS screen. You must press call or send yourself.',
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  if (contacts.loading)
                    const StatusBanner(message: 'Loading your contacts...')
                  else if (!hasContacts)
                    const StatusBanner(
                      kind: BannerKind.warning,
                      title: 'No emergency contacts yet',
                      message: 'Add at least one contact so the SOS screen can list who to alert.',
                    )
                  else
                    StatusBanner(
                      kind: BannerKind.success,
                      message:
                          '${contacts.contacts.length} emergency contact${contacts.contacts.length == 1 ? '' : 's'} ready.',
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: SosButton(onPressed: () => _go(context, AppRoutes.sos)),
                  ),
                  const Center(child: Text('Tap to open the SOS screen')),
                  const SizedBox(height: AppSpacing.lg),
                  ResponsiveWrap(
                    minItemWidth: 170,
                    children: [
                      FeatureTile(
                        icon: Icons.contacts_outlined,
                        title: 'Contacts',
                        subtitle: 'Manage emergency contacts',
                        onTap: () => _go(context, AppRoutes.contacts),
                      ),
                      FeatureTile(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        subtitle: 'View and open your position',
                        onTap: () => _go(context, AppRoutes.location),
                      ),
                      FeatureTile(
                        icon: Icons.tips_and_updates_outlined,
                        title: 'Safety tips',
                        subtitle: 'Advice from the tips service',
                        onTap: () => _go(context, AppRoutes.tips),
                      ),
                      FeatureTile(
                        icon: Icons.history,
                        title: 'SOS history',
                        subtitle: 'Locally recorded events',
                        onTap: () => _go(context, AppRoutes.history),
                      ),
                      FeatureTile(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'Profile, theme, privacy',
                        onTap: () => _go(context, AppRoutes.settings),
                      ),
                    ],
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
