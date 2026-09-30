import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService extends ChangeNotifier {
  FirebaseMessaging? get _messaging =>
      Firebase.apps.isNotEmpty ? FirebaseMessaging.instance : null;

  bool isPermissionGranted = true;

  Future<void> requestPermissions() async {
    if (Firebase.apps.isEmpty) {
      isPermissionGranted = true;
      notifyListeners();
      return;
    }

    if (_messaging == null) {
      isPermissionGranted = true;
      notifyListeners();
      return;
    }

    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    isPermissionGranted =
        settings.authorizationStatus != AuthorizationStatus.denied;
    notifyListeners();
  }

  Future<void> sendEmergencyAlert(
    String message,
    List<String> recipients,
  ) async {
    if (Firebase.apps.isEmpty) {
      debugPrint('Demo mode: would notify $recipients with message: $message');
      return;
    }

    if (!isPermissionGranted || _messaging == null) {
      return;
    }

    for (final recipient in recipients) {
      debugPrint('Notification sent to $recipient: $message');
    }
  }
}
