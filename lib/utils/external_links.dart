import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] in another app (browser, maps, dialer, SMS app).
///
/// This only *hands over* to another app. It never places a call or sends a
/// message by itself: the user must press the call/send button there. Returns
/// false when nothing could handle the link.
Future<bool> openExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('openExternal failed for $uri: $e');
    return false;
  }
}