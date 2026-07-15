import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mengambil user yang sedang login saat ini
  User? get user => _auth.currentUser;

  // Stream untuk memantau perubahan status login (Reactive Auth State)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==========================================
  // 1. SISTEM MASUK AKUN (LOGIN)
  // ==========================================
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
        case "invalid-credential":
          return "Email atau password salah. Silakan periksa kembali.";
        case "wrong-password":
          return "Password yang Anda masukkan salah.";
        case "invalid-email":
          return "Format alamat email tidak valid.";
        case "user-disabled":
          return "Akun Anda telah dinonaktifkan oleh administrator.";
        case "network-request-failed":
          return "Koneksi internet terputus. Periksa jaringan Anda.";
        default:
          return e.message ?? "Terjadi kegagalan saat masuk akun.";
      }
    } catch (_) {
      return "Terjadi kesalahan sistem saat memproses login.";
    }
  }

  // ==========================================
  // 2. SISTEM DAFTAR AKUN BARU (REGISTER)
  // ==========================================
  Future<String?> register({
    required String nama,
    required String email,
    required String phone,
    required String password,
  }) async {
    User? user;
    try {
      // 1. Buat Kredensial User di Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      user = credential.user;

      // 2. Simpan Data Tambahan Pengguna ke Firestore Database
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
      // ROLLBACK SAFETY: Jika pembuatan akun di Firestore gagal, hapus akun di Auth
      if (user != null) {
        await user.delete();
      }
      
      switch (e.code) {
        case "email-already-in-use":
          return "Alamat email tersebut sudah terdaftar.";
        case "weak-password":
          return "Keamanan password terlalu lemah (minimal 6 karakter).";
        case "invalid-email":
          return "Format alamat email tidak valid.";
        case "network-request-failed":
          return "Koneksi internet terputus. Periksa jaringan Anda.";
        default:
          return e.message ?? "Terjadi kegagalan saat pendaftaran.";
      }
    } catch (_) {
      // ROLLBACK SAFETY: Jika terjadi kegagalan umum database, hapus akun di Auth
      if (user != null) {
        try {
          await user.delete();
        } catch (_) {}
      }
      return "Gagal menyimpan data akun. Mohon coba sesaat lagi.";
    }
  }

  // ==========================================
  // 3. SISTEM RESET PASSWORD
  // ==========================================
  Future<String?> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "user-not-found":
          return "Email tidak terdaftar dalam sistem DesaPay.";
        case "invalid-email":
          return "Format alamat email tidak valid.";
        case "network-request-failed":
          return "Koneksi internet terputus. Periksa jaringan Anda.";
        default:
          return e.message ?? "Gagal mengirimkan email reset password.";
      }
    } catch (_) {
      return "Terjadi kesalahan sistem saat meminta reset password.";
    }
  }

  // ==========================================
  // 4. KELUAR AKUN & CEK SESI
  // ==========================================
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<User?> currentUser() async {
    return _auth.currentUser;
  }

  // ==========================================
  // 5. OTP SERVICE (SCAFFOLD UNTUK IMPLEMENTASI BERIKUTNYA)
  // ==========================================
  Future<void> sendOtp(String phone) async {
    // Sesi pengembangan integrasi OTP WhatsApp / SMS Gateway
  }

  Future<bool> verifyOtp(String code) async {
    // Sesi pengembangan validasi kode OTP
    return true;
  }
}
