import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/firebase_service.dart';
import '../shared/chat_screen.dart';
import 'order_edit_screen.dart';
import '../../widgets/payment_method_selector.dart';

class OrderStatusScreen extends StatefulWidget {
  final String orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  Order? _order;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order = await FirebaseService.getOrderById(widget.orderId);
    if (mounted) {
      setState(() => _order = order);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Status'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Status'),
        actions: [
          if (_order!.isEditable)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderEditScreen(order: _order!),
                  ),
                ).then((_) => _loadOrder()); // Refresh order after editing
              },
            ),
          if (_order!.providerId != null)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(orderId: widget.orderId),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatusIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _order!.status.displayName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusDescription(_order!.status),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Order Details
            Text(
              'Order Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow('Address', _order!.address, Icons.location_on),
                    const Divider(),
                    _buildDetailRow('Volume', '${_order!.volume}L', Icons.water_drop),
                    const Divider(),
                    _buildDetailRow('Date', _formatDateTime(_order!.requestedDate), Icons.calendar_today),
                    const Divider(),
                    _buildDetailRow('Price', '${_order!.price.toStringAsFixed(0)} ₽', Icons.attach_money),
                    if (_order!.notes != null && _order!.notes!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailRow('Notes', _order!.notes!, Icons.note),
                    ],
                  ],
                ),
              ),
            ),
            
            // Images
            if (_order!.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Photos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _order!.imageUrls.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _order!.imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            
            // Provider Info
            if (_order!.providerId != null) ...[
              const SizedBox(height: 24),
              Text(
                'Provider',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Provider Assigned',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your provider has been assigned and will contact you soon.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(orderId: widget.orderId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Payment Summary (only for completed orders)
            if (_order!.status == OrderStatus.completed) ...[
              const SizedBox(height: 24),
              Text(
                'Payment Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPaymentRow('Total Price', '${_order!.price.toStringAsFixed(0)} ₽', Icons.attach_money),
                      const Divider(),
                      _buildPaymentRow('Provider Share', '${_order!.price.toStringAsFixed(0)} ₽ (100%)', Icons.person),
                      const Divider(),
                      _buildPaymentRow('Platform Fee', '0 ₽ (0%)', Icons.business),
                      const Divider(),
                      _buildPaymentStatus(),
                      if (!_order!.isPaid) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showPaymentDialog,
                            icon: const Icon(Icons.payment),
                            label: const Text('Mark as Paid'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _getStatusColor(_order!.status).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getStatusIcon(_order!.status),
        size: 40,
        color: _getStatusColor(_order!.status),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.onTheWay:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.accepted:
        return Icons.check_circle;
      case OrderStatus.onTheWay:
        return Icons.local_shipping;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Your request is being reviewed by our providers.';
      case OrderStatus.accepted:
        return 'A provider has accepted your request and will contact you soon.';
      case OrderStatus.onTheWay:
        return 'Your provider is on the way to your location.';
      case OrderStatus.completed:
        return 'Your septic tank service has been completed successfully.';
      case OrderStatus.cancelled:
        return 'This order has been cancelled.';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPaymentRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            _order!.isPaid ? Icons.check_circle : Icons.pending,
            color: _order!.isPaid ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Payment Status',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _order!.isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _order!.isPaid ? 'Paid' : 'Pending',
              style: TextStyle(
                color: _order!.isPaid ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          PaymentMethod? selectedMethod;
          
          return AlertDialog(
            title: const Text('Payment Method'),
            content: SizedBox(
              width: double.maxFinite,
              child: PaymentMethodSelector(
                selectedMethod: selectedMethod,
                onChanged: (method) {
                  setDialogState(() {
                    selectedMethod = method;
                  });
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedMethod != null 
                    ? () => _confirmPayment(selectedMethod!)
                    : null,
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmPayment(PaymentMethod method) {
    Navigator.pop(context); // Close method selection dialog
    
    showDialog(
      context: context,
      builder: (context) => PaymentConfirmationDialog(
        amount: _order!.price,
        paymentMethod: method,
        onCancel: () => Navigator.pop(context),
        onConfirm: () => _markAsPaid(),
      ),
    );
  }

  Future<void> _markAsPaid() async {
    Navigator.pop(context); // Close confirmation dialog
    
    try {
      final updatedOrder = _order!.copyWith(
        isPaid: true,
        updatedAt: DateTime.now(),
      );
      
      await FirebaseService.updateOrder(updatedOrder);
      
      if (mounted) {
        setState(() {
          _order = updatedOrder;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment marked as completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update payment status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}