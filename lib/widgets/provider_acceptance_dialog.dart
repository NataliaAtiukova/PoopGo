import 'package:flutter/material.dart';

import '../routes.dart';

Future<bool> showProviderAgreementDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          bool isChecked = false;
          return StatefulBuilder(
            builder: (context, setState) {
              final textStyle = Theme.of(context).textTheme.bodySmall;
              final linkStyle = textStyle?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  );
              final baseStyle = textStyle ?? const TextStyle(fontSize: 12);

              return AlertDialog(
                title: const Text('Подтверждение принятия заказа'),
                content: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isChecked,
                  onChanged: (value) => setState(() => isChecked = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Wrap(
                    spacing: 2,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Принимая заказ, вы подтверждаете согласие с ',
                        style: baseStyle,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed(Routes.publicOffer),
                        child: Text('Публичной офертой', style: linkStyle),
                      ),
                      Text(' и ', style: baseStyle),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed(Routes.userAgreement),
                        child: Text('Пользовательским соглашением', style: linkStyle),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Отмена'),
                  ),
                  ElevatedButton(
                    onPressed: isChecked ? () => Navigator.of(dialogContext).pop(true) : null,
                    child: const Text('Принять'),
                  ),
                ],
              );
            },
          );
        },
      ) ??
      false;
}
