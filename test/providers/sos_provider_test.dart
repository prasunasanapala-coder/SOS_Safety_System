import 'package:flutter_test/flutter_test.dart';
import 'package:sos_safety_system/models/location_models.dart';
import 'package:sos_safety_system/models/sos_record.dart';
import 'package:sos_safety_system/providers/sos_provider.dart';

import '../helpers/fakes.dart';

void main() {
  late InMemoryRepository repository;
  late FakeLocationService location;
  late SosProvider sos;

  setUp(() {
    repository = InMemoryRepository();
    location = FakeLocationService();
    sos = SosProvider(repository: repository, locationService: location);
    sos.setUser('user-1');
  });

  tearDown(() => sos.dispose());

  testWidgets('countdown ticks once per second, then the alert is initiated', (tester) async {
    expect(sos.state, SosState.idle);

    sos.start(seconds: 3, contactCount: 2, demoMode: true);
    expect(sos.state, SosState.preparing);
    expect(sos.remainingSeconds, 3);

    await tester.pump(const Duration(seconds: 1));
    expect(sos.remainingSeconds, 2);
    expect(sos.state, SosState.preparing);

    await tester.pump(const Duration(seconds: 1));
    expect(sos.remainingSeconds, 1);
    expect(sos.state, SosState.preparing);

    await tester.pump(const Duration(seconds: 1));
    expect(sos.state, SosState.initiated);

    // Let the history write finish.
    await tester.pump(const Duration(milliseconds: 10));
    final records = repository.history['user-1']!;
    expect(records.length, 1);
    expect(records.single.status, SosStatus.initiated);
    expect(records.single.demoMode, isTrue);
    expect(records.single.contactCount, 2);
    expect(records.single.locationShared, isFalse);
  });

  testWidgets('cancel stops the countdown and records a cancelled event', (tester) async {
    sos.start(seconds: 5, contactCount: 1, demoMode: true);
    await tester.pump(const Duration(seconds: 1));

    sos.cancel();
    await tester.pump(const Duration(milliseconds: 10));

    expect(sos.state, SosState.cancelled);
    // No further ticks after cancelling.
    await tester.pump(const Duration(seconds: 10));
    expect(sos.state, SosState.cancelled);
    expect(repository.history['user-1']!.single.status, SosStatus.cancelled);
  });

  testWidgets('location is read only when sharing is switched on', (tester) async {
    sos.setShareLocation(true);
    sos.start(seconds: 1, contactCount: 0, demoMode: true);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 10));

    expect(location.calls, 1);
    expect(sos.position, isNotNull);
    expect(repository.history['user-1']!.single.locationShared, isTrue);
  });

  testWidgets('location is NOT read when sharing is off', (tester) async {
    sos.start(seconds: 1, contactCount: 0, demoMode: true);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 10));

    expect(location.calls, 0);
    expect(sos.position, isNull);
  });

  testWidgets('a location failure does not stop the alert from being recorded', (tester) async {
    location.error = const LocationException(
      LocationFailure.denied,
      'Location permission was denied.',
    );
    sos.setShareLocation(true);
    sos.start(seconds: 1, contactCount: 0, demoMode: true);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 10));

    expect(sos.state, SosState.initiated);
    expect(sos.locationNote, contains('not included'));
    expect(repository.history['user-1']!.single.locationShared, isFalse);
  });

  testWidgets('reset returns to idle', (tester) async {
    sos.start(seconds: 1, contactCount: 0, demoMode: true);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 10));

    sos.reset();
    expect(sos.state, SosState.idle);
  });
}