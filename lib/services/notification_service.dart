import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'data_repository.dart';

enum NotificationSetupStatus { enabled, denied, unsupported, error }

class NotificationSetupResult {
  const NotificationSetupResult(this.status, this.message);

  final NotificationSetupStatus status;
  final String message;
}

/// Client side of the optional Firebase Cloud Messaging workflow.
///
/// What this does: asks for notification permission, reads this device's FCM
/// token, stores it under `users/{uid}/fcmTokens/{token}` and keeps it fresh
/// when Firebase rotates it.
///
/// What this does NOT do: send anything. Sending needs a trusted server (for
/// example Cloud Functions, which require the paid Blaze plan). See
/// `docs/FCM_DESIGN.md`. A stored token is only a *request-ready* device, never
/// proof that a notification was delivered.
abstract class NotificationService {
  Future<NotificationSetupResult> enable(String uid);
}

class FcmNotificationService implements NotificationService {
  FcmNotificationService(this._repository);

  final DataRepository _repository;
  bool _listening = false;

  @override
  Future<NotificationSetupResult> enable(String uid) async {
    if (kIsWeb) {
      return const NotificationSetupResult(
        NotificationSetupStatus.unsupported,
        'Push notifications are only set up for Android in this prototype.',
      );
    }
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) {
        return const NotificationSetupResult(
          NotificationSetupStatus.denied,
          'Notification permission was not granted.',
        );
      }

      final token = await messaging.getToken();
      if (token == null) {
        return const NotificationSetupResult(
          NotificationSetupStatus.error,
          'Could not get a device token.',
        );
      }
      await _repository.saveFcmToken(uid, token, defaultTargetPlatform.name);

      // Tokens can change (reinstall, restore, expiry). Store the new one.
      if (!_listening) {
        _listening = true;
        messaging.onTokenRefresh.listen((newToken) {
          _repository
              .saveFcmToken(uid, newToken, defaultTargetPlatform.name)
              .catchError((Object e) => debugPrint('Token refresh save failed: $e'));
        });
      }
      return const NotificationSetupResult(
        NotificationSetupStatus.enabled,
        'This device is registered for notifications. Nothing is sent automatically.',
      );
    } on RepositoryException catch (e) {
      return NotificationSetupResult(NotificationSetupStatus.error, e.message);
    } catch (e) {
      debugPrint('FCM setup failed: $e');
      return const NotificationSetupResult(
        NotificationSetupStatus.error,
        'Notification setup failed on this device.',
      );
    }
  }
}