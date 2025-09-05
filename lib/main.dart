import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/messaging_service.dart';
import 'theme.dart';
import 'routes.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PoopGoApp());
}

class PoopGoApp extends StatelessWidget {
  const PoopGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<MessagingService>(create: (_) => MessagingService()),
      ],
      child: MaterialApp(
        title: 'PoopGo',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        initialRoute: Routes.splash,
        routes: Routes.map,
      ),
    );
  }
}

