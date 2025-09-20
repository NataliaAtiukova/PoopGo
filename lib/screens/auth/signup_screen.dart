import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/messaging_service.dart';
import '../../routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _vehicle = TextEditingController();
  String _role = 'customer';
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    _company.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final messaging = context.read<MessagingService>();
    try {
      await auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        displayName: _name.text.trim(),
      );
      // Save contact data
      if (_role == 'provider') {
        await firestore.saveProviderProfile(
          uid: auth.currentUser!.uid,
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
          companyName: _company.text.trim().isEmpty ? null : _company.text.trim(),
          vehicleInfo: _vehicle.text.trim().isEmpty ? null : _vehicle.text.trim(),
        );
      } else {
        await firestore.saveCustomerContact(
          uid: auth.currentUser!.uid,
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
        );
      }
      await messaging.init(firestore, auth.currentUser!.uid);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        _role == 'customer' ? Routes.customerHome : Routes.providerHome,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.signupFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.signUp)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Roboto'),
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fullNameLabel),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.pleaseEnterName : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Roboto'),
                keyboardType: TextInputType.text,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.phoneNumberLabel),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.pleaseEnterPhoneNumber : null,
              ),
              const SizedBox(height: 12),
              if (_role == 'provider') ...[
                TextFormField(
                  controller: _company,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'Roboto'),
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.companyNameOptional),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vehicle,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'Roboto'),
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.vehicleInfoOptional),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _email,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Roboto'),
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.emailLabel),
                keyboardType: TextInputType.text,
                validator: (v) => (v == null || !v.contains('@')) ? AppLocalizations.of(context)!.enterValidEmail : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'Roboto'),
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.passwordLabel),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? AppLocalizations.of(context)!.min6Chars : null,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'customer', label: Text(AppLocalizations.of(context)!.roleCustomer), icon: const Icon(Icons.person)),
                  ButtonSegment(value: 'provider', label: Text(AppLocalizations.of(context)!.roleProvider), icon: const Icon(Icons.local_shipping)),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const CircularProgressIndicator() : Text(AppLocalizations.of(context)!.createAccount),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
                child: Text(AppLocalizations.of(context)!.alreadyHaveAccountLogin),
              )
            ],
          ),
        ),
      ),
    );
  }
}
