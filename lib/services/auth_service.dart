import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Kontrak layanan autentikasi DesaPay.
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

  Future<String?> forgotPassword(
    String email,
  );

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(
      PhoneAuthCredential,
    ) verificationCompleted,
    required Function(
      FirebaseAuthException,
    ) verificationFailed,
    required Function(
      String,
      int?,
    ) codeSent,
    required Function(
      String,
    ) codeAutoRetrievalTimeout,
  });

  Future<UserCredential?> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  });
}

/// Implementasi Firebase Authentication DesaPay.
class AuthService implements IAuthService {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // CURRENT USER
  // =========================================================

  @override
  User? get currentUser =>
      _auth.currentUser;

  @override
  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  // =========================================================
  // LOGIN
  // =========================================================

  @override
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final emailTrim =
        email.trim();

    final passwordTrim =
        password.trim();

    if (emailTrim.isEmpty ||
        passwordTrim.isEmpty) {
      return "Email dan password wajib diisi.";
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailTrim,
        password: passwordTrim,
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

        case "too-many-requests":
          return "Terlalu banyak percobaan login. Silakan coba lagi nanti.";

        case "network-request-failed":
          return "Koneksi internet terputus. Periksa jaringan Anda.";

        default:
          return e.message ??
              "Terjadi kegagalan saat masuk akun.";
      }
    } catch (_) {
      return "Terjadi kesalahan sistem saat memproses login.";
    }
  }

  // =========================================================
  // REGISTER
  // =========================================================

  @override
  Future<String?> register({
    required String nama,
    required String email,
    required String phone,
    required String password,
  }) async {
    User? user;

    final namaTrim =
        nama.trim();

    final emailTrim =
        email.trim();

    final phoneInput =
        phone.trim();

    final passwordTrim =
        password.trim();

    if (namaTrim.isEmpty) {
      return "Nama wajib diisi.";
    }

    if (emailTrim.isEmpty) {
      return "Email wajib diisi.";
    }

    if (phoneInput.isEmpty) {
      return "Nomor handphone wajib diisi.";
    }

    if (passwordTrim.length < 6) {
      return "Password minimal 6 karakter.";
    }

    try {
      // ======================================================
      // FORMAT NOMOR INDONESIA
      // ======================================================

      String formattedPhone =
          phoneInput;

      if (formattedPhone.startsWith("0")) {
        formattedPhone =
            "+62${formattedPhone.substring(1)}";
      } else if (!formattedPhone.startsWith("+")) {
        formattedPhone =
            "+$formattedPhone";
      }

      // ======================================================
      // FIREBASE AUTH
      // ======================================================

      final credential =
          await _auth
              .createUserWithEmailAndPassword(
        email: emailTrim,
        password: passwordTrim,
      );

      user = credential.user;

      if (user == null) {
        return "Gagal membuat akun pengguna.";
      }

      // ======================================================
      // DISPLAY NAME
      // ======================================================

      await user.updateDisplayName(
        namaTrim,
      );

      // ======================================================
      // FIRESTORE USER
      //
      // balance = saldo utama DesaPay.
      // ======================================================

      await _firestore
          .collection("users")
          .doc(user.uid)
          .set({
        "uid": user.uid,
        "nama": namaTrim,
        "email": emailTrim,
        "phone": formattedPhone,

        "balance": 0,
        "poin": 0,
        "member": "Silver",

        "fotoProfil": "",
        "fotoKtp": "",
        "fotoSelfie": "",

        "kycStatus": "BELUM",

        "status": "Aktif",

        "createdAt":
            FieldValue.serverTimestamp(),
        "updatedAt":
            FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      // ======================================================
      // ROLLBACK AUTH
      // ======================================================

      if (user != null) {
        try {
          await user.delete();
        } catch (_) {}
      }

      switch (e.code) {
        case "email-already-in-use":
          return "Alamat email tersebut sudah terdaftar.";

        case "weak-password":
          return "Keamanan password terlalu lemah.";

        case "invalid-email":
          return "Format alamat email tidak valid.";

        case "operation-not-allowed":
          return "Metode login email/password belum diaktifkan.";

        case "network-request-failed":
          return "Koneksi internet terputus. Periksa jaringan Anda.";

        default:
          return e.message ??
              "Terjadi kegagalan saat pendaftaran.";
      }
    } catch (e) {
      // ======================================================
      // ROLLBACK AUTH JIKA FIRESTORE GAGAL
      // ======================================================

      if (user != null) {
        try {
          await user.delete();
        } catch (_) {}
      }

      return "Gagal menyimpan data akun: $e";
    }
  }

  // =========================================================
  // RESET PASSWORD
  // =========================================================

  @override
  Future<String?> forgotPassword(
    String email,
  ) async {
    final emailTrim =
        email.trim();

    if (emailTrim.isEmpty) {
      return "Email wajib diisi.";
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: emailTrim,
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
          return e.message ??
              "Gagal mengirimkan email reset password.";
      }
    } catch (_) {
      return "Terjadi kesalahan sistem saat meminta reset password.";
    }
  }

  // =========================================================
  // CHANGE PASSWORD
  // =========================================================

  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return "Sesi akun tidak ditemukan. Silakan login kembali.";
    }

    if (newPassword.trim().length < 6) {
      return "Password baru minimal 6 karakter.";
    }

    final email =
        user.email;

    if (email == null ||
        email.isEmpty) {
      return "Email akun tidak tersedia.";
    }

    try {
      final credential =
          EmailAuthProvider.credential(
        email: email,
        password:
            currentPassword.trim(),
      );

      await user.reauthenticateWithCredential(
        credential,
      );

      await user.updatePassword(
        newPassword.trim(),
      );

      await _firestore
          .collection("users")
          .doc(user.uid)
          .set(
        {
          "securityUpdatedAt":
              FieldValue.serverTimestamp(),
          "updatedAt":
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "wrong-password":
        case "invalid-credential":
          return "Kata sandi lama salah.";

        case "weak-password":
          return "Kata sandi baru terlalu lemah.";

        case "requires-recent-login":
          return "Sesi keamanan telah kedaluwarsa. Silakan login kembali.";

        case "user-disabled":
          return "Akun Anda telah dinonaktifkan.";

        case "network-request-failed":
          return "Koneksi internet terputus.";

        default:
          return e.message ??
              "Gagal mengubah kata sandi.";
      }
    } catch (_) {
      return "Terjadi kesalahan saat mengubah kata sandi.";
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  // =========================================================
  // PHONE AUTH
  // =========================================================

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(
      PhoneAuthCredential,
    ) verificationCompleted,
    required Function(
      FirebaseAuthException,
    ) verificationFailed,
    required Function(
      String,
      int?,
    ) codeSent,
    required Function(
      String,
    ) codeAutoRetrievalTimeout,
  }) async {
    String formattedPhone =
        phoneNumber.trim();

    if (formattedPhone.startsWith("0")) {
      formattedPhone =
          "+62${formattedPhone.substring(1)}";
    } else if (!formattedPhone.startsWith("+")) {
      formattedPhone =
          "+$formattedPhone";
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted:
          verificationCompleted,
      verificationFailed:
          verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout:
          codeAutoRetrievalTimeout,
      timeout:
          const Duration(seconds: 60),
    );
  }

  @override
  Future<UserCredential?>
      signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential =
        PhoneAuthProvider.credential(
      verificationId:
          verificationId,
      smsCode:
          smsCode.trim(),
    );

    return _auth.signInWithCredential(
      credential,
    );
  }
}
