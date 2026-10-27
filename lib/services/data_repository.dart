import '../models/emergency_contact.dart';
import '../models/sos_record.dart';
import '../models/user_profile.dart';

/// Base class for storage errors with a message safe to show to the user.
class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when a write did not get a server acknowledgement in time. On
/// Android, Firestore keeps the write in its offline queue and syncs later, so
/// this is a notice rather than a hard failure.
class PendingSyncException extends RepositoryException {
  const PendingSyncException()
      : super('Saved on this device. It will sync when you are back online.');
}

/// Contract for private, per-user cloud data. The real implementation is
/// [FirestoreRepository]; tests use an in-memory fake.
///
/// Every method takes the signed-in user's [uid]; all data lives under
/// `users/{uid}` and Firestore rules only let that user touch it.
abstract class DataRepository {
  Stream<List<EmergencyContact>> watchContacts(String uid);

  /// [demoteIds] are other contacts that must stop being primary because the
  /// saved contact is now primary. Done in one batch so there is never more
  /// than one primary contact.
  Future<void> addContact(String uid, EmergencyContact contact,
      {List<String> demoteIds = const []});

  Future<void> updateContact(String uid, EmergencyContact contact,
      {List<String> demoteIds = const []});

  Future<void> deleteContact(String uid, String contactId);

  Future<void> setPrimaryContact(String uid, String primaryId, List<String> allIds);

  Stream<List<SosRecord>> watchHistory(String uid);

  Future<void> addHistory(String uid, SosRecord record);

  Future<void> clearHistory(String uid);

  Future<UserProfile?> getProfile(String uid);

  Future<void> saveProfile(String uid, UserProfile profile);

  /// Stores an FCM device token for the optional notification workflow.
  Future<void> saveFcmToken(String uid, String token, String platform);
}