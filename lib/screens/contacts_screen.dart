import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/emergency_contact.dart';
import '../providers/contacts_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_card.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/state_views.dart';

/// List of emergency contacts with add / edit / delete / make-primary.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  void _openForm(BuildContext context, [EmergencyContact? contact]) {
    // Navigator.pushNamed passes the contact as `arguments` (Experiment 4).
    Navigator.of(context).pushNamed(AppRoutes.contactForm, arguments: contact);
  }

  Future<void> _handleAction(
    BuildContext context,
    EmergencyContact contact,
    ContactAction action,
  ) async {
    final provider = context.read<ContactsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case ContactAction.edit:
        _openForm(context, contact);
      case ContactAction.makePrimary:
        {
          final result = await provider.makePrimary(contact);
          messenger.showSnackBar(SnackBar(content: Text(result.message)));
        }
      case ContactAction.delete:
        {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete contact?'),
              content: Text('${contact.name} will be removed from your emergency contacts.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  key: const Key('confirm_delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
          final result = await provider.delete(contact);
          messenger.showSnackBar(SnackBar(content: Text(result.message)));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContactsProvider>();
    final Widget body;
    if (provider.loading) {
      body = const LoadingView(label: 'Loading contacts...');
    } else if (provider.error != null) {
      body = ErrorView(message: provider.error!);
    } else if (provider.contacts.isEmpty) {
      body = EmptyState(
        icon: Icons.contacts_outlined,
        title: 'No emergency contacts',
        message: 'Add the people you trust. The first one becomes your primary contact.',
        actionLabel: 'Add contact',
        onAction: () => _openForm(context),
      );
    } else {
      body = SingleChildScrollView(
        child: ResponsiveCenter(
          child: ResponsiveWrap(
            minItemWidth: 380,
            spacing: AppSpacing.sm + 4,
            children: [
              for (final contact in provider.contacts)
                ContactCard(
                  contact: contact,
                  onAction: (action) => _handleAction(context, contact, action),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency contacts')),
      body: SafeArea(child: body),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_contact_fab'),
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add contact'),
      ),
    );
  }
}