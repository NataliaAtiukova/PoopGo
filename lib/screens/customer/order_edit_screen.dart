import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/order.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/firebase_service.dart';

class OrderEditScreen extends StatefulWidget {
  final Order order;

  const OrderEditScreen({super.key, required this.order});

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  static const List<Map<String, dynamic>> _paymentOptions = [
    {'value': 'card', 'icon': Icons.credit_card},
    {'value': 'cash', 'icon': Icons.attach_money},
  ];

  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _volumeController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _addressController.text = widget.order.address;
    _volumeController.text = widget.order.volume.toString();
    _notesController.text = widget.order.notes ?? '';
    _priceController.text = widget.order.price.toString();
    _selectedDate = widget.order.requestedDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.order.requestedDate);
    _selectedPaymentMethod =
        _normalizePaymentMethod(widget.order.paymentMethod);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _volumeController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String? _normalizePaymentMethod(String? method) {
    if (method == null) return null;
    final value = method.toLowerCase();
    if (value.contains('cash')) return 'cash';
    if (value.contains('card')) return 'card';
    if (value.contains('bank')) return 'card';
    return method;
  }

  String _cardPaymentLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'ru'
        ? 'Оплата картой онлайн'
        : 'Online card payment';
  }

  String _serviceFeeNote(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'ru'
        ? 'Сервисный сбор 10 % включён в итоговую стоимость.'
        : 'A 10% service fee is included in the total price.';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _updateOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload new images if any
      List<String> imageUrls = List.from(widget.order.imageUrls);
      if (_selectedImages.isNotEmpty) {
        final newImageUrls = await FirebaseService.uploadMultipleImages(
            _selectedImages, widget.order.id);
        imageUrls.addAll(newImageUrls);
      }

      final requestedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final paymentMethod = _selectedPaymentMethod ?? 'card';
      final amount = double.parse(_priceController.text);
      final serviceFee = double.parse((amount * 0.10).toStringAsFixed(2));
      final totalWithFee =
          double.parse((amount + serviceFee).toStringAsFixed(2));

      final updatedOrder = widget.order.copyWith(
        address: _addressController.text.trim(),
        requestedDate: requestedDateTime,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        volume: double.parse(_volumeController.text),
        imageUrls: imageUrls,
        price: totalWithFee,
        paymentMethod: paymentMethod,
        updatedAt: DateTime.now(),
      );

      await FirebaseService.updateOrder(updatedOrder);
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
        'amount': amount,
        'serviceFee': serviceFee,
        'total': totalWithFee,
        'paymentMethod': paymentMethod,
        'status': paymentMethod == 'cash' ? 'pendingCash' : 'pending',
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.success),
            content:
                Text(AppLocalizations.of(context)!.orderUpdatedSuccessfully),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.error),
            content: Text(AppLocalizations.of(context)!
                .failedToUpdateOrder(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editOrder),
        actions: [
          if (widget.order.isEditable)
            TextButton(
              onPressed: _isLoading ? null : _updateOrder,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context)!.save),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Editability notice
              if (!widget.order.isEditable)
                Card(
                  color: Colors.orange.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This order cannot be edited because it has been accepted by a provider.',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (!widget.order.isEditable) const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Roboto'),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.address,
                  hintText:
                      AppLocalizations.of(context)!.pleaseEnterPickupAddress,
                  prefixIcon: const Icon(Icons.location_on),
                ),
                maxLines: 2,
                readOnly: !widget.order.isEditable,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!
                        .pleaseEnterPickupAddress;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date and Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.order.isEditable ? _selectDate : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.date,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: widget.order.isEditable ? _selectTime : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.time,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTime.format(context),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Volume
              TextFormField(
                controller: _volumeController,
                decoration: InputDecoration(
                  labelText: '${AppLocalizations.of(context)!.volume} (L)',
                  hintText: AppLocalizations.of(context)!.enterTankVolume,
                  prefixIcon: const Icon(Icons.water_drop),
                ),
                keyboardType: TextInputType.number,
                readOnly: !widget.order.isEditable,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.enterTankVolume;
                  }
                  final volume = double.tryParse(value);
                  if (volume == null || volume <= 0) {
                    return AppLocalizations.of(context)!.enterValidVolume;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: '${AppLocalizations.of(context)!.totalPrice} (₽)',
                  hintText: AppLocalizations.of(context)!.enterPriceOffer,
                  prefixIcon: const Icon(Icons.currency_ruble),
                ),
                keyboardType: TextInputType.number,
                readOnly: !widget.order.isEditable,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.enterPriceOffer;
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return AppLocalizations.of(context)!.enterValidPrice;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Payment Method
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.choosePaymentMethod,
                  prefixIcon: const Icon(Icons.payment),
                ),
                items: _paymentOptions.map((option) {
                  final value = option['value'] as String;
                  final icon = option['icon'] as IconData;
                  final label = value == 'card'
                      ? _cardPaymentLabel(context)
                      : AppLocalizations.of(context)!.cashPayment;
                  return DropdownMenuItem(
                    value: value,
                    child: Row(
                      children: [
                        Icon(icon,
                            color:
                                value == 'card' ? Colors.blue : Colors.green),
                        const SizedBox(width: 8),
                        Text(label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: widget.order.isEditable
                    ? (value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }
                    : null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.choosePaymentMethod;
                  }
                  return null;
                },
              ),

              if (_selectedPaymentMethod != null) ...[
                const SizedBox(height: 8),
                Text(
                  _serviceFeeNote(context),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Roboto'),
                decoration: InputDecoration(
                  labelText:
                      '${AppLocalizations.of(context)!.notes} (${AppLocalizations.of(context)!.optional})',
                  hintText: AppLocalizations.of(context)!.notes,
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 3,
                readOnly: !widget.order.isEditable,
              ),

              const SizedBox(height: 16),

              // Photos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.photo_camera),
                          const SizedBox(width: 8),
                          Text(
                            '${AppLocalizations.of(context)!.photos} (optional)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.addPhotosHint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[400],
                            ),
                      ),
                      if (widget.order.isEditable) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(AppLocalizations.of(context)!.addPhotos),
                        ),
                      ],
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _selectedImages[index].path,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image),
                                          );
                                        },
                                      ),
                                    ),
                                    if (widget.order.isEditable)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Update Button (only if editable)
              if (widget.order.isEditable)
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateOrder,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.updateOrder),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
