import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../routes.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.of(context)!.chooseRole, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.login, arguments: 'customer'),
              child: Text(AppLocalizations.of(context)!.roleCustomer),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.login, arguments: 'provider'),
              child: Text(AppLocalizations.of(context)!.roleProvider),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, Routes.signup),
              child: Text(AppLocalizations.of(context)!.newHereCreateAccount),
            )
          ],
        ),
      ),
    );
  }
}
