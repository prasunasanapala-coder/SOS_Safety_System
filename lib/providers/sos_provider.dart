import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/location_models.dart';
import '../models/sos_record.dart';
import '../services/data_repository.dart';
import '../services/location_service.dart';
import 'op_result.dart';

/// The states of the SOS workflow.
enum SosState { idle, preparing, initiated, cancelled }

/// Runs the SOS countdown and records the outcome.
///
/// IMPORTANT: this workflow never sends an SMS, never places a call and never
/// contacts emergency services. Initiating an alert only (1) changes the
/// on-screen state and (2) writes a record to the user's own history.
class SosProvider extends ChangeNotifier with SafeNotifier {
     SosProvider({
    required this._repository,
    required this._locationService,
  });

  final DataRepository _repository;
  final LocationService _locationService;

  String? _uid;
  Timer? _timer;

  SosState _state = SosState.idle;
  int _remaining = 0;
  bool _shareLocation = false;
  bool _demoMode = true;
  int _contactCount = 0;
  AppPosition? _position;
  String? _locationNote;
  String? _recordNote;

  SosState get state => _state;
  int get remainingSeconds => _remaining;
  bool get shareLocation => _shareLocation;
  bool get demoMode => _demoMode;
  AppPosition? get position => _position;
  String? get locationNote => _locationNote;
  String? get recordNote => _recordNote;

  void setUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _cancelTimer();
    _resetFields();
    notifyLater();
  }

  /// Location is only read when the user switches this on AND an alert starts.
  void setShareLocation(bool value) {
    _shareLocation = value;
    notifySafely();
  }

  /// Starts the cancellable countdown.
  void start({
    required int seconds,
    required int contactCount,
    required bool demoMode,
  }) {
    if (_state == SosState.preparing) return;
    _resetFields();
    _demoMode = demoMode;
    _contactCount = contactCount;
    _remaining = seconds;
    _state = SosState.preparing;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifySafely();
  }

  void _tick(Timer timer) {
    _remaining--;
    if (_remaining <= 0) {
      _cancelTimer();
      unawaited(_initiate());
    } else {
      notifySafely();
    }
  }

  Future<void> _initiate() async {
    _state = SosState.initiated;
    _remaining = 0;
    notifySafely();

    if (_shareLocation) {
      try {
        _position = await _locationService.getCurrentPosition();
        _locationNote = 'Location included in the record.';
      } on LocationException catch (e) {
        _locationNote = 'Location not included: ${e.message}';
      } catch (_) {
        _locationNote = 'Location not included: unexpected error.';
      }
      notifySafely();
    } else {
      _locationNote = 'Location sharing is off.';
    }

    await _record(SosStatus.initiated);
  }

  /// Cancels the countdown. Does nothing if no countdown is running.
  Future<void> cancel() async {
    if (_state != SosState.preparing) return;
    _cancelTimer();
    _state = SosState.cancelled;
    _remaining = 0;
    notifySafely();
    await _record(SosStatus.cancelled);
  }

  /// Returns to the idle state after the user has read the result.
  void reset() {
    _cancelTimer();
    _resetFields();
    notifySafely();
  }

  Future<void> _record(SosStatus status) async {
    final uid = _uid;
    if (uid == null) return;
    final result = await runOp(
      () => _repository.addHistory(
        uid,
        SosRecord(
          id: '',
          status: status,
          demoMode: _demoMode,
          contactCount: _contactCount,
          locationShared: _position != null,
          latitude: _position?.latitude,
          longitude: _position?.longitude,
        ),
      ),
      'Locally recorded in your SOS history.',
    );
    _recordNote = result.ok
        ? result.message
        : 'Could not record this event: ${result.message}';
    notifySafely();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetFields() {
    _state = SosState.idle;
    _remaining = 0;
    _position = null;
    _locationNote = null;
    _recordNote = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
