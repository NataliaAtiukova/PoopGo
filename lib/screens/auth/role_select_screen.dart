import 'package:flutter/material.dart';
import '../../routes.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to PoopGo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choose your role to continue:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.login, arguments: 'customer'),
              child: const Text('I am a Customer'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.login, arguments: 'provider'),
              child: const Text('I am a Provider'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, Routes.signup),
              child: const Text('New here? Create an account'),
            )
          ],
        ),
      ),
    );
  }
}

