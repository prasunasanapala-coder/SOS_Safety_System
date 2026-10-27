import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tips_provider.dart';
import '../routes/app_routes.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/state_views.dart';
import '../widgets/status_banner.dart';

/// Profile, safety preferences, theme, privacy and sign-out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();

  bool _initialised = false;
  bool _demoMode = true;
  int _countdown = UserProfile.defaultCountdown;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  /// Copies the stored profile into the form once it has loaded.
  void _initFrom(UserProfile profile) {
    _nameController.text = profile.displayName;
    _numberController.text = profile.emergencyNumber;
    _demoMode = profile.demoMode;
    _countdown = profile.countdownSeconds;
    _initialised = true;
  }

  Future<void> _onDemoChanged(bool value) async {
    if (value) {
      setState(() => _demoMode = true);
      return;
    }
    // Turning demo mode OFF needs an explicit confirmation.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turn off demo mode?'),
        content: const Text(
          'In live mode the SOS screen can open your phone dialer and message app. The app still never calls or sends anything by itself, but real contacts could be reached if you press call or send. Use test numbers only while developing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep demo mode'),
          ),
          TextButton(
            key: const Key('confirm_live_mode'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) setState(() => _demoMode = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final result = await settings.saveProfile(
      settings.profile.copyWith(
        displayName: _nameController.text.trim(),
        emergencyNumber: _numberController.text.trim(),
        demoMode: _demoMode,
        countdownSeconds: _countdown,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _clearHistory() async {
    final history = context.read<HistoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirm(
      'Clear SOS history?',
      'All recorded SOS events will be deleted from your account.',
      'Clear',
    )) {
      return;
    }
    final result = await history.clear();
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _clearLocalData() async {
    final storage = context.read<LocalStorageService>();
    final tips = context.read<TipsProvider>();
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirm(
      'Clear data on this device?',
      'This removes the saved theme, favourite tips and onboarding flag from this device. Your account data in the cloud is not affected.',
      'Clear',
    )) {
      return;
    }
    await storage.clearAll();
    tips.resetLocalState();
    await settings.setThemeMode(ThemeMode.system);
    messenger.showSnackBar(const SnackBar(content: Text('Device data cleared.')));
  }

  Future<void> _enableNotifications() async {
    final uid = context.read<AuthProvider>().uid;
    final service = context.read<NotificationService>();
    final messenger = ScaffoldMessenger.of(context);
    if (uid == null) return;
    final result = await service.enable(uid);
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    if (!await _confirm('Sign out?', 'You will need to sign in again to see your data.', 'Sign out')) {
      return;
    }
    await auth.signOut();
    navigator.pushNamedAndRemoveUntil(AppRoutes.gate, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    if (settings.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const LoadingView(label: 'Loading your settings...'),
      );
    }
    if (!_initialised) _initFrom(settings.profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxWidth: 720,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (settings.error != null) ...[
                    StatusBanner(kind: BannerKind.warning, message: settings.error!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text('Profile', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    key: const Key('display_name_field'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: AppStyles.input('Display name', icon: Icons.person_outline),
                    validator: Validators.name,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(auth.user?.email ?? 'Unknown'),
                  ),
                  const Divider(),
                  Text('Safety preferences', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    key: const Key('demo_mode_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Demo mode'),
                    subtitle: const Text(
                      'On: the SOS screen never opens the dialer or message app. Recommended for testing and demonstrations.',
                    ),
                    value: _demoMode,
                    onChanged: _onDemoChanged,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Countdown before alert: $_countdown seconds'),
                  Slider(
                    value: _countdown.toDouble(),
                    min: UserProfile.minCountdown.toDouble(),
                    max: UserProfile.maxCountdown.toDouble(),
                    divisions: UserProfile.maxCountdown - UserProfile.minCountdown,
                    label: '$_countdown s',
                    onChanged: (value) => setState(() => _countdown = value.round()),
                  ),
                  TextFormField(
                    key: const Key('emergency_number_field'),
                    controller: _numberController,
                    keyboardType: TextInputType.phone,
                    decoration: AppStyles.input(
                      'Emergency number for the dialer shortcut',
                      icon: Icons.call_outlined,
                      hint: 'For example 112',
                    ),
                    validator: Validators.emergencyNumber,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    key: const Key('save_settings_button'),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Save changes'),
                  ),
                  const Divider(height: AppSpacing.xl),
                  Text('Appearance', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) =>
                        context.read<SettingsProvider>().setThemeMode(selection.first),
                  ),
                  const Divider(height: AppSpacing.xl),
                  Text('Notifications (optional prototype)', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Registers this device for Firebase Cloud Messaging. Nothing is sent from the app, and a registered device is not proof that any notification was delivered.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _enableNotifications,
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Register this device'),
                  ),
                  const Divider(height: AppSpacing.xl),
                  Text('Privacy', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  const ExpansionTile(
                    title: Text('What this app stores'),
                    childrenPadding: EdgeInsets.all(AppSpacing.md),
                    children: [
                      Text(
                        'Account: your email and password are handled by Firebase Authentication; the password is never stored by this app.\n\n'
                        'Cloud (only you can read it): display name, safety preferences, emergency contacts, SOS history and optional device token.\n\n'
                        'Location: read only after you press a button or switch on location for an alert; stored only inside your own SOS record.\n\n'
                        'This device: theme, favourite tip ids and the onboarding flag.\n\n'
                        'This is an academic prototype, not a production emergency service.',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _clearHistory,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear SOS history (cloud)'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _clearLocalData,
                    icon: const Icon(Icons.phone_android),
                    label: const Text('Clear data on this device'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.tonalIcon(
                    key: const Key('sign_out_button'),
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
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