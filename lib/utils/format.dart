import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatDateTime(BuildContext context, DateTime dateTime) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).add_Hm().format(dateTime);
}

