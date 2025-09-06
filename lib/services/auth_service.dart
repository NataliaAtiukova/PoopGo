import 'package:firebase_auth/firebase_auth.dart' as fa;

class AuthService {
  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;

  Stream<fa.User?> get authStateChanges => _auth.authStateChanges();

  fa.User? get currentUser => _auth.currentUser;

  Future<fa.UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    return cred;
  }

  Future<fa.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
