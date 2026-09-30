import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final firestore = context.read<FirestoreService>();
        if (firestore.emergencyMessage.isNotEmpty) {
          // message editor is handled in the dialog itself
        }
      }
    });
  }

  Future<void> _signOut() async {
    await context.read<AuthService>().signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final firestore = context.watch<FirestoreService>();
    final locationService = context.watch<LocationService>();
    final notificationService = context.watch<NotificationService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text('Name: ${user?.fullName ?? 'Unknown'}'),
                  Text('Email: ${user?.email ?? 'N/A'}'),
                  Text('Phone: ${user?.phone ?? 'N/A'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Emergency contacts'),
            subtitle: const Text('Manage contact list and priority contacts'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () => Navigator.of(context).pushNamed('/contacts'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Emergency message'),
            subtitle: const Text(
              'Customize the message sent when an SOS is triggered',
            ),
            onTap: () async {
              final controller = TextEditingController(
                text: firestore.emergencyMessage,
              );
              final messenger = ScaffoldMessenger.maybeOf(context);
              final saved = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Edit emergency message'),
                  content: TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Emergency! I may need help. This is my current location: [Google Maps Link]',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        firestore.setEmergencyMessage(controller.text.trim());
                        Navigator.pop(context, true);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (saved == true) {
                messenger?.showSnackBar(
                  const SnackBar(content: Text('Emergency message saved.')),
                );
              }
            },
          ),
          const Divider(),
          SwitchListTile(
            value: locationService.isLocationServiceEnabled,
            title: const Text('Location services'),
            subtitle: const Text('Uses GPS only when needed for SOS alerts'),
            onChanged: (value) async {
              if (value) {
                await locationService.ensureLocationReady();
              }
            },
          ),
          SwitchListTile(
            value: firestore.notificationsEnabled,
            title: const Text('Notifications'),
            subtitle: const Text('Allow emergency notifications and alerts'),
            onChanged: (value) async {
              firestore.setNotificationsEnabled(value);
              if (value) {
                await notificationService.requestPermissions();
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy information'),
            subtitle: const Text(
              'Location is stored privately and not shared publicly.',
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy'),
                  content: const Text(
                    'Your location is used only for the purpose of an active SOS event and is kept private to your account. Not shared publicly or to random contacts.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}
