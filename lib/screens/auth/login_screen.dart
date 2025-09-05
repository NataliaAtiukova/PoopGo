import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import '../../routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _roleArg;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _roleArg ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    try {
      await auth.signIn(email: _email.text.trim(), password: _password.text);
      final profile = await firestore.getUserProfile(auth.currentUser!.uid);
      if (profile == null) {
        // If profile missing, force signup flow
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile not found. Please sign up.')));
        Navigator.pushReplacementNamed(context, Routes.signup);
        return;
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        profile.role == UserRole.customer ? Routes.customerHome : Routes.providerHome,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_roleArg != null) Text('Role: $_roleArg'),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const CircularProgressIndicator() : const Text('Login'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, Routes.signup),
                child: const Text('Create an account'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

