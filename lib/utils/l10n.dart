import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/order.dart';

String orderStatusText(BuildContext context, OrderStatus status) {
  final l = AppLocalizations.of(context)!;
  switch (status) {
    case OrderStatus.processing:
      return _manualStatus(context, en: 'Processing payment', ru: 'Оплата обрабатывается');
    case OrderStatus.paid:
      return _manualStatus(context, en: 'Paid', ru: 'Оплачен');
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

String _manualStatus(BuildContext context, {required String en, required String ru}) {
  final locale = Localizations.localeOf(context);
  return locale.languageCode == 'ru' ? ru : en;
}
