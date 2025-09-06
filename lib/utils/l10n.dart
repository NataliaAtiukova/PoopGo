import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/order.dart';

String orderStatusText(BuildContext context, OrderStatus status) {
  final l = AppLocalizations.of(context)!;
  switch (status) {
    case OrderStatus.pending:
      return l.orderStatusPending;
    case OrderStatus.accepted:
      return l.orderStatusAccepted;
    case OrderStatus.onTheWay:
      return l.orderStatusOnTheWay;
    case OrderStatus.completed:
      return l.orderStatusCompleted;
    case OrderStatus.cancelled:
      return l.orderStatusCancelled;
  }
}

