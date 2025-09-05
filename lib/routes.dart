import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/customer/order_form_screen.dart';
import 'screens/customer/order_status_screen.dart';
import 'screens/provider/provider_home_screen.dart';
import 'screens/provider/open_requests_screen.dart';
import 'screens/provider/profile_screen.dart';
import 'screens/shared/chat_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'models/user_profile.dart';
import 'package:provider/provider.dart';

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const roleSelect = '/role-select';
  static const customerHome = '/customer/home';
  static const providerHome = '/provider/home';
  static const orderForm = '/customer/order-form';
  static const orderStatus = '/customer/order-status';
  static const openRequests = '/provider/open-requests';
  static const providerProfile = '/provider/profile';
  static const chat = '/chat';

  static Map<String, WidgetBuilder> get map => {
        splash: (ctx) => const SplashRouter(),
        login: (ctx) => const LoginScreen(),
        signup: (ctx) => const SignupScreen(),
        roleSelect: (ctx) => const RoleSelectScreen(),
        customerHome: (ctx) => const CustomerHomeScreen(),
        providerHome: (ctx) => const ProviderHomeScreen(),
        orderForm: (ctx) => const OrderFormScreen(),
        orderStatus: (ctx) => const OrderStatusScreen(),
        openRequests: (ctx) => const OpenRequestsScreen(),
        providerProfile: (ctx) => const ProviderProfileScreen(),
        chat: (ctx) => const ChatScreen(),
      };
}

class SplashRouter extends StatelessWidget {
  const SplashRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = auth.currentUser;
        if (user == null) {
          return const RoleSelectScreen();
        }

        return FutureBuilder<UserProfile?>(
          future: firestore.getUserProfile(user.uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final profile = snap.data!;
            if (profile.role == UserRole.customer) {
              return const CustomerHomeScreen();
            } else {
              return const ProviderHomeScreen();
            }
          },
        );
      },
    );
  }
}

