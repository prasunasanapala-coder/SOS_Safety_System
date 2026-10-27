# Screenshot checklist and final verification

Take screenshots only from your own running app and consoles. Use test data and fake numbers. Blur emails, user ids and any key before adding images to a report. Do not edit screenshots to add content that was not on screen.

Save images in `docs/screenshots/` with these names.

## App screenshots

| ☐ | File | What to capture | How |
|---|---|---|---|
| ☐ | `splash_screen.png` | Splash / onboarding with "Get started" | Clear data on device in Settings, relaunch |
| ☐ | `login_screen.png` | Login screen | Signed out |
| ☐ | `home_dashboard.png` | Home with greeting, demo banner, SOS button, tiles | Signed in, contacts present |
| ☐ | `emergency_contacts.png` | Contact list showing the Primary chip | Two fake contacts |
| ☐ | `contact_form_validation.png` | Form with validation errors | Press Save with empty fields |
| ☐ | `sos_screen.png` | Countdown running (State: preparing) | Press SOS |
| ☐ | `sos_initiated.png` | "Demo alert initiated" state | Let the countdown finish |
| ☐ | `location_screen.png` | Location screen with coordinates | Use the demo location button if permission is not given |
| ☐ | `safety_tips.png` | Tips loaded from the mock server | Mock server running |
| ☐ | `tips_error.png` | Error state with Try again | Stop the mock server and reload |
| ☐ | `sos_history.png` | History list with an entry | After an SOS |
| ☐ | `settings_screen.png` | Settings | Signed in |
| ☐ | `dark_theme.png` | Any screen in dark theme | Settings → Appearance → Dark |
| ☐ | `responsive_mobile.png` | Home at phone width | Browser dev-tools device mode, about 400 px |
| ☐ | `responsive_desktop.png` | Home at desktop width | Maximised browser window |

## Test and debugging evidence

| ☐ | File | What to capture |
|---|---|---|
| ☐ | `dart_basics_output.png` | Terminal after `dart run tool/dart_basics.dart` |
| ☐ | `flutter_analyze.png` | `flutter analyze` result |
| ☐ | `widget_test_output.png` | `flutter test` ending with "All tests passed!" |
| ☐ | `debugging_output.png` | Failing run with the seeded bug and the passing run after the fix |

## Firebase evidence

| ☐ | File | What to capture |
|---|---|---|
| ☐ | `firebase_auth_users.png` | Authentication users list (blur emails) |
| ☐ | `firestore_data.png` | Firestore showing `users/{uid}/emergencyContacts` (blur ids) |
| ☐ | `firestore_rules.png` | The published rules in the console |
| ☐ | `rules_playground_deny.png` | A denied request (other user or unauthenticated) |
| ☐ | `rules_playground_allow.png` | An allowed owner request |
| ☐ | `two_account_isolation.png` | Account B seeing an empty list while A has contacts |

## Final verification checklist

Tick each item only after you have checked it yourself.

### Code
- ☐ `flutter pub get` succeeds
- ☐ `flutter analyze` reports no errors (note any remaining infos)
- ☐ `flutter test` passes
- ☐ App starts on Chrome and Android emulator or device
- ☐ Mock server runs and the tips screen loads

### Safety rules
- ☐ Fresh account starts in **demo mode**
- ☐ Demo mode: the call and message buttons show an explanation and do not open any app
- ☐ Turning demo mode off asks for confirmation
- ☐ No screen claims a message, call or notification was sent or delivered
- ☐ Only fake numbers appear in contacts and screenshots

### Firebase
- ☐ Email/Password sign-in enabled
- ☐ Firestore created in production mode (not test mode)
- ☐ Rules published from `firestore.rules`
- ☐ Rules Playground tests recorded
- ☐ Two-account isolation test done
- ☐ Spark plan still active; no billing added

### Repository hygiene
- ☐ `lib/firebase_options.dart` and `android/app/google-services.json` are in `.gitignore`
- ☐ No keys, tokens or real phone numbers in the repository
- ☐ README setup steps work from a clean clone
- ☐ Project folder is outside OneDrive (for example `C:\dev`)

### Report
- ☐ Every screenshot is real and named as above
- ☐ Test results in the report are copied from your own run
- ☐ Limitations section matches `docs/LIMITATIONS.md`