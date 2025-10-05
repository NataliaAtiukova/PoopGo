import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/provider/provider_home_screen.dart';
import 'services/firebase_service.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    debugPrint('Warning: failed to load .env file: $error');
  }
  await Firebase.initializeApp(options: _firebaseOptionsFromEnv());
  runApp(const PoopGoApp());
}

FirebaseOptions _firebaseOptionsFromEnv() {
  final apiKey = dotenv.env['FIREBASE_API_KEY'];
  final appId = dotenv.env['FIREBASE_APP_ID'];
  final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
  final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];

  if (apiKey == null ||
      appId == null ||
      projectId == null ||
      messagingSenderId == null) {
    throw StateError('Missing Firebase environment configuration');
  }

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    projectId: projectId,
    messagingSenderId: messagingSenderId,
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
  );
}

class PoopGoApp extends StatelessWidget {
  const PoopGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? 'PoopGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routes: Routes.map,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ru', ''),
      ],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const RoleBasedHome();
        }

        return const LoginScreen();
      },
    );
  }
}

class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    return FutureBuilder<String?>(
      future: FirebaseService.getUserRole(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final role = snapshot.data;
        switch (role) {
          case 'customer':
            return const CustomerHomeScreen();
          case 'provider':
            return const ProviderHomeScreen();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
