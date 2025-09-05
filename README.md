PoopGo — Septic Tank Pickup (Flutter)

Overview

- Two roles: Customer and Provider.
- Firebase Auth, Firestore, Storage, and FCM.
- Customers create pickup requests; providers accept and update status.
- Basic chat per order and simple Material 3 UI.

Project Setup

1) Create Flutter project scaffolding (if missing platforms):
   - flutter create .

2) Configure Firebase:
   - dart pub global activate flutterfire_cli
   - flutterfire configure
   - Replace `lib/firebase_options.dart` with generated file.
   - Ensure Firestore, Authentication, Storage, and Cloud Messaging are enabled in Firebase console.

3) Add iOS/Android FCM setup:
   - iOS: Enable Push Notifications and Background Modes in Xcode; add APNs key.
   - Android: Add google-services.json and apply Gradle plugins per Firebase docs.

4) Google Maps (optional to start):
   - Add platform API keys and configuration per google_maps_flutter docs.

5) Install dependencies:
   - flutter pub get

6) Run:
   - flutter run

Firestore Data Model (suggested)

- users/{uid}
  - uid, role: 'customer'|'provider', displayName, companyName, truckPhotoUrl, licenseInfo, rating, fcmToken
- orders/{orderId}
  - id, status: 'pending'|'accepted'|'onTheWay'|'completed', address, lat, lng, scheduledAt, volumeLiters, photoUrls[], notes, customerId, providerId, createdAt, updatedAt
- chats/{orderId}/messages/{messageId}
  - senderId, text, createdAt

Notes

- `lib/firebase_options.dart` is a placeholder; replace via `flutterfire configure`.
- Push notifications are wired to store the FCM token; showing foreground notifications can be added with flutter_local_notifications.
- Map picker is left as a follow-up; address text is supported now.

