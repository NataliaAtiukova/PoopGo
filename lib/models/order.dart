import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  accepted,
  onTheWay,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
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
  final double price; // customer's price offer in RUB
  final bool isPaid;

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
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
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
      'isPaid': isPaid,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
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
        orElse: () => OrderStatus.pending,
      ),
      notes: map['notes'],
      volume: map['volume']?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      price: map['price']?.toDouble() ?? 0.0,
      isPaid: map['isPaid'] ?? false,
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
    double? price,
    bool? isPaid,
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
      isPaid: isPaid ?? this.isPaid,
    );
  }

  // Helper method to check if order is editable
  bool get isEditable => status == OrderStatus.pending;
}