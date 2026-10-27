import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/emergency_contact.dart';
import '../providers/contacts_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sos_provider.dart';
import '../theme/app_theme.dart';
import '../utils/external_links.dart';
import '../utils/validators.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/sos_button.dart';
import '../widgets/status_banner.dart';

/// SOS workflow screen: idle -> preparing (countdown) -> initiated | cancelled.
class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();
    final contacts = context.watch<ContactsProvider>().contacts;
    final settings = context.watch<SettingsProvider>();

    final statePanel = _StatePanel(sos: sos, contacts: contacts, settings: settings);
    final infoPanel = _InfoPanel(sos: sos, contacts: contacts, settings: settings);

    return Scaffold(
      appBar: AppBar(title: const Text('SOS alert')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Two columns on wide screens, one column on phones.
                if (constraints.maxWidth >= 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: statePanel),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: infoPanel),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [statePanel, const SizedBox(height: AppSpacing.lg), infoPanel],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({required this.sos, required this.contacts, required this.settings});

  final SosProvider sos;
  final List<EmergencyContact> contacts;
  final SettingsProvider settings;

  Future<void> _start(BuildContext context) async {
    var proceed = true;
    if (contacts.isEmpty) {
      proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No emergency contacts'),
              content: const Text(
                'You have no emergency contacts saved, so nobody is listed for this alert. Start the countdown anyway?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Go back'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Start anyway'),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!proceed || !context.mounted) return;
    context.read<SosProvider>().start(
          seconds: settings.profile.countdownSeconds,
          contactCount: contacts.length,
          demoMode: settings.demoMode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (sos.state) {
      case SosState.idle:
        return Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            SosButton(onPressed: () => _start(context)),
            const SizedBox(height: AppSpacing.md),
            Text('State: idle', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Press SOS to start a cancellable countdown.',
              textAlign: TextAlign.center,
            ),
          ],
        );
      case SosState.preparing:
        return Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Text('State: preparing', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              label: '${sos.remainingSeconds} seconds until alert',
              child: Text(
                '${sos.remainingSeconds}',
                key: const Key('countdown_value'),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: AppColors.sos,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Text('seconds until the alert is initiated'),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              key: const Key('cancel_button'),
              onPressed: () => context.read<SosProvider>().cancel(),
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
          ],
        );
      case SosState.initiated:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text('State: alert initiated', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            StatusBanner(
              kind: BannerKind.warning,
              title: sos.demoMode ? 'Demo alert initiated' : 'Alert initiated',
              message: sos.demoMode
                  ? 'DEMO: no call, SMS or notification was sent to anyone.'
                  : 'Nothing was sent automatically. Use the buttons below to open the dialer or message app, then press call or send yourself. Opening them does not confirm delivery.',
            ),
            const SizedBox(height: AppSpacing.md),
            _ActionButtons(sos: sos, contacts: contacts, settings: settings),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              key: const Key('done_button'),
              onPressed: () => context.read<SosProvider>().reset(),
              child: const Text('Done'),
            ),
          ],
        );
      case SosState.cancelled:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text('State: cancelled', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            const StatusBanner(
              kind: BannerKind.success,
              message: 'The countdown was cancelled. No alert was initiated.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              key: const Key('done_button'),
              onPressed: () => context.read<SosProvider>().reset(),
              child: const Text('Done'),
            ),
          ],
        );
    }
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.sos, required this.contacts, required this.settings});

  final SosProvider sos;
  final List<EmergencyContact> contacts;
  final SettingsProvider settings;

  Future<void> _demoNotice(BuildContext context, String what) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo mode'),
        content: Text('$what is disabled in demo mode so nobody is contacted by accident. Turn demo mode off in Settings to use it.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  /// Builds an sms: link that only pre-fills the message. The user still has to
  /// press send in their messaging app.
  static Uri _smsUri(String phone, SosProvider sos) {
    final location =
        sos.position == null ? '' : ' My location: ${sos.position!.mapUri}';
    final body =
        'I need help. This message was prepared by the SOS Safety System app.$location';
    return Uri.parse('sms:${Validators.normalizePhone(phone)}?body=${Uri.encodeComponent(body)}');
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await openExternal(uri);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No app on this device can handle that action.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = contacts.where((c) => c.isPrimary).firstOrNull;
    final number = settings.profile.emergencyNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('call_button'),
          icon: const Icon(Icons.call),
          label: Text('Open dialer for $number'),
          onPressed: () => settings.demoMode
              ? _demoNotice(context, 'Opening the dialer')
              : _open(context, Uri(scheme: 'tel', path: number)),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('sms_button'),
          icon: const Icon(Icons.sms_outlined),
          label: Text(primary == null
              ? 'No primary contact to message'
              : 'Open message to ${primary.name}'),
          onPressed: primary == null
              ? null
              : () => settings.demoMode
                  ? _demoNotice(context, 'Opening the message app')
                  : _open(context, _smsUri(primary.phone, sos)),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.sos, required this.contacts, required this.settings});

  final SosProvider sos;
  final List<EmergencyContact> contacts;
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = sos.state == SosState.preparing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusBanner(
          kind: settings.demoMode ? BannerKind.info : BannerKind.warning,
          title: settings.demoMode ? 'Demo mode' : 'Live mode',
          message: settings.demoMode
              ? 'No call or SMS is ever started. The alert is only recorded in your SOS history.'
              : 'The dialer and message app can be opened after the alert. The app never sends anything by itself.',
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Contacts to alert', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (contacts.isEmpty)
          const Text('No contacts saved yet. Add some from the Contacts screen.')
        else
          for (final contact in contacts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(contact.isPrimary ? Icons.star : Icons.person_outline),
              title: Text(contact.name),
              subtitle: Text(contact.relationship),
            ),
        const SizedBox(height: AppSpacing.md),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: AppStyles.cardShape(context),
          child: SwitchListTile(
            key: const Key('share_location_switch'),
            title: const Text('Include my location'),
            subtitle: const Text(
              'Your device location is read only when an alert starts, saved in your own history, and never shared with anyone else by this app.',
            ),
            value: sos.shareLocation,
            onChanged: locked ? null : (value) => context.read<SosProvider>().setShareLocation(value),
          ),
        ),
        if (sos.locationNote != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Location: ${sos.locationNote}'),
        ],
        if (sos.recordNote != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('History: ${sos.recordNote}', key: const Key('record_note')),
        ],
      ],
    );
  }
}