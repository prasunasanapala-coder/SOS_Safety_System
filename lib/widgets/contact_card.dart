import 'package:flutter/material.dart';

import '../models/emergency_contact.dart';
import '../theme/app_theme.dart';

enum ContactAction { edit, makePrimary, delete }

/// One emergency contact row (Card + ListTile).
class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.contact,
    required this.onAction,
  });

  final EmergencyContact contact;
  final ValueChanged<ContactAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = contact.name.isEmpty ? '?' : contact.name[0].toUpperCase();
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: AppStyles.cardShape(context),
      child: ListTile(
        leading: CircleAvatar(child: Text(initial)),
        title: Row(
          children: [
            Flexible(child: Text(contact.name, overflow: TextOverflow.ellipsis)),
            if (contact.isPrimary) ...[
              const SizedBox(width: AppSpacing.sm),
              Chip(
                label: const Text('Primary'),
                visualDensity: VisualDensity.compact,
                avatar: Icon(Icons.star, size: 16, color: theme.colorScheme.primary),
              ),
            ],
          ],
        ),
        subtitle: Text('${contact.relationship} • ${contact.phone}'),
        trailing: PopupMenuButton<ContactAction>(
          tooltip: 'Contact options',
          onSelected: onAction,
          itemBuilder: (context) => [
            const PopupMenuItem(value: ContactAction.edit, child: Text('Edit')),
            if (!contact.isPrimary)
              const PopupMenuItem(
                value: ContactAction.makePrimary,
                child: Text('Make primary'),
              ),
            const PopupMenuItem(value: ContactAction.delete, child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}