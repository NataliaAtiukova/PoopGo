import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final String? orderId;
  const ChatScreen({super.key, this.orderId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId ?? (ModalRoute.of(context)?.settings.arguments as String);
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestore.streamChat(orderId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMine = m['senderId'] == auth.currentUser?.uid;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMine ? Theme.of(context).colorScheme.primary.withOpacity(.15) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      decoration: const InputDecoration(hintText: 'Message...'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      if (_text.text.trim().isEmpty) return;
                      await firestore.sendMessage(orderId: orderId, senderId: auth.currentUser!.uid, text: _text.text.trim());
                      _text.clear();
                    },
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

