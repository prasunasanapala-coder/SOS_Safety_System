# Debugging (Experiment 10b)

This document has two parts: a **deliberate bug exercise** you can repeat for your lab record, and a list of **real problems** met while building the project.

---

## Part A: Deliberate bug exercise

### The bug

In `lib/providers/sos_provider.dart`, `_tick` ends the countdown when the remaining time reaches zero:

```dart
void _tick(Timer timer) {
  _remaining--;
  if (_remaining <= 0) {   // correct
    _cancelTimer();
    unawaited(_initiate());
  } else {
    notifySafely();
  }
}
```

Introduce an off-by-one error by changing `<=` to `<`:

```dart
  if (_remaining < 0) {    // BUG: alert starts one second late
```

### What the bug does

The countdown shows `0` and then waits another second before initiating. The alert fires one second later than the user was told, which matters in a safety app.

### Step 1: reproduce with the tests

```powershell
flutter test test/providers/sos_provider_test.dart
```

Expected outcome: the test "countdown ticks once per second, then the alert is initiated" fails because the state is still `preparing` when `initiated` was expected. Other tests that wait for the alert also fail (for example in `test/screens/sos_flow_test.dart`). Copy the first failure message into your record. Its shape is:

```
Expected: SosState:<SosState.initiated>
  Actual: SosState:<SosState.preparing>
```

### Step 2: read the failure

- Which test failed and on which line?
- What was expected and what was received?
- Which method updates `state`? (`_tick` and `_initiate`)

### Step 3: narrow it down with prints

Add a temporary line at the top of `_tick`:

```dart
debugPrint('tick: remaining=$_remaining state=$_state');
```

Run the single test again. The output shows the countdown reaching `0` while the state is still `preparing`, which points at the condition.

### Step 4: use the debugger (VS Code)

1. Set a breakpoint on the `if (_remaining < 0)` line (click left of the line number).
2. In the test file, click **Debug** above the failing test.
3. When execution stops, hover over `_remaining` or look at the Variables panel. It is `0`, and the condition is false.
4. Step over (F10) and confirm the `else` branch runs.

### Step 5: fix and prove the fix

Restore `<=`, remove the debug print, and rerun:

```powershell
flutter test
```

All tests should pass again. Screenshot the failing run and the passing run as `debugging_output.png` (two images, or one that shows both).

### Lesson for the record

A boundary condition (`<` versus `<=`) is exactly what a unit test with a fake clock catches. The widget tests use `tester.pump(Duration(seconds: 1))` to move time forward without waiting.

### Other tools to mention

- `flutter analyze` finds problems before running.
- Flutter DevTools: Widget Inspector (layout, overflow), Logging and Network tabs.
- The "RenderFlex overflowed" yellow-black stripes show a layout overflow; the console names the widget.
- Hot reload keeps state; hot restart resets it.

---

## Part B: Real problems met while building this project

These are genuine issues that came up, with the cause and fix. They make good additions to the record.

| # | Symptom | Cause | Fix |
|---|---|---|---|
| 1 | `mkdir -p assets/images ...` failed in PowerShell | `-p` is a Unix option | `New-Item -ItemType Directory -Force -Path ...` |
| 2 | `npm.ps1 cannot be loaded` | PowerShell execution policy blocks the script | Use `npm.cmd` |
| 3 | `flutterfire` is not recognised | The pub cache folder was not on `PATH` | `dart pub global run flutterfire_cli:flutterfire configure` |
| 4 | `flutterfire configure` failed on the iOS app | iOS registration was attempted without an iOS setup | `--platforms=android,web` |
| 5 | Analyzer errors about `AppRoutes` and `firebase_options.dart` | The files did not exist yet | Added `app_routes.dart`; generated `firebase_options.dart` with `flutterfire configure` |
| 6 | Tips screen showed a network error | The mock server was not running | Start `dart run tool/mock_api/server.dart` |
| 7 | `SocketException ... errno = 10013` on port 8080 | Windows blocked binding that port | Run the server on port 8787 and pass `--dart-define=TIPS_API_URL=...` |
| 8 | Could not remember the sign-in details | Normal user problem | Used the "Forgot password" reset flow |
| 9 | `Flutter failed to delete a directory at "build\unit_test_assets"` | A running process and OneDrive sync held files in `build` | Stopped Dart processes, moved the project out of OneDrive to `C:\dev` |
| 10 | `The name 'RepositoryException' isn't a class` in a test | The import was missing | Added `import 'package:sos_safety_system/services/data_repository.dart';` |
| 11 | `prefer_initializing_formals` analyzer infos | Style lint on provider constructors | Optional refactor to `required this._repository` |

For items 5 and 7, keep the original terminal output as evidence if you captured it.