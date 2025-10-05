import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Future<String> generateDailyOrderId() async {
  final now = DateTime.now();
  final datePart = DateFormat('ddMMyyyy').format(now);
  final dayStart = DateTime(now.year, now.month, now.day);
  final snapshot = await FirebaseFirestore.instance
      .collection('orders')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
      .get();
  final orderCount = snapshot.docs.length + 1;
  final serial = orderCount.toString().padLeft(3, '0');
  return '$datePart-$serial';
}
