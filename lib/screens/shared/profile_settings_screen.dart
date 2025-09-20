import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/storage_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String role; // 'customer' or 'provider'

  const ProfileSettingsScreen({super.key, required this.role});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _avatarUrl;
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final uid = user.uid;
      final db = FirebaseFirestore.instance;
      if (widget.role == 'provider') {
        final snap = await db.collection('providers').doc(uid).get();
        final data = snap.data() ?? {};
        _fullNameController.text = (data['fullName'] ?? '').toString();
        _phoneController.text = (data['phone'] ?? '').toString();
        _emailController.text = (data['email'] ?? user.email ?? '').toString();
        _avatarUrl = (data['avatarUrl'] ?? data['logoUrl'])?.toString();
      } else {
        final snap = await db.collection('users').doc(uid).get();
        final data = snap.data() ?? {};
        _fullNameController.text = (data['fullName'] ?? data['name'] ?? '').toString();
        _phoneController.text = (data['phone'] ?? '').toString();
        _emailController.text = (data['email'] ?? user.email ?? '').toString();
        _avatarUrl = (data['avatarUrl'])?.toString();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1440);
    if (x != null) {
      setState(() => _avatarFile = File(x.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      // Upload avatar if selected
      String? url = _avatarUrl;
      if (_avatarFile != null) {
        final storage = StorageService();
        url = await storage.uploadProfileImage(user.uid, _avatarFile!, folder: widget.role == 'provider' ? 'providers' : 'profiles');
      }

      final db = FirebaseFirestore.instance;
      if (widget.role == 'provider') {
        await db.collection('providers').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          if (url != null) 'avatarUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Save in users; keep both name and fullName for compatibility
        await db.collection('users').doc(user.uid).set({
          'id': user.uid,
          'name': _fullNameController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          if (url != null) 'avatarUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profileSaved), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.failedToSave}: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = widget.role == 'provider';
    return Scaffold(
      appBar: AppBar(title: Text(isProvider ? AppLocalizations.of(context)!.providerSettings : AppLocalizations.of(context)!.profileSettings)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundImage: _avatarFile != null
                                  ? FileImage(_avatarFile!)
                                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                      ? NetworkImage(_avatarUrl!) as ImageProvider
                                      : null,
                              child: (_avatarFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Material(
                                color: Theme.of(context).colorScheme.primary,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _pickAvatar,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.edit, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _fullNameController,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontFamily: 'Roboto'),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.fullName,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontFamily: 'Roboto'),
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.phoneNumber,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your phone' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontFamily: 'Roboto'),
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.email,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _save,
                        icon: const Icon(Icons.save),
                        label: Text(AppLocalizations.of(context)!.save),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
