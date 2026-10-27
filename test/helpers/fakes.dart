import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sos_safety_system/app.dart';
import 'package:sos_safety_system/models/app_user.dart';
import 'package:sos_safety_system/models/emergency_contact.dart';
import 'package:sos_safety_system/models/location_models.dart';
import 'package:sos_safety_system/models/sos_record.dart';
import 'package:sos_safety_system/models/user_profile.dart';
import 'package:sos_safety_system/routes/app_routes.dart';
import 'package:sos_safety_system/services/auth_service.dart';
import 'package:sos_safety_system/services/data_repository.dart';
import 'package:sos_safety_system/services/local_storage_service.dart';
import 'package:sos_safety_system/services/location_service.dart';
import 'package:sos_safety_system/services/notification_service.dart';
import 'package:sos_safety_system/services/tips_api_service.dart';

/// Fake authentication: password "wrongpass" always fails.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? initialUser}) : _user = initialUser;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  final List<String> resetRequests = [];

  @override
  Stream<AppUser?> authStateChanges() {
    return Stream<AppUser?>.multi((controller) {
      controller.add(_user);
      final sub = _controller.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  void _emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (password == 'wrongpass') {
      throw const AuthFailure('Incorrect email or password.');
    }
    _emit(AppUser(uid: 'user-1', email: email, displayName: 'Test User'));
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _emit(AppUser(uid: 'user-new', email: email, displayName: displayName));
  }

  @override
  Future<void> sendPasswordReset(String email) async => resetRequests.add(email);

  @override
  Future<void> signOut() async => _emit(null);
}

/// In-memory stand-in for Firestore. Keeps data per uid.
class InMemoryRepository implements DataRepository {
  final Map<String, List<EmergencyContact>> contacts = {};
  final Map<String, List<SosRecord>> history = {};
  final Map<String, UserProfile> profiles = {};
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  /// When set, streams emit this error (simulates permission/network errors).
  Object? streamError;

  /// When set, every write throws this.
  RepositoryException? writeError;

  Stream<T> _watch<T>(T Function() snapshot) {
    return Stream<T>.multi((controller) {
      if (streamError != null) {
        controller.addError(streamError!);
      } else {
        controller.add(snapshot());
      }
      final sub = _changes.stream.listen((_) => controller.add(snapshot()));
      controller.onCancel = sub.cancel;
    });
  }

  void _checkWrite() {
    if (writeError != null) throw writeError!;
  }

  @override
  Stream<List<EmergencyContact>> watchContacts(String uid) =>
      _watch(() => List.of(contacts[uid] ?? const []));

  @override
  Future<void> addContact(String uid, EmergencyContact contact,
      {List<String> demoteIds = const []}) async {
    _checkWrite();
    final list = contacts.putIfAbsent(uid, () => []);
    for (var i = 0; i < list.length; i++) {
      if (demoteIds.contains(list[i].id)) list[i] = list[i].copyWith(isPrimary: false);
    }
    list.add(contact.copyWith(id: 'c${_nextId++}'));
    _changes.add(null);
  }

  @override
  Future<void> updateContact(String uid, EmergencyContact contact,
      {List<String> demoteIds = const []}) async {
    _checkWrite();
    final list = contacts.putIfAbsent(uid, () => []);
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == contact.id) list[i] = contact;
      if (demoteIds.contains(list[i].id)) list[i] = list[i].copyWith(isPrimary: false);
    }
    _changes.add(null);
  }

  @override
  Future<void> deleteContact(String uid, String contactId) async {
    _checkWrite();
    contacts[uid]?.removeWhere((c) => c.id == contactId);
    _changes.add(null);
  }

  @override
  Future<void> setPrimaryContact(String uid, String primaryId, List<String> allIds) async {
    _checkWrite();
    final list = contacts[uid] ?? [];
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isPrimary: list[i].id == primaryId);
    }
    _changes.add(null);
  }

  @override
  Stream<List<SosRecord>> watchHistory(String uid) =>
      _watch(() => List.of(history[uid] ?? const []));

  @override
  Future<void> addHistory(String uid, SosRecord record) async {
    _checkWrite();
    history.putIfAbsent(uid, () => []).insert(
          0,
          SosRecord(
            id: 'h${_nextId++}',
            status: record.status,
            demoMode: record.demoMode,
            contactCount: record.contactCount,
            locationShared: record.locationShared,
            createdAt: DateTime(2026, 1, 1, 10, 30),
            latitude: record.latitude,
            longitude: record.longitude,
          ),
        );
    _changes.add(null);
  }

  @override
  Future<void> clearHistory(String uid) async {
    _checkWrite();
    history[uid]?.clear();
    _changes.add(null);
  }

  @override
  Future<UserProfile?> getProfile(String uid) async => profiles[uid];

  @override
  Future<void> saveProfile(String uid, UserProfile profile) async {
    _checkWrite();
    profiles[uid] = profile;
  }

  @override
  Future<void> saveFcmToken(String uid, String token, String platform) async {}
}

