import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/user_profile.dart';
import '../models/order.dart';
import '../utils/order_status_display.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Collections
  CollectionReference get users => _db.collection('users');
  CollectionReference get orders => _db.collection('orders');
  CollectionReference get providers => _db.collection('providers');

  Future<void> createUserProfile(UserProfile profile) async {
    await users.doc(profile.id).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final snap = await users.doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.data() as Map<String, dynamic>);
  }

  Stream<List<Order>> streamCustomerOrders(String uid) => orders
      .where('customerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => Order.fromMap(d.data() as Map<String, dynamic>)).toList());

  Stream<List<Order>> streamOpenOrders() => orders
      .where('status', isEqualTo: OrderStatus.paid.firestoreValue)
      .where('isPaid', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => Order.fromMap(d.data() as Map<String, dynamic>)).toList());

  Stream<List<Order>> streamProviderOrders(String uid) => orders
      .where('providerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => Order.fromMap(d.data() as Map<String, dynamic>)).toList());

  Future<void> createOrder(Order order) async {
    await orders.doc(order.id).set(order.toMap());
  }

  Future<void> acceptOrder({required String orderId, required String providerId}) async {
    await orders.doc(orderId).update({
      'providerId': providerId,
      'status': OrderStatus.assigned.firestoreValue,
      'displayStatus':
          displayStatusFromRaw(OrderStatus.assigned.firestoreValue),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await orders.doc(orderId).update({
      'status': status.firestoreValue,
      'displayStatus': displayStatusFromRaw(status.firestoreValue),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Chat
  CollectionReference chatMessages(String orderId) => _db.collection('chats').doc(orderId).collection('messages');

  Stream<List<Map<String, dynamic>>> streamChat(String orderId) => chatMessages(orderId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => d.data() as Map<String, dynamic>).toList());

  Future<void> sendMessage({
    required String orderId,
    required String senderId,
    required String text,
  }) async {
    await chatMessages(orderId).add({
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveProviderProfile({
    required String uid,
    required String fullName,
    required String phone,
    String? companyName,
    String? vehicleInfo,
  }) async {
    await providers.doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'phone': phone,
      if (companyName != null && companyName.isNotEmpty) 'companyName': companyName,
      if (vehicleInfo != null && vehicleInfo.isNotEmpty) 'vehicleInfo': vehicleInfo,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getProviderProfile(String uid) async {
    final snap = await providers.doc(uid).get();
    if (!snap.exists) return null;
    return snap.data() as Map<String, dynamic>;
  }

  Future<void> saveCustomerContact({
    required String uid,
    required String fullName,
    required String phone,
  }) async {
    await users.doc(uid).set({
      'fullName': fullName,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
