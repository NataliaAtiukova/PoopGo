import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _company = TextEditingController();
  final _license = TextEditingController();
  File? _truckPhoto;

  @override
  void dispose() {
    _company.dispose();
    _license.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final storage = context.read<StorageService>();
    String? url;
    if (_truckPhoto != null) {
      url = await storage.uploadOrderImage('provider_${auth.currentUser!.uid}', _truckPhoto!);
    }
    await fs.users.doc(auth.currentUser!.uid).set({
      'companyName': _company.text.trim(),
      'licenseInfo': _license.text.trim(),
      if (url != null) 'truckPhotoUrl': url,
    }, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.providerProfile)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _company,
              keyboardType: TextInputType.text,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'Roboto'),
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.companyNameOptional),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _license,
              keyboardType: TextInputType.text,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'Roboto'),
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.licenseInfoOptional),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _truckPhoto == null
                    ? const CircleAvatar(radius: 32, child: Icon(Icons.local_shipping))
                    : CircleAvatar(radius: 32, backgroundImage: FileImage(_truckPhoto!)),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1440);
                    if (x != null) setState(() => _truckPhoto = File(x.path));
                  },
                  icon: const Icon(Icons.photo_library),
                  label: Text(AppLocalizations.of(context)!.pickTruckPhoto),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: Text(AppLocalizations.of(context)!.save)),
          ],
        ),
      ),
    );
  }
}
