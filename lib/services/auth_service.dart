import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> register({
    required String nama,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "nama": nama,
          "email": email,
          "phone": phone,
          "saldo": 0,
          "poin": 0,
          "member": "Silver",
          "foto": "",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> forgotPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email,
    );
  }

  Future<User?> currentUser() async {
    return _auth.currentUser;
  }

  Future<void> sendOtp(String phone) async {
    // Akan kita lengkapi setelah Phone Authentication diaktifkan.
  }

  Future<bool> verifyOtp(String code) async {
    // Akan kita lengkapi setelah Phone Authentication diaktifkan.
    return true;
  }
}