class FakeLocationService implements LocationService {
  FakeLocationService({this.result, this.error});

  AppPosition? result;
  LocationException? error;
  int calls = 0;

  @override
  Future<AppPosition> getCurrentPosition() async {
    calls++;
    if (error != null) throw error!;
    return result ??
        AppPosition(latitude: 12.34567, longitude: 76.54321, timestamp: DateTime(2026));
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

class FakeNotificationService implements NotificationService {
  @override
  Future<NotificationSetupResult> enable(String uid) async => const NotificationSetupResult(
        NotificationSetupStatus.enabled,
        'Registered (fake).',
      );
}

/// Builds a [TipsApiService] whose HTTP client is a [MockClient].
TipsApiService fakeTipsApi({
  int status = 200,
  Object? body,
  bool throwNetworkError = false,
}) {
  final client = MockClient((request) async {
    if (throwNetworkError) throw http.ClientException('offline');
    return http.Response(
      body is String ? body : jsonEncode(body ?? sampleTipsJson),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
  return TipsApiService(baseUrl: 'http://test.local/tips.json', client: client);
}

const Map<String, Object> sampleTipsJson = {
  'tips': [
    {'id': 'p1', 'category': 'Personal safety', 'title': 'Share your plans', 'body': 'Tell someone where you are going.'},
    {'id': 't1', 'category': 'Travel safety', 'title': 'Use licensed transport', 'body': 'Check vehicle details.'},
  ],
};

/// Everything a test needs: the app plus handles to its fakes.
class TestHarness {
  TestHarness({
    required this.deps,
    required this.auth,
    required this.repository,
    required this.location,
  });

  final AppDependencies deps;
  final FakeAuthService auth;
  final InMemoryRepository repository;
  final FakeLocationService location;

  Widget app({String initialRoute = AppRoutes.gate}) =>
      SosApp(deps: deps, initialRoute: initialRoute);
}

/// Creates fakes. Pass [signedIn] true to start with a signed-in user.
Future<TestHarness> createHarness({
  bool signedIn = false,
  bool onboardingSeen = true,
  TipsApiService? tipsApi,
  FakeLocationService? location,
  List<EmergencyContact> initialContacts = const [],
}) async {
  SharedPreferences.setMockInitialValues({'onboarding_seen': onboardingSeen});
  final prefs = await SharedPreferences.getInstance();
  final auth = FakeAuthService(
    initialUser: signedIn
        ? const AppUser(uid: 'user-1', email: 'test@example.com', displayName: 'Test User')
        : null,
  );
  final repository = InMemoryRepository();
  if (initialContacts.isNotEmpty) repository.contacts['user-1'] = [...initialContacts];
  repository.profiles['user-1'] = UserProfile.defaults(displayName: 'Test User');
  final fakeLocation = location ?? FakeLocationService();
  return TestHarness(
    deps: AppDependencies(
      auth: auth,
      repository: repository,
      location: fakeLocation,
      tipsApi: tipsApi ?? fakeTipsApi(),
      storage: LocalStorageService(prefs),
      notifications: FakeNotificationService(),
    ),
    auth: auth,
    repository: repository,
    location: fakeLocation,
  );
}

/// Pumps a few frames. We avoid pumpAndSettle because the SOS button runs a
/// repeating animation that never "settles".
Future<void> pumpFrames(WidgetTester tester, {int count = 10}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Gives the test window a bigger size so whole screens fit without scrolling.
void useTallScreen(WidgetTester tester, {Size size = const Size(800, 1600)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const EmergencyContact testContactA = EmergencyContact(
  id: 'a1',
  name: 'Test Contact A',
  phone: '+10000000001',
  relationship: 'Friend',
  isPrimary: true,
);

const EmergencyContact testContactB = EmergencyContact(
  id: 'b1',
  name: 'Test Contact B',
  phone: '+10000000002',
  relationship: 'Sibling',
  isPrimary: false,
);