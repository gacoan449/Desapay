import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Kontrak Abstraksi untuk Layanan Autentikasi DesaPay (Domain Layer)
abstract class IAuthService {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  
  Future<String?> login({
    required String email,
    required String password,
  });
  
  Future<String?> register({
    required String nama,
    required String email,
    required String phone,
    required String password,
  });
  
  Future<String?> forgotPassword(String email);
  
  Future<void> logout();
  
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  });
  
  Future<UserCredential?> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  });
}

/// Implementasi Layanan Autentikasi DesaPay dengan Firebase (Data Layer)
class AuthService implements IAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==========================================
  // 1. SISTEM MASUK AKUN (LOGIN)
  // ==========================================
  @override
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
    } catch (e) {
      return "Terjadi kesalahan sistem saat memproses login: ${e.toString()}";
    }
  }

  // ==========================================
  // 2. SISTEM DAFTAR AKUN BARU (REGISTER)
  // ==========================================
  @override
  Future<String?> register({
    required String nama,
    required String email,
    required String phone,
    required String password,
  }) async {
    User? user;
    try {
      // Standarisasi format nomor telepon Indonesia (+62)
      String formattedPhone = phone.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+62${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$formattedPhone';
      }

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
          "phone": formattedPhone,
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
    } catch (e) {
      // ROLLBACK SAFETY: Jika terjadi kegagalan umum database, hapus akun di Auth
      if (user != null) {
        try {
          await user.delete();
        } catch (ignoredError) {
          // Mengabaikan error internal delete agar tidak mengaburkan pesan utama
        }
      }
      return "Gagal menyimpan data akun. Detail error: ${e.toString()}";
    }
  }

  // ==========================================
  // 3. SISTEM RESET PASSWORD
  // ==========================================
  @override
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
    } catch (e) {
      return "Terjadi kesalahan sistem saat meminta reset password: ${e.toString()}";
    }
  }

  // ==========================================
  // 4. KELUAR AKUN
  // ==========================================
  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ==========================================
  // 5. FIREBASE PHONE AUTHENTICATION (OTP INTEGRATION)
  // ==========================================
  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    String formattedPhone = phoneNumber.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+62${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  @override
  Future<UserCredential?> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // Melempar kembali exception agar ditangani oleh presenter/controller UI DesaPay
      rethrow;
    }
  }
}
