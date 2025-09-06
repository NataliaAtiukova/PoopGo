import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/order.dart' as app_models;
import '../models/user_profile.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // User Management
  static Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  static Future<void> saveUserRole(String userId, String role) async {
    await _firestore.collection('users').doc(userId).set({
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<String?> getUserRole(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['role'];
  }

  static Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data()!);
    }
    return null;
  }

  static Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.id).set(profile.toMap());
  }

  // Order Management
  static Future<String> createOrder(app_models.Order order) async {
    final docRef = await _firestore.collection('orders').add(order.toMap());
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  static Future<void> updateOrderStatus(String orderId, app_models.OrderStatus status, {String? providerId}) async {
    final updateData = {
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (providerId != null) {
      updateData['providerId'] = providerId;
    }
    
    await _firestore.collection('orders').doc(orderId).update(updateData);
  }

  static Future<void> updateOrder(app_models.Order order) async {
    await _firestore.collection('orders').doc(order.id).update(order.toMap());
  }

  static Stream<List<app_models.Order>> getOrdersForCustomer(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => app_models.Order.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort in memory instead of using orderBy to avoid index requirement
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  static Stream<List<app_models.Order>> getPendingOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: app_models.OrderStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => app_models.Order.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort in memory instead of using orderBy
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  static Stream<List<app_models.Order>> getOrdersForProvider(String providerId) {
    return _firestore
        .collection('orders')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => app_models.Order.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort in memory instead of using orderBy
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  static Stream<List<app_models.Order>> getCompletedOrdersForProvider(String providerId) {
    return _firestore
        .collection('orders')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: app_models.OrderStatus.completed.name)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => app_models.Order.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  static Stream<List<app_models.Order>> getActiveOrdersForProvider(String providerId) {
    return _firestore
        .collection('orders')
        .where('providerId', isEqualTo: providerId)
        .where('status', whereIn: [
          app_models.OrderStatus.accepted.name,
          app_models.OrderStatus.onTheWay.name,
        ])
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => app_models.Order.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  static Future<Map<String, dynamic>?> getUserContact(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  static Future<app_models.Order?> getOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (doc.exists) {
      return app_models.Order.fromMap({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  // Provider Profiles (separate collection)
  static Future<Map<String, dynamic>?> getProviderProfile(String providerId) async {
    final doc = await _firestore.collection('providers').doc(providerId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // Image Upload
  static Future<String> uploadImage(XFile image, String orderId) async {
    final ref = _storage.ref().child('orders/$orderId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = ref.putFile(File(image.path));
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  static Future<List<String>> uploadMultipleImages(List<XFile> images, String orderId) async {
    final List<String> urls = [];
    for (final image in images) {
      final url = await uploadImage(image, orderId);
      urls.add(url);
    }
    return urls;
  }

  // Chat Management
  static Future<void> sendMessage(String orderId, String senderId, String message) async {
    await _firestore.collection('chats').doc(orderId).collection('messages').add({
      'senderId': senderId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> getChatMessages(String orderId) {
    return _firestore
        .collection('chats')
        .doc(orderId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Notifications
  static Future<void> sendNotificationToUser(String userId, String title, String body) async {
    // This would typically integrate with FCM
    // For now, we'll store it in Firestore
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }
}
