import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../services/firebase_service.dart';
import '../services/payment_config.dart';

class OrderStatusHandler {
  /// Allowed linear flow: Pending -> Accepted -> OnTheWay -> Completed
  static bool canTransition(OrderStatus from, OrderStatus to) {
    const order = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.onTheWay,
      OrderStatus.completed,
    ];
    final iFrom = order.indexOf(from);
    final iTo = order.indexOf(to);
    if (iFrom == -1 || iTo == -1) return false;
    // Only allow moving to the immediate next state or staying in same
    return iTo == iFrom + 1;
  }

  /// Provider accepts an order. Sets providerId and moves to Accepted.
  static Future<void> providerAcceptOrder({
    required String orderId,
    required String providerId,
  }) async {
    final current = await FirebaseService.getOrderById(orderId);
    if (current == null) {
      throw StateError('Order not found');
    }
    if (!canTransition(current.status, OrderStatus.accepted)) {
      throw StateError('Invalid transition to Accepted');
    }
    await FirebaseService.updateOrderStatus(
      orderId,
      OrderStatus.accepted,
      providerId: providerId,
    );
  }

  /// Provider confirms they are en route. Requires Accepted first.
  static Future<void> providerSetOnTheWay({
    required String orderId,
  }) async {
    final current = await FirebaseService.getOrderById(orderId);
    if (current == null) throw StateError('Order not found');
    if (!canTransition(current.status, OrderStatus.onTheWay)) {
      throw StateError('Must be Accepted before OnTheWay');
    }
    await FirebaseService.updateOrderStatus(orderId, OrderStatus.onTheWay);
  }

  /// Provider marks job as done. Requires OnTheWay first.
  static Future<void> providerComplete({
    required String orderId,
  }) async {
    final current = await FirebaseService.getOrderById(orderId);
    if (current == null) throw StateError('Order not found');
    if (!canTransition(current.status, OrderStatus.completed)) {
      throw StateError('Must be OnTheWay before Completed');
    }
    await FirebaseService.updateOrderStatus(orderId, OrderStatus.completed);
  }

  /// Whether the app should prompt service fee now.
  /// Only at Accepted and above minimum total, and not yet paid.
  static bool shouldPromptServiceFee(Order order) {
    return order.status == OrderStatus.accepted && order.serviceFeePaid == false;
  }

  /// Whether customer can access provider contact/chat.
  /// - At Accepted: require serviceFeePaid (or skipped under min).
  /// - At Completed: do NOT prompt; access is allowed regardless.
  static bool canAccessContact(Order order) {
    // Contact info is visible only after service fee is paid
    return order.serviceFeePaid == true;
  }
}
