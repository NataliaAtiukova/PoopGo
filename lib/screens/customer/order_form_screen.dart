import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/local_order_store.dart';
import '../../models/order.dart';
import '../../routes.dart';
import '../../widgets/image_picker_row.dart';
import '../../widgets/map_preview.dart';
import '../../utils/order_status_display.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();
  final _volume = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _scheduledAt;
  List<File> _images = [];
  double? _lat;
  double? _lng;
  bool _loading = false;
  late final TapGestureRecognizer _agreementRecognizer;
  late final TapGestureRecognizer _offerRecognizer;

  @override
  void initState() {
    super.initState();
    _agreementRecognizer = TapGestureRecognizer()..onTap = _openAgreement;
    _offerRecognizer = TapGestureRecognizer()..onTap = _openOffer;
  }

  @override
  void dispose() {
    _address.dispose();
    _date.dispose();
    _time.dispose();
    _volume.dispose();
    _notes.dispose();
    _agreementRecognizer.dispose();
    _offerRecognizer.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
        initialDate: now);
    if (!mounted) return;
    if (date == null) return;
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (!mounted) return;
    if (time == null) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!mounted) return;
    setState(() {
      _scheduledAt = dt;
      _date.text = '${date.year}-${date.month}-${date.day}';
      _time.text = time.format(context);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _scheduledAt == null) return;
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final storage = context.read<StorageService>();
    try {
      final id = const Uuid().v4();
      final orderNumber = 'poopgo_${DateTime.now().millisecondsSinceEpoch}';
      final urls = <String>[];
      for (final f in _images) {
        urls.add(await storage.uploadOrderImage(id, f));
      }
      const basePrice = 0.0; // TODO: actual pricing logic
      final serviceFee = double.parse((basePrice * 0.10).toStringAsFixed(2));
      final total = double.parse((basePrice + serviceFee).toStringAsFixed(2));

      final order = Order(
        id: id,
        customerId: auth.currentUser!.uid,
        providerId: null,
        address: _address.text.trim(),
        latitude: _lat ?? 0.0,
        longitude: _lng ?? 0.0,
        requestedDate: _scheduledAt!,
        status: OrderStatus.processing,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        volume: double.tryParse(_volume.text) ?? 0.0,
        imageUrls: urls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        price: basePrice,
        serviceFee: serviceFee,
        total: total,
        isPaid: false,
        paymentMethod: 'cash',
        serviceFeePaid: false,
        orderId: orderNumber,
        displayStatus:
            displayStatusFromRaw(OrderStatus.processing.firestoreValue),
      );
      await fs.createOrder(order);
      await LocalOrderStore.instance.saveOrder(order);
      await FirebaseFirestore.instance.collection('orders').doc(id).update({
        'amount': basePrice,
        'serviceFee': serviceFee,
        'total': total,
        'paymentMethod': 'cash',
        'isPaid': false,
        'serviceFeePaid': false,
        'status': OrderStatus.processing.firestoreValue,
        'displayStatus':
            displayStatusFromRaw(OrderStatus.processing.firestoreValue),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.orderStatus,
          arguments: order.id,
          (route) => route.settings.name == Routes.customerHome);
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${l.error}: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openAgreement() {
    Navigator.pushNamed(context, Routes.userAgreement);
  }

  void _openOffer() {
    Navigator.pushNamed(context, Routes.publicOffer);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodySmall = Theme.of(context).textTheme.bodySmall;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.requestPickup)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _address,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Roboto'),
                decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.addressOptionalMap),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _date,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: 'Roboto'),
                      readOnly: true,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.date),
                      onTap: _pickDateTime,
                      validator: (v) => (_scheduledAt == null)
                          ? AppLocalizations.of(context)!.selectDateTime
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _time,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: 'Roboto'),
                      readOnly: true,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.time),
                      onTap: _pickDateTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _volume,
                decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.volume} (L)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) {
                    return AppLocalizations.of(context)!.enterPositiveNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.latitudeOptional),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      onChanged: (v) =>
                          setState(() => _lat = double.tryParse(v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.longitudeOptional),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      onChanged: (v) =>
                          setState(() => _lng = double.tryParse(v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MapPreview(lat: _lat, lng: _lng),
              const SizedBox(height: 12),
              ImagePickerRow(onChanged: (files) => _images = files),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Roboto'),
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.additionalNotes),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  onPressed: _loading ? null : _submit,
                  label: _loading
                      ? const CircularProgressIndicator()
                      : Text(AppLocalizations.of(context)!.submitRequest),
                ),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.mapTip),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ) ??
                      TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                  children: [
                    const TextSpan(
                        text: 'Оплачивая сервисный сбор, вы соглашаетесь с '),
                    TextSpan(
                      text: 'Публичной офертой',
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: _offerRecognizer,
                    ),
                    const TextSpan(text: ' и '),
                    TextSpan(
                      text: 'Пользовательским соглашением',
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: _agreementRecognizer,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
