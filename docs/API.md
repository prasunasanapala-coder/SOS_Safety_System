# Tips API (mock)

Experiment 9 needs a REST call. No public safety-tips API was verified for this project, so the app uses a small **mock** server that you run yourself. It is clearly a mock: the content is general advice written for this project.

## Run the mock server

From the project root (so it can find `mock_api/tips.json`):

```powershell
dart run tool/mock_api/server.dart 8787
```

The optional argument is the port (default 8080). If the port is blocked on Windows (`errno = 10013`), choose another one.

## Point the app at it

The app reads the URL from a compile-time define. There is no API key.

```powershell
flutter run -d chrome --dart-define=TIPS_API_URL=http://localhost:8787/tips.json
```

If `TIPS_API_URL` is not set, the default is `http://localhost:8080/tips.json`, or `http://10.0.2.2:8080/tips.json` on an Android emulator (10.0.2.2 is how the emulator reaches your PC).

## Endpoints

| Path | Behaviour | Used to demonstrate |
|---|---|---|
| `GET /tips.json` | 200 with the tips list | Success state |
| `GET /empty` | 200 with `{"tips": []}` | Empty state |
| `GET /error` | Server error status | Error state |
| `GET /slow` | Responds after a delay | Loading state and timeout |

To try an alternate state, run the app with that path, for example `--dart-define=TIPS_API_URL=http://localhost:8787/error`.

## Response format

```json
{
  "tips": [
    {
      "id": "p1",
      "category": "Personal safety",
      "title": "Share your plans",
      "body": "Tell a trusted person where you are going and when you expect to be back."
    }
  ]
}
```

All four fields are required text. `TipsApiService` skips any item that is missing a field and keeps the valid ones.

## How the app handles problems

| Situation | Message shown |
|---|---|
| Non-200 status | "The tips server responded with status N." |
| Not valid JSON | "The tips server sent invalid data." |
| Wrong shape (no `tips` list) | "The tips server sent an unexpected format." |
| No connection / server not running | "Could not reach the tips server. ..." |
| No answer within 10 seconds | "The request timed out. Please try again." |
| Empty list | The "No tips available" screen with Reload |

Every error screen has a **Try again** button.

## Android notes

Plain `http://` is blocked by default on Android release builds. The debug manifest allows cleartext for development only (`usesCleartextTraffic`). A real deployment should use `https://`.

## Tests

`test/services/tips_api_service_test.dart` and `test/screens/tips_screen_test.dart` use an `http` `MockClient`, so they never need the server.