import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/emergency_contact.dart';
import '../services/data_repository.dart';
import 'op_result.dart';

/// Emergency contacts for the signed-in user, kept in sync with Firestore.
class ContactsProvider extends ChangeNotifier with SafeNotifier {
  ContactsProvider(this._repository);

  final DataRepository _repository;

  String? _uid;
  StreamSubscription<List<EmergencyContact>>? _subscription;
  List<EmergencyContact> _contacts = const [];
  bool _loading = false;
  String? _error;

  List<EmergencyContact> get contacts => _contacts;
  bool get loading => _loading;
  String? get error => _error;

  EmergencyContact? get primary {
    for (final c in _contacts) {
      if (c.isPrimary) return c;
    }
    return null;
  }

  /// Called whenever the signed-in user changes.
  void setUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    _contacts = const [];
    _error = null;
    _loading = uid != null;
    if (uid != null) {
      _subscription = _repository.watchContacts(uid).listen(
        (list) {
          _contacts = _sorted(list);
          _loading = false;
          _error = null;
          notifySafely();
        },
        onError: (Object e) {
          debugPrint('Contacts stream error: $e');
          _loading = false;
          _error = 'Could not load contacts. Check your connection and sign-in.';
          notifySafely();
        },
      );
    }
    notifyLater();
  }

  static List<EmergencyContact> _sorted(List<EmergencyContact> list) {
    final copy = [...list];
    copy.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return copy;
  }

  /// Adds a new contact (empty id) or updates an existing one. Guarantees
  /// that exactly one contact is primary.
  Future<OpResult> save(EmergencyContact contact) {
    final uid = _uid;
    if (uid == null) return Future.value(const OpResult(false, 'You are not signed in.'));

    final others = _contacts.where((c) => c.id != contact.id).toList();
    final needsPrimary = !others.any((c) => c.isPrimary);
    final toSave = (needsPrimary && !contact.isPrimary)
        ? contact.copyWith(isPrimary: true)
        : contact;
    final demoteIds = toSave.isPrimary
        ? others.where((c) => c.isPrimary).map((c) => c.id).toList()
        : <String>[];

    final isNew = toSave.id.isEmpty;
    return runOp(
      () => isNew
          ? _repository.addContact(uid, toSave, demoteIds: demoteIds)
          : _repository.updateContact(uid, toSave, demoteIds: demoteIds),
      isNew ? 'Contact added.' : 'Contact updated.',
    );
  }

  Future<OpResult> delete(EmergencyContact contact) async {
    final uid = _uid;
    if (uid == null) return const OpResult(false, 'You are not signed in.');
    final remaining = _contacts.where((c) => c.id != contact.id).toList();
    final result = await runOp(
      () => _repository.deleteContact(uid, contact.id),
      'Contact deleted.',
    );
    // If the primary contact was removed, promote another so one always exists.
    if (result.ok && contact.isPrimary && remaining.isNotEmpty) {
      await runOp(
        () => _repository.setPrimaryContact(
          uid,
          remaining.first.id,
          remaining.map((c) => c.id).toList(),
        ),
        '',
      );
    }
    return result;
  }

  Future<OpResult> makePrimary(EmergencyContact contact) {
    final uid = _uid;
    if (uid == null) return Future.value(const OpResult(false, 'You are not signed in.'));
    return runOp(
      () => _repository.setPrimaryContact(
        uid,
        contact.id,
        _contacts.map((c) => c.id).toList(),
      ),
      '${contact.name} is now your primary contact.',
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}