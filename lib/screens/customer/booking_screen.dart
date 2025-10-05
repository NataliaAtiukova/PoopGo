import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../models/order.dart';
import '../../services/firebase_service.dart';
import '../../services/local_order_store.dart';
import '../payment/payment_info_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/order_id_generator.dart';
import '../../utils/order_status_display.dart';

/// BookingScreen: lightweight wrapper around order creation with enforced Pending status.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _volume = TextEditingController();
  final _notes = TextEditingController();
  final _price = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  final List<XFile> _images = [];
  bool _loading = false;

  @override
  void dispose() {
    _address.dispose();
    _volume.dispose();
    _notes.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) setState(() => _images.addAll(images));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final orderNumber = await generateDailyOrderId();
      final requested = DateTime(
          _date.year, _date.month, _date.day, _time.hour, _time.minute);

      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        imageUrls =
            await FirebaseService.uploadMultipleImages(_images, orderNumber);
      }

      const paymentMethod = 'cash'; // default payout method for driver
      final amount = double.parse(_price.text);
      final serviceFee = double.parse((amount * 0.10).toStringAsFixed(2));
      final totalWithFee =
          double.parse((amount + serviceFee).toStringAsFixed(2));

      final order = Order(
        id: orderNumber,
        customerId: user.uid,
        providerId: null,
        address: _address.text.trim(),
        latitude: 0,
        longitude: 0,
        requestedDate: requested,
        status: OrderStatus.processing,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        volume: double.parse(_volume.text),
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        price: amount,
        serviceFee: serviceFee,
        total: totalWithFee,
        isPaid: false,
        paymentMethod: paymentMethod,
        serviceFeePaid: false,
        orderId: orderNumber,
        displayStatus:
            displayStatusFromRaw(OrderStatus.processing.firestoreValue),
      );

      final createdId = await FirebaseService.createOrder(order);
      await LocalOrderStore.instance.saveOrder(order.copyWith(id: createdId));
      await FirebaseFirestore.instance.collection('orders').doc(createdId).set({
        'amount': amount,
        'serviceFee': serviceFee,
        'total': totalWithFee,
        'paymentMethod': paymentMethod,
        'isPaid': false,
        'serviceFeePaid': false,
        'status': OrderStatus.processing.firestoreValue,
        'displayStatus':
            displayStatusFromRaw(OrderStatus.processing.firestoreValue),
        'orderId': orderNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentInfoScreen(orderId: createdId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppLocalizations.of(context)!.error}: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.newOrder)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _address,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'Roboto'),
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.address),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.pleaseEnterPickupAddress
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _volume,
              decoration: InputDecoration(
                  labelText: '${AppLocalizations.of(context)!.volume} (L)'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || double.tryParse(v) == null)
                  ? AppLocalizations.of(context)!.enterTankVolume
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              decoration: InputDecoration(
                  labelText: '${AppLocalizations.of(context)!.totalPrice} (₽)'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || double.tryParse(v) == null)
                  ? AppLocalizations.of(context)!.enterPriceOffer
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'Roboto'),
              decoration: InputDecoration(
                  labelText:
                      '${AppLocalizations.of(context)!.notes} (${AppLocalizations.of(context)!.optional})'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _time);
                      if (t != null) setState(() => _time = t);
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(
                        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text(
                  '${AppLocalizations.of(context)!.addPhotos} (${_images.length})'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppLocalizations.of(context)!.createOrder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
