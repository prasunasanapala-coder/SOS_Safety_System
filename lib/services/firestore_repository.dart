import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/emergency_contact.dart';
import '../models/sos_record.dart';
import '../models/user_profile.dart';
import 'data_repository.dart';

/// Cloud Firestore implementation.
///
/// Data model:
///   users/{uid}                       profile + preferences
///   users/{uid}/emergencyContacts/{id}
///   users/{uid}/sosHistory/{id}
///   users/{uid}/fcmTokens/{token}
class FirestoreRepository implements DataRepository {
  FirestoreRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// How long to wait for the server to acknowledge a write. Firestore's
  /// `set()`/`update()` futures only complete after the server confirms, so
  /// without this limit the UI would spin forever while offline.
  static const Duration _ackTimeout = Duration(seconds: 8);

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _contacts(String uid) =>
      _userDoc(uid).collection('emergencyContacts');

  CollectionReference<Map<String, dynamic>> _history(String uid) =>
      _userDoc(uid).collection('sosHistory');

  /// Firestore returns Timestamp objects; the models use plain DateTime.
  static Map<String, dynamic> _withDates(Map<String, dynamic> data) {
    return data.map((key, value) =>
        MapEntry(key, value is Timestamp ? value.toDate() : value));
  }

  /// Runs a write with a timeout and maps Firestore errors to messages.
  Future<void> _write(Future<void> Function() action) async {
    try {
      await action().timeout(_ackTimeout);
    } on TimeoutException {
      throw const PendingSyncException();
    } on FirebaseException catch (e) {
      debugPrint('Firestore write failed: ${e.code}');
      throw RepositoryException(_messageFor(e.code));
    }
  }

  static String _messageFor(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to do that. Please sign in again.';
      case 'unavailable':
        return 'The server is unreachable. Check your connection.';
      case 'not-found':
        return 'That item no longer exists.';
      default:
        return 'Could not complete the request ($code).';
    }
  }

  // ---------------------------------------------------------------- contacts

  @override
  Stream<List<EmergencyContact>> watchContacts(String uid) {
    return _contacts(uid).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => EmergencyContact.fromMap(doc.id, _withDates(doc.data())))
        .toList());
  }

  @override
  Future<void> addContact(String uid, EmergencyContact contact,
      {List<String> demoteIds = const []}) {
    return _write(() {
      final batch = _db.batch();
      batch.set(_contacts(uid).doc(), {
        ...contact.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (final id in demoteIds) {
        batch.update(_contacts(uid).doc(id), {'isPrimary': false});
      }
      return batch.commit();
    });
  }

  @override
  Future<void> updateContact(String uid, EmergencyContact contact,
      {List<String> demoteIds = const []}) {
    return _write(() {
      final batch = _db.batch();
      batch.update(_contacts(uid).doc(contact.id), contact.toMap());
      for (final id in demoteIds) {
        batch.update(_contacts(uid).doc(id), {'isPrimary': false});
      }
      return batch.commit();
    });
  }

  @override
  Future<void> deleteContact(String uid, String contactId) {
    return _write(() => _contacts(uid).doc(contactId).delete());
  }

  @override
  Future<void> setPrimaryContact(String uid, String primaryId, List<String> allIds) {
    return _write(() {
      final batch = _db.batch();
      for (final id in allIds) {
        batch.update(_contacts(uid).doc(id), {'isPrimary': id == primaryId});
      }
      return batch.commit();
    });
  }

  // ----------------------------------------------------------------- history

  @override
  Stream<List<SosRecord>> watchHistory(String uid) {
    return _history(uid).snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => SosRecord.fromMap(doc.id, _withDates(doc.data())))
          .toList();
      // Newest first. A record whose server timestamp is still pending has a
      // null createdAt, so treat it as "now".
      final now = DateTime.now();
      records.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
      return records;
    });
  }

  @override
  Future<void> addHistory(String uid, SosRecord record) {
    return _write(() => _history(uid).doc().set({
          ...record.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        }));
  }

  @override
  Future<void> clearHistory(String uid) {
    return _write(() async {
      final snapshot = await _history(uid).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    });
  }

  // ----------------------------------------------------------------- profile

  @override
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final snapshot = await _userDoc(uid).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return UserProfile.fromMap(data);
    } on FirebaseException catch (e) {
      throw RepositoryException(_messageFor(e.code));
    }
  }

  @override
  Future<void> saveProfile(String uid, UserProfile profile) {
    return _write(() => _userDoc(uid).set({
          ...profile.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)));
  }

  // ------------------------------------------------------------------ tokens

  @override
  Future<void> saveFcmToken(String uid, String token, String platform) {
    return _write(() => _userDoc(uid).collection('fcmTokens').doc(token).set({
          'platform': platform,
          'updatedAt': FieldValue.serverTimestamp(),
        }));
  }
}