import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/order.dart';
import '../../routes.dart';
import '../../widgets/image_picker_row.dart';
import '../../widgets/map_preview.dart';
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

  @override
  void dispose() {
    _address.dispose();
    _date.dispose();
    _time.dispose();
    _volume.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)), initialDate: now);
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
      final urls = <String>[];
      for (final f in _images) {
        urls.add(await storage.uploadOrderImage(id, f));
      }
      final order = Order(
        id: id,
        customerId: auth.currentUser!.uid,
        providerId: null,
        address: _address.text.trim(),
        latitude: _lat ?? 0.0,
        longitude: _lng ?? 0.0,
        requestedDate: _scheduledAt!,
        status: OrderStatus.pending,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        volume: double.tryParse(_volume.text) ?? 0.0,
        imageUrls: urls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        price: 0.0,
        isPaid: false,
        paymentMethod: null,
        serviceFeePaid: false,
      );
      await fs.createOrder(order);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.orderStatus, arguments: order.id, (route) => route.settings.name == Routes.customerHome);
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l.error}: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.addressOptionalMap),
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
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.date),
                      onTap: _pickDateTime,
                      validator: (v) => (_scheduledAt == null) ? AppLocalizations.of(context)!.selectDateTime : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _time,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: 'Roboto'),
                      readOnly: true,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.time),
                      onTap: _pickDateTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _volume,
                decoration: InputDecoration(labelText: '${AppLocalizations.of(context)!.volume} (L)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return AppLocalizations.of(context)!.enterPositiveNumber;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.latitudeOptional),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      onChanged: (v) => setState(() => _lat = double.tryParse(v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.longitudeOptional),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      onChanged: (v) => setState(() => _lng = double.tryParse(v)),
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
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.additionalNotes),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  onPressed: _loading ? null : _submit,
                  label: _loading ? const CircularProgressIndicator() : Text(AppLocalizations.of(context)!.submitRequest),
                ),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.mapTip),
            ],
          ),
        ),
      ),
    );
  }
}
