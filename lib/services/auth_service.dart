import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "user-not-found":
          return "Email belum terdaftar.";

        case "wrong-password":
          return "Password salah.";

        case "invalid-email":
          return "Format email tidak valid.";

        case "invalid-credential":
          return "Email atau password salah.";

        case "network-request-failed":
          return "Tidak ada koneksi internet.";

        default:
          return e.message ?? "Login gagal.";
      }
    } catch (_) {
      return "Terjadi kesalahan.";
    }
  }

  Future<String?> register({
    required String nama,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "nama": nama.trim(),
          "email": email.trim(),
          "phone": phone.trim(),
          "saldo": 0,
          "poin": 0,
          "member": "Silver",
          "foto": "",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "email-already-in-use":
          return "Email sudah digunakan.";

        case "weak-password":
          return "Password terlalu lemah.";

        case "invalid-email":
          return "Format email tidak valid.";

        case "network-request-failed":
          return "Tidak ada koneksi internet.";

        default:
          return e.message ?? "Pendaftaran gagal.";
      }
    } catch (_) {
      return "Terjadi kesalahan.";
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String?> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (_) {
      return "Gagal mengirim email reset password.";
    }
  }

  Future<User?> currentUser() async {
    return _auth.currentUser;
  }

  Future<void> sendOtp(String phone) async {
    // Tahap berikutnya
  }

  Future<bool> verifyOtp(String code) async {
    // Tahap berikutnya
    return true;
  }
}
