import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/services/firestore_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import '../../models/sos_event.dart';
import '../sos/sos_active_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _countdownTimer;
  int _countdownValue = 4;
  bool _isCountingDown = false;
  bool _sosActive = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdownValue = 4;
    });
  }

  Future<void> _startCountdown() async {
    final locationService = context.read<LocationService>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final allowed = await locationService.ensureLocationReady();
    if (!allowed) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            locationService.errorMessage ?? 'Location access is required.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCountingDown = true;
      _countdownValue = 4;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdownValue <= 1) {
        timer.cancel();
        _activateSos();
        return;
      }

      setState(() {
        _countdownValue -= 1;
      });
    });
  }

  Future<void> _activateSos() async {
    if (!mounted) {
      return;
    }

    final locationService = context.read<LocationService>();
    final firestore = context.read<FirestoreService>();
    final notificationService = context.read<NotificationService>();
    final navigator = Navigator.of(context);

    final position = locationService.currentPosition;
    if (position == null) {
      final allowed = await locationService.ensureLocationReady();
      if (!context.mounted) {
        return;
      }
      if (!allowed) {
        setState(() {
          _isCountingDown = false;
          _countdownValue = 4;
        });
        return;
      }
    }

    final targetPosition = locationService.currentPosition!;
    final mapUrl = locationService.buildMapsUrl(
      targetPosition.latitude,
      targetPosition.longitude,
    );
    final message = firestore.emergencyMessage.replaceAll(
      '[Google Maps Link]',
      mapUrl,
    );
    final emergencyContacts = firestore.contacts
        .where((contact) => contact.isEmergencyContact)
        .toList();

    final event = SosEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      latitude: targetPosition.latitude,
      longitude: targetPosition.longitude,
      locationUrl: mapUrl,
      status: 'active',
      message: message,
      contactsNotified: emergencyContacts
          .map((contact) => contact.phone)
          .toList(),
    );

    await firestore.createSosEvent(event);
    await notificationService.sendEmergencyAlert(
      message,
      emergencyContacts.map((contact) => contact.phone).toList(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isCountingDown = false;
      _sosActive = true;
    });

    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => SosActiveScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final firestore = context.watch<FirestoreService>();
    final emergencyContacts = firestore.contacts
        .where((contact) => contact.isEmergencyContact)
        .toList();
    final position = locationService.currentPosition;
    final recentEvents = firestore.sosEvents.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await firestore.loadEmergencyContacts();
            await firestore.loadSosHistory();
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Safety status'),
                        Text(
                          _sosActive ? 'SOS active' : 'Safe mode',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _sosActive
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle,
                    color: _sosActive ? Colors.red : Colors.green,
                    size: 36,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: FittedBox(
                    child: ElevatedButton(
                      onPressed: _isCountingDown ? null : _startCountdown,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        minimumSize: const Size(180, 180),
                        padding: const EdgeInsets.all(32),
                        elevation: 10,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          key: ValueKey<int>(
                            _isCountingDown ? _countdownValue : 0,
                          ),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isCountingDown ? '$_countdownValue' : 'SOS',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isCountingDown ? 'Activating' : 'Tap to trigger',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isCountingDown) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cancel emergency alert'),
                      TextButton(
                        onPressed: _cancelCountdown,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.location_on_outlined),
                          SizedBox(width: 8),
                          Text('Current location'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        position == null
                            ? 'Location unavailable'
                            : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (position != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Updated ${DateFormat('hh:mm a').format(DateTime.now())}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.people_alt_outlined,
                      label: 'Emergency contacts',
                      value: '${emergencyContacts.length}',
                      onTap: () => Navigator.of(context).pushNamed('/contacts'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.history_rounded,
                      label: 'Recent alerts',
                      value: '${recentEvents.length}',
                      onTap: () => Navigator.of(context).pushNamed('/history'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emergency history',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/history'),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recentEvents.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No emergency history yet.'),
                  ),
                )
              else
                ...recentEvents.map(
                  (event) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: event.status == 'active'
                            ? Colors.red.withValues(alpha: 0.12)
                            : Colors.green.withValues(alpha: 0.12),
                        child: Icon(
                          event.status == 'active'
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle,
                          color: event.status == 'active'
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      title: Text(
                        DateFormat('MMM d, yyyy • hh:mm a')
                            .format(event.createdAt),
                      ),
                      subtitle: Text(event.status.toUpperCase()),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
