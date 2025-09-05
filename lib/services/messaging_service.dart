import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // TODO: Optionally handle background messages (show local notifications, etc.)
}

class MessagingService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> init(FirestoreService firestore, String uid) async {
    await _messaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final token = await _messaging.getToken();
    if (token != null) {
      await firestore.users.doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
    }

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint('Foreground push: ${message.notification?.title}');
      }
      // TODO: Optionally present a local notification in foreground.
    });
  }
}
