import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/firestore_service.dart';
import '../../models/emergency_contact.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FirestoreService>().loadEmergencyContacts();
      }
    });
  }

  Future<void> _showContactDialog({EmergencyContact? contact}) async {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final relationshipController = TextEditingController(
      text: contact?.relationship ?? '',
    );
    final isPrimary = contact?.isEmergencyContact ?? true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(contact == null ? 'Add contact' : 'Edit contact'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final firestore = context.read<FirestoreService>();
                final nextContact = EmergencyContact(
                  id:
                      contact?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  relationship: relationshipController.text.trim(),
                  isEmergencyContact: isPrimary,
                  createdAt: contact?.createdAt ?? DateTime.now(),
                );

                await firestore.saveContact(nextContact);
                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final contacts = firestore.contacts;

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactDialog(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add contact'),
      ),
      body: contacts.isEmpty
          ? const Center(child: Text('No emergency contacts added yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: contact.isEmergencyContact
                          ? Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.person_outline,
                        color: contact.isEmergencyContact
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                    title: Text(contact.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.phone),
                        Text(contact.relationship),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'toggle') {
                          await firestore.saveContact(
                            contact.copyWith(
                              isEmergencyContact: !contact.isEmergencyContact,
                            ),
                          );
                        }
                        if (value == 'edit') {
                          await _showContactDialog(contact: contact);
                        }
                        if (value == 'delete') {
                          final dialogContext = context;
                          final confirmed = await showDialog<bool>(
                            context: dialogContext,
                            builder: (builderContext) => AlertDialog(
                              title: const Text('Delete contact?'),
                              content: const Text(
                                'This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(builderContext, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(builderContext, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await firestore.deleteContact(contact.id);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            contact.isEmergencyContact
                                ? 'Mark as non-emergency'
                                : 'Mark as emergency',
                          ),
                        ),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
