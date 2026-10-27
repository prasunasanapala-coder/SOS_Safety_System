import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sos_record.dart';
import '../services/data_repository.dart';
import 'op_result.dart';

/// SOS history for the signed-in user (a live Firestore stream).
class HistoryProvider extends ChangeNotifier with SafeNotifier {
  HistoryProvider(this._repository);

  final DataRepository _repository;

  String? _uid;
  StreamSubscription<List<SosRecord>>? _subscription;
  List<SosRecord> _records = const [];
  bool _loading = false;
  String? _error;

  List<SosRecord> get records => _records;
  bool get loading => _loading;
  String? get error => _error;

  void setUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    _records = const [];
    _error = null;
    _loading = uid != null;
    if (uid != null) {
      _subscription = _repository.watchHistory(uid).listen(
        (list) {
          _records = list;
          _loading = false;
          _error = null;
          notifySafely();
        },
        onError: (Object e) {
          debugPrint('History stream error: $e');
          _loading = false;
          _error = 'Could not load history. Check your connection and sign-in.';
          notifySafely();
        },
      );
    }
    notifyLater();
  }

  Future<OpResult> clear() {
    final uid = _uid;
    if (uid == null) return Future.value(const OpResult(false, 'You are not signed in.'));
    return runOp(() => _repository.clearHistory(uid), 'SOS history cleared.');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
