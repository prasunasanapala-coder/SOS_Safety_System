import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/emergency_contact.dart';
import '../providers/contacts_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/responsive_layout.dart';

/// Add or edit one contact (Experiments 7a, 7b: several input types + validation).
///
/// Receives the contact to edit through `RouteSettings.arguments`; a null
/// argument means "add new".
class ContactFormScreen extends StatefulWidget {
  const ContactFormScreen({super.key});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  static const List<String> _suggestions = [
    'Parent',
    'Sibling',
    'Friend',
    'Partner',
    'Neighbour',
    'Colleague',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  EmergencyContact? _editing;
  bool _isPrimary = false;
  bool _saving = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is EmergencyContact) {
      _editing = args;
      _nameController.text = args.name;
      _phoneController.text = args.phone;
      _relationshipController.text = args.relationship;
      _isPrimary = args.isPrimary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final provider = context.read<ContactsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);
    final contact = EmergencyContact(
      id: _editing?.id ?? '',
      name: _nameController.text.trim(),
      phone: Validators.normalizePhone(_phoneController.text.trim()),
      relationship: _relationshipController.text.trim(),
      isPrimary: _isPrimary,
    );
    final result = await provider.save(contact);
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
    if (result.ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit contact' : 'Add contact')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxWidth: 560,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('name_field'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: AppStyles.input('Full name', icon: Icons.person_outline),
                    validator: Validators.name,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('phone_field'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: AppStyles.input(
                      'Phone number',
                      icon: Icons.phone_outlined,
                      hint: 'Digits, optionally starting with +',
                    ),
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('relationship_field'),
                    controller: _relationshipController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    decoration: AppStyles.input('Relationship', icon: Icons.group_outlined),
                    validator: Validators.relationship,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final label in _suggestions)
                        ActionChip(
                          label: Text(label),
                          onPressed: () => _relationshipController.text = label,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    key: const Key('primary_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Primary contact'),
                    subtitle: const Text('Shown first and used for the SOS message shortcut.'),
                    value: _isPrimary,
                    onChanged: (value) => setState(() => _isPrimary = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    key: const Key('save_contact_button'),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(isEditing ? 'Save changes' : 'Add contact'),
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