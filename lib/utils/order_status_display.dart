import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/order.dart';

String customerStatusLabel(BuildContext context, OrderStatus status) {
  final l = AppLocalizations.of(context)!;
  switch (status) {
    case OrderStatus.processing:
      return l.customerStatusProcessing;
    case OrderStatus.paid:
      return l.customerStatusPaid;
    case OrderStatus.assigned:
      return l.customerStatusAssigned;
    case OrderStatus.inProgress:
      return l.customerStatusInProgress;
    case OrderStatus.completed:
      return l.customerStatusCompleted;
    case OrderStatus.cancelled:
      return l.customerStatusCancelled;
  }
}

String customerStatusLabelFromRaw(BuildContext context, String rawStatus) {
  return customerStatusLabel(context, OrderStatus.fromRaw(rawStatus));
}

String displayStatusFromRaw(String rawStatus) {
  switch (OrderStatus.fromRaw(rawStatus)) {
    case OrderStatus.processing:
      return 'Не оплачен';
    case OrderStatus.paid:
      return 'Сервисный сбор оплачен';
    case OrderStatus.assigned:
      return 'В поиске водителя';
    case OrderStatus.inProgress:
      return 'Принят водителем';
    case OrderStatus.completed:
      return 'Завершён';
    case OrderStatus.cancelled:
      return 'Отменён';
  }
}
