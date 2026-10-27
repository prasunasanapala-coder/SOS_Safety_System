# Notification design (Firebase Cloud Messaging)

**Status: partly implemented.** The app registers a device for notifications. It does **not** send any notification, and nothing in the app contacts another person.

## What is implemented

- Settings → "Register this device" calls `FcmNotificationService.enable(uid)`.
- It asks for notification permission, reads the device token and stores it under `users/{uid}/fcmTokens/{token}` with the platform name and a server timestamp.
- It saves the new token if Firebase rotates it.
- Web is reported as "not supported in this prototype".

A stored token only means "this device could be sent a message". It is not evidence that any message was delivered.

## What is not implemented, and why

Sending a push message needs a trusted server holding credentials. A phone app must not hold them. On Firebase this means **Cloud Functions**, which need the paid **Blaze** plan. This project stays on the free Spark plan, so sending is described here as a design only.

## Proposed flow

```
App                          Firestore                Cloud Function              FCM
 | -- SOS event recorded --> sosHistory/{id}  --trigger-->  read user's tokens
 |                                                          send message  -------> device
 |                                                          remove invalid tokens
```

1. The user finishes an SOS countdown; the app writes the event (already done).
2. A Firestore trigger on `users/{uid}/sosHistory/{eventId}` runs.
3. The function reads `users/{uid}/fcmTokens` and sends a message.
4. Tokens that FCM reports as invalid are deleted.

### Sample function (untested, not deployed)

This sketch notifies the user's **own** registered devices only. It is written for illustration and has not been run.

```js
// functions/index.js  (requires Blaze plan; NOT deployed or tested)
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.notifyOwnDevices = onDocumentCreated(
  "users/{uid}/sosHistory/{eventId}",
  async (event) => {
    const event_ = event.data.data();
    if (event_.demoMode) return; // never send for demo alerts

    const uid = event.params.uid;
    const snap = await getFirestore().collection(`users/${uid}/fcmTokens`).get();
    const tokens = snap.docs.map((d) => d.id);
    if (tokens.length === 0) return;

    const result = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "SOS event recorded",
        body: "An SOS event was recorded on your account.",
      },
    });

    // Remove tokens that are no longer valid.
    const stale = [];
    result.responses.forEach((r, i) => {
      const code = r.error && r.error.code;
      if (code === "messaging/registration-token-not-registered") stale.push(tokens[i]);
    });
    await Promise.all(stale.map((t) =>
      getFirestore().doc(`users/${uid}/fcmTokens/${t}`).delete()));
  }
);
```

## Notifying other people: open questions

The prototype stores contacts as a name and phone number. A contact is not an app user, so FCM cannot reach them. Notifying contacts would need:

- A way to link a contact to an account (for example the contact accepts an invitation), with their consent.
- A rule about what a contact may see, and a way for them to leave.
- Handling for false alarms, spam and abuse.
- Review of privacy law and platform policy for sharing location with third parties.

These are listed as future work in `LIMITATIONS.md`.

## Other considerations

- Android 13 and later asks for the `POST_NOTIFICATIONS` permission (declared in the manifest).
- Notifications can be delayed, throttled or blocked by the device, so they must never be the only safety mechanism.
- Message text must not contain precise location in the notification body.