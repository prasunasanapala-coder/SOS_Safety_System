import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/firestore_service.dart';
import '../sos/sos_active_screen.dart';

class SosHistoryScreen extends StatefulWidget {
  const SosHistoryScreen({super.key});

  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FirestoreService>().loadSosHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final events = firestore.sosEvents;

    return Scaffold(
      appBar: AppBar(title: const Text('SOS history')),
      body: events.isEmpty
          ? const Center(child: Text('No SOS events recorded yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${event.status.toUpperCase()}'),
                        Text(
                          'Location: ${event.latitude.toStringAsFixed(4)}, ${event.longitude.toStringAsFixed(4)}',
                        ),
                        Text('Event ID: ${event.id}'),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SosActiveScreen(event: event),
                        ),
                      );
                    },
                    trailing: IconButton(
                      onPressed: () async {
                        final uri = Uri.parse(event.locationUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.map_outlined),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
