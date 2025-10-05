import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServiceFeeNotice extends StatelessWidget {
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  const ServiceFeeNotice({super.key, required this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    final infoStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
        ) ??
        TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        );
    final linkStyle = infoStyle.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final learnMoreText = locale == 'ru' ? 'Подробнее…' : 'Learn more…';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.paymentMethodNote,
          style: infoStyle,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(learnMoreText, style: linkStyle),
        ),
      ],
    );

    if (padding != null) {
      return Padding(
        padding: padding!,
        child: content,
      );
    }
    return content;
  }
}
