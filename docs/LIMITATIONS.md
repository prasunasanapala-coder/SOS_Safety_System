# Known limitations and future work

## Safety and scope

- **Prototype only.** It is not a certified or monitored emergency service. It must not be relied on in a real emergency.
- **Nothing is sent automatically.** No SMS, call or emergency-service contact is ever made by the app.
- **Demo mode is the default.** In live mode the app can open the dialer or message app, but the user must press call or send. Opening them does not confirm that anyone was reached.
- **Contacts are not verified.** Phone numbers are checked only for format, not ownership or reachability.

## Technical limitations

- **Notifications:** the app registers a device token but cannot send notifications. Sending needs Cloud Functions on the paid Blaze plan (see `FCM_DESIGN.md`). Web notifications are not set up.
- **Tips API is a mock** you run yourself. There is no production tips service, and the tips are general advice, not professional guidance.
- **Cleartext HTTP** is allowed in debug builds only so the Android emulator can reach the mock server.
- **Offline behaviour:** writes that Firestore cannot acknowledge within 8 seconds are reported as "saved on this device, will sync later". The app does not show a per-item sync indicator.
- **Location:** accuracy depends on the device and permissions. On web, the browser prompts for permission and results vary. Location is optional and never required for an alert.
- **Platforms:** Android and Web only. iOS is not configured, and desktop builds are untested.
- **Single language** (English) and no localisation.
- **Accessibility** has basic labels and tooltips but has not been audited with a screen reader on real devices.
- **Security review:** the Firestore rules were written carefully and are tested with the Rules Playground, but they have not been independently audited.
- **Testing:** unit and widget tests use fakes. There are no integration tests against real Firebase and no device-level tests (for example real geolocator or url_launcher behaviour).
- **Account recovery** relies on Firebase password reset email only. Account deletion from inside the app is not implemented.

## Future work

1. Link contacts to real accounts with consent, then notify them through FCM using a Cloud Function (design in `FCM_DESIGN.md`).
2. Share a live location link for a limited time, with clear user control.
3. Offline-first queue with a visible sync state.
4. Integration tests with the Firebase Emulator Suite.
5. iOS support and localisation.
6. In-app account and data deletion.
7. A hosted, versioned tips service with review of the content by a qualified source.
8. Accessibility audit and larger-text testing.
9. Automatic continuous integration running `flutter analyze` and `flutter test`.