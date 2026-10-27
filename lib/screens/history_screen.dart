import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sos_record.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/state_views.dart';
import '../widgets/status_banner.dart';

/// Live list of SOS events from Firestore.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final provider = context.read<HistoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear SOS history?'),
        content: const Text('All recorded SOS events will be deleted from your account. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm_clear_history'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await provider.clear();
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final Widget body;
    if (history.loading) {
      body = const LoadingView(label: 'Loading history...');
    } else if (history.error != null) {
      body = ErrorView(message: history.error!);
    } else if (history.records.isEmpty) {
      body = const EmptyState(
        icon: Icons.history,
        title: 'No SOS events yet',
        message: 'Events appear here after you start or cancel an SOS countdown.',
      );
    } else {
      body = SingleChildScrollView(
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StatusBanner(
                title: 'Locally recorded events',
                message:
                    'These entries record what this prototype did. They do not confirm that any call, SMS or notification was delivered to anyone.',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final record in history.records) ...[
                _RecordTile(record: record),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS history'),
        actions: [
          if (history.records.isNotEmpty)
            IconButton(
              key: const Key('clear_history_button'),
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final SosRecord record;

  @override
  Widget build(BuildContext context) {
    final initiated = record.status == SosStatus.initiated;
    final details = <String>[
      record.demoMode ? 'Demo mode' : 'Live mode',
      '${record.contactCount} contact${record.contactCount == 1 ? '' : 's'} listed',
      record.locationShared ? 'Location included' : 'No location',
    ];
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: AppStyles.cardShape(context),
      child: ListTile(
        leading: Icon(initiated ? Icons.warning_amber_rounded : Icons.cancel_outlined),
        title: Text(record.status.label),
        subtitle: Text('${Formatters.dateTime(record.createdAt)}\n${details.join(' • ')}'),
        isThreeLine: true,
        trailing: const Tooltip(
          message: 'Locally recorded event',
          child: Icon(Icons.save_outlined),
        ),
      ),
    );
  }
}