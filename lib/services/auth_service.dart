import 'package:supabase_flutter/supabase_flutter.dart';

/// ===============================================================
/// KONTRAK LAYANAN AUTENTIKASI DESAPAY
/// ===============================================================
///
/// Versi ini sudah menggunakan Supabase Auth.
/// Tidak lagi menggunakan:
/// - FirebaseAuth
/// - FirebaseFirestore
/// - Firebase User
/// - Firebase UserCredential
/// - FirebaseAuthException
/// ===============================================================

abstract class IAuthService {
  User? get currentUser;

  Stream<AuthState> get authStateChanges;

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

  Future<String?> sendPhoneOtp({
    required String phoneNumber,
  });

  Future<String?> verifyPhoneOtp({
    required String phoneNumber,
    required String smsCode,
  });
}

/// ===============================================================
/// IMPLEMENTASI SUPABASE AUTH DESAPAY
/// ===============================================================

class AuthService implements IAuthService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ===============================================================
  // CURRENT USER
  // ===============================================================

  @override
  User? get currentUser =>
      _supabase.auth.currentUser;

  // ===============================================================
  // AUTH STATE
  // ===============================================================

  @override
  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // ===============================================================
  // FORMAT NOMOR INDONESIA
  // ===============================================================

  String _formatPhone(String phone) {
    String formatted =
        phone.trim().replaceAll(' ', '');

    if (formatted.startsWith('0')) {
      formatted =
          '+62${formatted.substring(1)}';
    } else if (!formatted.startsWith('+')) {
      formatted = '+$formatted';
    }

    return formatted;
  }

  // ===============================================================
  // LOGIN
  // ===============================================================

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
      return 'Email dan password wajib diisi.';
    }

    try {
      await _supabase.auth.signInWithPassword(
        email: emailTrim,
        password: passwordTrim,
      );

      return null;
    } on AuthException catch (e) {
      switch (e.code) {
        case 'invalid_credentials':
          return 'Email atau password salah. Silakan periksa kembali.';

        case 'email_not_confirmed':
          return 'Email Anda belum dikonfirmasi. Silakan cek email terlebih dahulu.';

        case 'user_not_found':
          return 'Akun tidak ditemukan.';

        case 'user_banned':
          return 'Akun Anda telah dinonaktifkan oleh administrator.';

        default:
          return e.message.isNotEmpty
              ? e.message
              : 'Terjadi kegagalan saat masuk akun.';
      }
    } catch (_) {
      return 'Terjadi kesalahan sistem saat memproses login.';
    }
  }

  // ===============================================================
  // REGISTER
  // ===============================================================

  @override
  Future<String?> register({
    required String nama,
    required String email,
    required String phone,
    required String password,
  }) async {
    final namaTrim =
        nama.trim();

    final emailTrim =
        email.trim();

    final phoneInput =
        phone.trim();

    final passwordTrim =
        password.trim();

    if (namaTrim.isEmpty) {
      return 'Nama wajib diisi.';
    }

    if (emailTrim.isEmpty) {
      return 'Email wajib diisi.';
    }

    if (phoneInput.isEmpty) {
      return 'Nomor handphone wajib diisi.';
    }

    if (passwordTrim.length < 6) {
      return 'Password minimal 6 karakter.';
    }

    try {
      final formattedPhone =
          _formatPhone(phoneInput);

      // =========================================================
      // SUPABASE AUTH
      // =========================================================

      final response =
          await _supabase.auth.signUp(
        email: emailTrim,
        password: passwordTrim,
        data: {
          'nama': namaTrim,
          'phone': formattedPhone,
        },
      );

      final user =
          response.user;

      if (user == null) {
        return 'Gagal membuat akun pengguna.';
      }

      // =========================================================
      // PROFILE / USERS
      // =========================================================
      //
      // Data akun disimpan di tabel public.users.
      //
      // Pastikan tabel users memiliki kolom:
      //
      // id
      // uid
      // nama
      // email
      // phone
      // balance
      // poin
      // member
      // fotoProfil
      // fotoKtp
      // fotoSelfie
      // kycStatus
      // status
      // role
      // createdAt
      // updatedAt
      //
      // =========================================================

      try {
        await _supabase
            .from('users')
            .upsert({
          'id': user.id,
          'uid': user.id,
          'nama': namaTrim,
          'email': emailTrim,
          'phone': formattedPhone,
          'balance': 0,
          'poin': 0,
          'member': 'Silver',
          'fotoProfil': '',
          'fotoKtp': '',
          'fotoSelfie': '',
          'kycStatus': 'BELUM',
          'status': 'Aktif',
          'role': 'user',
          'createdAt':
              DateTime.now().toIso8601String(),
          'updatedAt':
              DateTime.now().toIso8601String(),
        });
      } catch (e) {
        return 'Akun berhasil dibuat, tetapi data profil gagal disimpan: $e';
      }

      // =========================================================
      // EMAIL CONFIRMATION
      // =========================================================
      //
      // Jika Supabase Email Confirmation aktif,
      // user perlu konfirmasi email.
      //
      // =========================================================

      if (response.session == null) {
        return 'EMAIL_CONFIRMATION_REQUIRED';
      }

      return null;
    } on AuthException catch (e) {
      switch (e.code) {
        case 'user_already_exists':
          return 'Alamat email tersebut sudah terdaftar.';

        case 'email_exists':
          return 'Alamat email tersebut sudah terdaftar.';

        case 'weak_password':
          return 'Keamanan password terlalu lemah.';

        case 'invalid_credentials':
          return 'Data pendaftaran tidak valid.';

        default:
          return e.message.isNotEmpty
              ? e.message
              : 'Terjadi kegagalan saat pendaftaran.';
      }
    } catch (e) {
      return 'Gagal membuat akun: $e';
    }
  }

  // ===============================================================
  // RESET PASSWORD
  // ===============================================================

  @override
  Future<String?> forgotPassword(
    String email,
  ) async {
    final emailTrim =
        email.trim();

    if (emailTrim.isEmpty) {
      return 'Email wajib diisi.';
    }

    try {
      await _supabase.auth.resetPasswordForEmail(
        emailTrim,
      );

      return null;
    } on AuthException catch (e) {
      return e.message.isNotEmpty
          ? e.message
          : 'Gagal mengirimkan email reset password.';
    } catch (_) {
      return 'Terjadi kesalahan sistem saat meminta reset password.';
    }
  }

  // ===============================================================
  // CHANGE PASSWORD
  // ===============================================================

  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return 'Sesi akun tidak ditemukan. Silakan login kembali.';
    }

    final newPasswordTrim =
        newPassword.trim();

    if (newPasswordTrim.length < 6) {
      return 'Password baru minimal 6 karakter.';
    }

    try {
      // ===========================================================
      // VERIFIKASI PASSWORD LAMA
      // ===========================================================
      //
      // Supabase tidak menyediakan reauthenticateWithCredential()
      // seperti Firebase.
      //
      // Kita verifikasi password lama dengan login ulang.
      //
      // ===========================================================

      final email =
          user.email;

      if (email == null ||
          email.isEmpty) {
        return 'Email akun tidak tersedia.';
      }

      await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword.trim(),
      );

      // ===========================================================
      // UPDATE PASSWORD
      // ===========================================================

      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPasswordTrim,
        ),
      );

      // ===========================================================
      // UPDATE PROFILE
      // ===========================================================

      try {
        await _supabase
            .from('users')
            .update({
          'securityUpdatedAt':
              DateTime.now().toIso8601String(),
          'updatedAt':
              DateTime.now().toIso8601String(),
        })
            .eq(
          'id',
          user.id,
        );
      } catch (_) {
        // Password sudah berhasil diubah.
        // Kegagalan update profile tidak membatalkan
        // perubahan password.
      }

      return null;
    } on AuthException catch (e) {
      final code =
          e.code.toLowerCase();

      if (code.contains('invalid') ||
          code.contains('credential') ||
          code.contains('password')) {
        return 'Kata sandi lama salah.';
      }

      return e.message.isNotEmpty
          ? e.message
          : 'Gagal mengubah kata sandi.';
    } catch (_) {
      return 'Terjadi kesalahan saat mengubah kata sandi.';
    }
  }

  // ===============================================================
  // LOGOUT
  // ===============================================================

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ===============================================================
  // KIRIM OTP TELEPON
  // ===============================================================
  //
  // Pengganti Firebase verifyPhoneNumber().
  //
  // ===============================================================

  @override
  Future<String?> sendPhoneOtp({
    required String phoneNumber,
  }) async {
    final phone =
        _formatPhone(phoneNumber);

    if (phone.length < 10) {
      return 'Nomor handphone tidak valid.';
    }

    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
      );

      return null;
    } on AuthException catch (e) {
      return e.message.isNotEmpty
          ? e.message
          : 'Gagal mengirim kode OTP.';
    } catch (_) {
      return 'Terjadi kesalahan saat mengirim kode OTP.';
    }
  }

  // ===============================================================
  // VERIFIKASI OTP TELEPON
  // ===============================================================

  @override
  Future<String?> verifyPhoneOtp({
    required String phoneNumber,
    required String smsCode,
  }) async {
    final phone =
        _formatPhone(phoneNumber);

    final code =
        smsCode.trim();

    if (code.isEmpty) {
      return 'Kode OTP wajib diisi.';
    }

    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: code,
      );

      return null;
    } on AuthException catch (e) {
      return e.message.isNotEmpty
          ? e.message
          : 'Kode OTP tidak valid.';
    } catch (_) {
      return 'Terjadi kesalahan saat memverifikasi OTP.';
    }
  }
}
