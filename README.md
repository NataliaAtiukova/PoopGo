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
   - Create `.env` in the project root with the Firebase keys:
     ```env
     FIREBASE_API_KEY=...
     FIREBASE_APP_ID=...
     FIREBASE_PROJECT_ID=...
     FIREBASE_MESSAGING_SENDER_ID=...
     FIREBASE_STORAGE_BUCKET=...
     ```
   - Keep `.env` and all platform `GoogleService-Info.plist`/`google-services.json` files out of Git; they are listed in `.gitignore`.

3) Ensure Firebase services are enabled for your project (Auth, Firestore, Storage, Cloud Messaging).

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

- Firebase options are loaded dynamically from the `.env` file at runtime.
- Push notifications are wired to store the FCM token; showing foreground notifications can be added with flutter_local_notifications.
- Map picker is left as a follow-up; address text is supported now.
