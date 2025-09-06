import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadOrderImage(String orderId, File file) async {
    final ref = _storage.ref().child('orders').child(orderId).child(DateTime.now().millisecondsSinceEpoch.toString());
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<String> uploadProfileImage(String uid, File file, {String folder = 'profiles'}) async {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child(folder).child(uid).child('avatar_$ts.jpg');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}
