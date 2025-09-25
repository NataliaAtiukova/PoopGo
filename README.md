PoopGo: Вызов ассенизаторской машины — Septic Tank Pickup (Flutter)

Overview

- Two roles: Customer and Provider.
- Firebase Auth, Firestore, Storage, and FCM.
- Customers create pickup requests; providers accept and update status.
- Basic chat per order and simple Material 3 UI.

Project Setup

1) Create Flutter project scaffolding (if missing platforms):
   - flutter create .

2) Configure Firebase without committing secrets:
   - Copy each `*.example` file to its required location and populate with real values:
     - `android/app/google-services.json.example` → `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist.example` → `ios/Runner/GoogleService-Info.plist`
     - `macos/Runner/GoogleService-Info.plist.example` → `macos/Runner/GoogleService-Info.plist`
   - Create `firebase_options.env` from `firebase_options.env.example` and keep it out of Git.
   - Run the app with your secrets via `--dart-define-from-file=firebase_options.env` (or pass each `--dart-define` manually).

3) Ensure Firebase services are enabled for your project (Auth, Firestore, Storage, Cloud Messaging).

4) Google Maps (optional to start):
   - Add platform API keys and configuration per google_maps_flutter docs.

5) Install dependencies:
   - flutter pub get

6) Run:
   - flutter run --dart-define-from-file=firebase_options.env

Firestore Data Model (suggested)

- users/{uid}
  - uid, role: 'customer'|'provider', displayName, companyName, truckPhotoUrl, licenseInfo, rating, fcmToken
- orders/{orderId}
  - id, status: 'pending'|'accepted'|'onTheWay'|'completed', address, lat, lng, scheduledAt, volumeLiters, photoUrls[], notes, customerId, providerId, createdAt, updatedAt
- chats/{orderId}/messages/{messageId}
  - senderId, text, createdAt

Notes

- `lib/firebase_options.dart` expects configuration from compile-time defines; secrets no longer live in the repository.
- Push notifications are wired to store the FCM token; showing foreground notifications can be added with flutter_local_notifications.
- Map picker is left as a follow-up; address text is supported now.

