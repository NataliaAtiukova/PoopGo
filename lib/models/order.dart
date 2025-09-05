import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, accepted, onTheWay, completed }

class Order {
  final String id;
  final String? address;
  final double? lat;
  final double? lng;
  final DateTime scheduledAt;
  final int volumeLiters;
  final List<String> photoUrls;
  final String? notes;
  final String customerId;
  final String? providerId;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.customerId,
    required this.scheduledAt,
    required this.volumeLiters,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.lat,
    this.lng,
    this.photoUrls = const [],
    this.notes,
    this.providerId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'address': address,
        'lat': lat,
        'lng': lng,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'volumeLiters': volumeLiters,
        'photoUrls': photoUrls,
        'notes': notes,
        'customerId': customerId,
        'providerId': providerId,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static Order fromMap(Map<String, dynamic> m) => Order(
        id: m['id'],
        address: m['address'],
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        scheduledAt: (m['scheduledAt'] as Timestamp).toDate(),
        volumeLiters: (m['volumeLiters'] as num).toInt(),
        photoUrls: (m['photoUrls'] as List?)?.cast<String>() ?? [],
        notes: m['notes'],
        customerId: m['customerId'],
        providerId: m['providerId'],
        status: _statusFromString(m['status']),
        createdAt: (m['createdAt'] as Timestamp).toDate(),
        updatedAt: (m['updatedAt'] as Timestamp).toDate(),
      );

  static OrderStatus _statusFromString(String s) {
    switch (s) {
      case 'accepted':
        return OrderStatus.accepted;
      case 'onTheWay':
        return OrderStatus.onTheWay;
      case 'completed':
        return OrderStatus.completed;
      default:
        return OrderStatus.pending;
    }
  }
}

