import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/data_repository.dart';

/// Result of a write operation, ready to show in a SnackBar.
class OpResult {
  const OpResult(this.ok, this.message);

  /// True when the operation succeeded, or was queued for sync (still fine).
  final bool ok;
  final String message;
}

/// Runs [action] and converts any exception into an [OpResult].
Future<OpResult> runOp(Future<void> Function() action, String successMessage) async {
  try {
    await action();
    return OpResult(true, successMessage);
  } on PendingSyncException catch (e) {
    return OpResult(true, e.message);
  } on RepositoryException catch (e) {
    return OpResult(false, e.message);
  } catch (e) {
    debugPrint('Unexpected error: $e');
    return const OpResult(false, 'Something went wrong. Please try again.');
  }
}

/// ChangeNotifier that is safe to notify after it was disposed or while the
/// widget tree is building (providers are updated during build when the signed
/// in user changes).
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  /// Notifies after the current frame's build phase.
  void notifyLater() {
    scheduleMicrotask(() {
      if (!_disposed) notifyListeners();
    });
  }

  void notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}