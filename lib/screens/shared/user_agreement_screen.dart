import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UserAgreementScreen extends StatefulWidget {
  const UserAgreementScreen({super.key});

  @override
  State<UserAgreementScreen> createState() => _UserAgreementScreenState();
}

class _UserAgreementScreenState extends State<UserAgreementScreen> {
  late final Future<String> _agreementTextFuture;

  @override
  void initState() {
    super.initState();
    _agreementTextFuture = rootBundle.loadString('assets/user_agreement.txt');
  }

  Future<void> _openDocument() async {
    try {
      final data = await rootBundle.load('assets/documents/user_agreement_pooppgo.pdf');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/user_agreement_pooppgo.pdf');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        if (!mounted) return;
        final reason = result.message.isNotEmpty ? result.message : 'Нет приложения для открытия файла';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть документ: $reason')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть документ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользовательское соглашение'),
      ),
      body: FutureBuilder<String>(
        future: _agreementTextFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final text = snapshot.data ?? 'Не удалось загрузить документ.';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _openDocument,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Открыть документ'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
