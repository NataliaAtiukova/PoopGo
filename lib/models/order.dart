import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  processing('processing', 'Processing'),
  paid('paid', 'Paid'),
  assigned('assigned', 'Assigned'),
  inProgress('in_progress', 'In progress'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.firestoreValue, this.displayName);

  final String firestoreValue;
  final String displayName;

  static OrderStatus fromRaw(dynamic raw) {
    final value = raw?.toString().toLowerCase();
    switch (value) {
      case 'processing':
        return OrderStatus.processing;
      case 'paid':
        return OrderStatus.paid;
      case 'assigned':
        return OrderStatus.assigned;
      case 'in_progress':
      case 'inprogress':
      case 'ontheway':
        return OrderStatus.inProgress;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'failed':
        return OrderStatus.cancelled;
      case 'accepted':
        return OrderStatus.assigned;
      case 'pending':
        return OrderStatus.processing;
      default:
        return OrderStatus.processing;
    }
  }
}

class Order {
  final String id;
  final String customerId;
  final String? providerId;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime requestedDate;
  final OrderStatus status;
  final String? notes;
  final double volume; // in liters
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double price; // base price (without service fee)
  final double serviceFee; // calculated 10% fee
  final double total; // price + serviceFee
  final bool isPaid;
  final String? paymentMethod; // payment method selected by customer
  final bool serviceFeePaid; // service commission paid by customer
  final String? orderId; // external payment reference
  final String? displayStatus;

  Order({
    required this.id,
    required this.customerId,
    this.providerId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.requestedDate,
    required this.status,
    this.notes,
    required this.volume,
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.startedAt,
    this.completedAt,
    required this.price,
    required this.serviceFee,
    required this.total,
    this.isPaid = false,
    this.paymentMethod,
    this.serviceFeePaid = false,
    this.orderId,
    this.displayStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'userId': customerId,
      'providerId': providerId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'requestedDate': Timestamp.fromDate(requestedDate),
      'status': status.firestoreValue,
      'notes': notes,
      'volume': volume,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'price': price,
      'serviceFee': serviceFee,
      'total': total,
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'serviceFeePaid': serviceFeePaid,
      'orderId': orderId,
      'displayStatus': displayStatus,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    String resolveOrderId() {
      final value = map['orderId'];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      final docId = map['id'];
      if (docId is String && docId.isNotEmpty) {
        return 'poopgo_$docId';
      }
      final created = map['createdAt'];
      if (created is Timestamp) {
        return 'poopgo_${created.millisecondsSinceEpoch}';
      }
      return 'poopgo_${DateTime.now().millisecondsSinceEpoch}';
    }

    double resolveServiceFee(double base) {
      final raw = map['serviceFee'];
      if (raw is num) return raw.toDouble();
      return base * 0.10;
    }

    double resolveTotal(double base, double fee) {
      final raw = map['total'];
      if (raw is num) return raw.toDouble();
      return base + fee;
    }

    final basePrice = map['price']?.toDouble() ?? 0.0;
    final fee = resolveServiceFee(basePrice);
    final total = resolveTotal(basePrice, fee);

    return Order(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      providerId: map['providerId'],
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      requestedDate: (map['requestedDate'] as Timestamp).toDate(),
      status: OrderStatus.fromRaw(map['status']),
      notes: map['notes'],
      volume: map['volume']?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      paidAt: map['paidAt'] is Timestamp
          ? (map['paidAt'] as Timestamp).toDate()
          : null,
      startedAt: map['startedAt'] is Timestamp
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      price: basePrice,
      serviceFee: fee,
      total: total,
      isPaid: map['isPaid'] ?? false,
      paymentMethod: map['paymentMethod'],
      serviceFeePaid: map['serviceFeePaid'] ?? false,
      orderId: resolveOrderId(),
      displayStatus: map['displayStatus'] as String?,
    );
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? providerId,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? requestedDate,
    OrderStatus? status,
    String? notes,
    double? volume,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    DateTime? startedAt,
    DateTime? completedAt,
    double? price,
    double? serviceFee,
    double? total,
    bool? isPaid,
    String? paymentMethod,
    bool? serviceFeePaid,
    String? orderId,
    String? displayStatus,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      requestedDate: requestedDate ?? this.requestedDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      volume: volume ?? this.volume,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      price: price ?? this.price,
      serviceFee: serviceFee ?? this.serviceFee,
      total: total ?? this.total,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      serviceFeePaid: serviceFeePaid ?? this.serviceFeePaid,
      orderId: orderId ?? this.orderId,
      displayStatus: displayStatus ?? this.displayStatus,
    );
  }

  // Helper method to check if order is editable
  bool get isEditable => status == OrderStatus.processing;
}
