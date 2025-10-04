import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  processing,
  paid,
  pending,
  accepted,
  onTheWay,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.onTheWay:
        return 'On the way';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
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
  final double price; // base price (without service fee)
  final double serviceFee; // calculated 10% fee
  final double total; // price + serviceFee
  final bool isPaid;
  final String? paymentMethod; // payment method selected by customer
  final bool serviceFeePaid; // service commission paid by customer
  final String orderId; // external payment reference

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
    required this.price,
    required this.serviceFee,
    required this.total,
    this.isPaid = false,
    this.paymentMethod,
    this.serviceFeePaid = false,
    required this.orderId,
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
      'status': status.name,
      'notes': notes,
      'volume': volume,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'price': price,
      'serviceFee': serviceFee,
      'total': total,
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'serviceFeePaid': serviceFeePaid,
      'orderId': orderId,
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
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => _resolveStatus(map['status']),
      ),
      notes: map['notes'],
      volume: map['volume']?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      price: basePrice,
      serviceFee: fee,
      total: total,
      isPaid: map['isPaid'] ?? false,
      paymentMethod: map['paymentMethod'],
      serviceFeePaid: map['serviceFeePaid'] ?? false,
      orderId: resolveOrderId(),
    );
  }

  static OrderStatus _resolveStatus(dynamic statusValue) {
    final value = statusValue?.toString().toLowerCase() ?? '';
    switch (value) {
      case 'processing':
        return OrderStatus.processing;
      case 'paid':
        return OrderStatus.paid;
      case 'accepted':
        return OrderStatus.accepted;
      case 'ontheway':
        return OrderStatus.onTheWay;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
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
    double? price,
    double? serviceFee,
    double? total,
    bool? isPaid,
    String? paymentMethod,
    bool? serviceFeePaid,
    String? orderId,
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
      price: price ?? this.price,
      serviceFee: serviceFee ?? this.serviceFee,
      total: total ?? this.total,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      serviceFeePaid: serviceFeePaid ?? this.serviceFeePaid,
      orderId: orderId ?? this.orderId,
    );
  }

  // Helper method to check if order is editable
  bool get isEditable => status == OrderStatus.pending;
}
