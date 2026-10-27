# Firebase setup

This project uses the free **Spark** plan: Authentication (email/password), Cloud Firestore, and the client side of Cloud Messaging. Nothing here needs billing.

## 1. Create the project

1. Open the Firebase console and create a project (this one uses id `sos-safety-system-e6eae`; use your own).
2. Keep the Spark plan.

## 2. Install the tools (Windows PowerShell)

```powershell
npm.cmd install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

If `npm` is blocked by the execution policy, `npm.cmd` avoids it. If `flutterfire` is not found, run it through Dart as shown below.

## 3. Connect the app

From the project root:

```powershell
dart pub global run flutterfire_cli:flutterfire configure --project=sos-safety-system-e6eae --platforms=android,web
```

- `--platforms=android,web` skips iOS. An iOS registration attempt failed during this project, and iOS is out of scope.
- This generates `lib/firebase_options.dart` and `android/app/google-services.json`.
- Do not commit these to a public repository. Add them to `.gitignore`:

```
lib/firebase_options.dart
android/app/google-services.json
```

Anyone cloning the project runs the command above with their own project.

## 4. Enable Authentication

Console → Build → Authentication → Get started → Sign-in method → **Email/Password** → Enable.

## 5. Create Firestore

Console → Build → Firestore Database → Create database.

- Choose **production mode**. Do **not** use test mode.
- Pick a region close to you.

## 6. Publish the security rules

The rules are in `firestore.rules`. Either paste the file into Console → Firestore → Rules → Publish, or deploy:

```powershell
firebase deploy --only firestore:rules
```

What the rules enforce:

- Everything lives under `users/{uid}`; only the signed-in owner can read or write it.
- Profile, contact, SOS event and token documents must have exactly the expected fields and valid values (lengths, types, countdown 3 to 10, coordinates in range).
- Timestamps must equal the server time (`request.time`), so a client cannot back-date a record.
- SOS history is append-only (no updates), and user profile documents cannot be deleted.
- Everything else is denied.

## 7. Data model

```
users/{uid}                          displayName, demoMode, emergencyNumber, countdownSeconds, updatedAt
users/{uid}/emergencyContacts/{id}   name, phone, relationship, isPrimary, createdAt
users/{uid}/sosHistory/{id}          status, demoMode, contactCount, locationShared, [latitude, longitude], createdAt
users/{uid}/fcmTokens/{token}        platform, updatedAt
```

## 8. Test the rules (your evidence)

Use Console → Firestore → Rules → **Rules Playground**. Use a made-up uid; never real data.

| # | Test | Expected |
|---|---|---|
| 1 | Unauthenticated `get` on `/users/abc123` | Denied |
| 2 | Authenticated as `abc123`, `get` `/users/abc123` | Allowed |
| 3 | Authenticated as `other456`, `get` `/users/abc123` | Denied |
| 4 | `abc123` creates `/users/abc123/emergencyContacts/c1` with a valid contact | Allowed |
| 5 | Same create with `phone` of 3 characters | Denied |
| 6 | Same create with an extra field such as `admin: true` | Denied |
| 7 | `update` on `/users/abc123/sosHistory/e1` | Denied (append-only) |
| 8 | `delete` on `/users/abc123` | Denied |
| 9 | Any access to `/somethingElse/doc1` | Denied |

Screenshot a few of these (see `SCREENSHOT_CHECKLIST.md`).

### Two-account isolation test in the real app

1. Register account A, add one contact.
2. Sign out, register account B. Confirm B's contact list is empty.
3. In the Firestore console, confirm the data sits under two different `users/{uid}` documents.
4. Optional: a screenshot of A's data and B's empty list, with emails and uids blurred.

## 9. Common problems

| Symptom | Likely cause |
|---|---|
| App shows "Firebase could not be started" | `firebase_options.dart` missing or from another project; rerun `flutterfire configure` |
| `permission-denied` in the app | Rules not published, or signed out; check the Rules tab and sign in again |
| Save takes about 8 seconds then says it is saved on this device | Offline; Firestore queues the write and it syncs later |
| Auth error "operation-not-allowed" | Email/Password sign-in not enabled |