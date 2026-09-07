# HouseMate push notification setup

HouseMate uses this delivery path:

`HouseMate backend -> Firebase Cloud Messaging -> Apple Push Notification service -> iPhone`

The app registers each installation and stores its Firebase registration ID in:

`users/{userId}/device_tokens/{registrationId}`

## 1. Apple Developer configuration

1. Open Apple Developer and select **Certificates, Identifiers & Profiles**.
2. Under **Identifiers**, open the development App ID for
   `com.Mar-cin.HouseMate.dev`.
3. Enable **Push Notifications** and save the App ID.
4. Under **Keys**, create an APNs authentication key with Apple Push
   Notifications enabled.
5. Download the `.p8` file and securely store it. Apple only allows this file
   to be downloaded once.
6. Keep the Key ID and Team ID together with the key file.

The production App ID, `com.Mar-cin.HouseMate`, must also have Push
Notifications enabled before a production/TestFlight release.

## 2. Firebase configuration

1. Open the Firebase project `housemate-5fbc5`.
2. Go to **Project settings -> Cloud Messaging**.
3. Find the iOS app with bundle ID `com.Mar-cin.HouseMate.dev`.
4. Upload the APNs `.p8` authentication key.
5. Enter the Apple Key ID and Team ID when Firebase asks for them.

Repeat this for the production Firebase project and production iOS app before
shipping HouseMate.

## 3. Firestore Rules

Publish the current `firestore.rules`. It permits a signed-in user to manage
only their own `device_tokens` documents. Server code using the Firebase Admin
SDK is not restricted by client security rules.

## 4. Verify registration

1. Install and run **HouseMate-Dev on a physical iPhone**.
2. Sign in and enable notifications when HouseMate asks for permission.
3. In Firestore, open `users/{yourUserId}/device_tokens`.
4. Confirm that a document exists with `registration_id`, `platform`,
   `environment`, and `updated_at` fields.
5. Sign out and confirm that the document is removed.

The simulator build verifies compilation, but delivery must be tested on a
properly signed physical-device build with the Push Notifications entitlement.

## 5. Server delivery

The next implementation phase is a trusted backend, normally Firebase Cloud
Functions. It will observe new or changed household data, create an in-app
notification document, find the recipient's device registrations and ask FCM
to deliver the push. Firebase Admin credentials must never be embedded in the
iOS application.

