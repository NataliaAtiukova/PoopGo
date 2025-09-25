import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class PublicOfferScreen extends StatefulWidget {
  const PublicOfferScreen({super.key});

  @override
  State<PublicOfferScreen> createState() => _PublicOfferScreenState();
}

class _PublicOfferScreenState extends State<PublicOfferScreen> {
  late final Future<String> _offerTextFuture;

  @override
  void initState() {
    super.initState();
    _offerTextFuture = rootBundle.loadString('assets/oferta.txt');
  }

  Future<void> _openDocument() async {
    try {
      final data = await rootBundle.load('assets/documents/oferta_pooppgo.pdf');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/oferta_pooppgo.pdf');
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
        title: const Text('Публичная оферта'),
      ),
      body: FutureBuilder<String>(
        future: _offerTextFuture,
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
