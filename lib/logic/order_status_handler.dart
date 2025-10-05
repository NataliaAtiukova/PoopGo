import '../models/order.dart';
import '../services/firebase_service.dart';

class OrderStatusHandler {
  /// Allowed transitions between order statuses.
  static bool canTransition(OrderStatus from, OrderStatus to) {
    if (from == to) return true;
    const Map<OrderStatus, Set<OrderStatus>> allowed = {
      OrderStatus.processing: <OrderStatus>{
        OrderStatus.paid,
        OrderStatus.cancelled,
      },
      OrderStatus.paid: <OrderStatus>{
        OrderStatus.assigned,
        OrderStatus.cancelled,
      },
      OrderStatus.assigned: <OrderStatus>{
        OrderStatus.inProgress,
        OrderStatus.cancelled,
      },
      OrderStatus.inProgress: <OrderStatus>{
        OrderStatus.completed,
        OrderStatus.cancelled,
      },
      OrderStatus.completed: <OrderStatus>{},
      OrderStatus.cancelled: <OrderStatus>{},
    };
    final next = allowed[from];
    if (next == null) return false;
    return next.contains(to);
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
    if (!canTransition(current.status, OrderStatus.assigned)) {
      throw StateError('Invalid transition to Assigned');
    }
    await FirebaseService.updateOrderStatus(
      orderId,
      OrderStatus.assigned,
      providerId: providerId,
    );
  }

  /// Provider confirms they are en route. Requires Accepted first.
  static Future<void> providerSetOnTheWay({
    required String orderId,
  }) async {
    final current = await FirebaseService.getOrderById(orderId);
    if (current == null) throw StateError('Order not found');
    if (!canTransition(current.status, OrderStatus.inProgress)) {
      throw StateError('Must be Assigned before InProgress');
    }
    await FirebaseService.updateOrderStatus(orderId, OrderStatus.inProgress);
  }

  /// Provider marks job as done. Requires OnTheWay first.
  static Future<void> providerComplete({
    required String orderId,
  }) async {
    final current = await FirebaseService.getOrderById(orderId);
    if (current == null) throw StateError('Order not found');
    if (!canTransition(current.status, OrderStatus.completed)) {
      throw StateError('Must be InProgress before Completed');
    }
    await FirebaseService.updateOrderStatus(orderId, OrderStatus.completed);
  }

  /// Whether the app should prompt service fee now.
  /// Only at Accepted and above minimum total, and not yet paid.
  static bool shouldPromptServiceFee(Order order) {
    return order.status == OrderStatus.processing && order.serviceFeePaid == false;
  }

  /// Whether customer can access provider contact/chat.
  /// - At Accepted: require serviceFeePaid (or skipped under min).
  /// - At Completed: do NOT prompt; access is allowed regardless.
  static bool canAccessContact(Order order) {
    // Contact info is visible only after service fee is paid
    return order.serviceFeePaid == true;
  }
}
