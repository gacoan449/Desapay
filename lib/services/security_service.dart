import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan keamanan lokal DesaPay.
///
/// Menangani:
/// - Fingerprint
/// - Face ID / biometrik perangkat
/// - Status preferensi login biometrik
///
/// Catatan:
/// Data biometrik pengguna tidak disimpan oleh DesaPay.
/// Verifikasi dilakukan oleh sistem keamanan perangkat melalui local_auth.
class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _biometricEnabledKey = 'desapay_biometric_enabled';

  // ============================================================
  // CEK APAKAH PERANGKAT MENDUKUNG BIOMETRIK
  // ============================================================
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();

      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // MENDAPATKAN JENIS BIOMETRIK YANG TERSEDIA
  // ============================================================
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  // ============================================================
  // VERIFIKASI BIOMETRIK
  // ============================================================
  Future<bool> authenticate() async {
    try {
      final bool available = await isBiometricAvailable();

      if (!available) {
        return false;
      }

      // ✅ PERBAIKAN: Menyesuaikan parameter local_auth v3.0.0+
      // 'stickyAuth' diganti menjadi 'persistAcrossBackgrounding'
      // 'useErrorDialogs' dihapus karena penanganan error UI sekarang otomatis dikelola sistem
      return await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas untuk mengakses keamanan DesaPay',
        biometricOnly: false, 
        persistAcrossBackgrounding: true, 
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // AKTIFKAN LOGIN BIOMETRIK
  // ============================================================
  Future<bool> enableBiometric() async {
    final bool authenticated = await authenticate();

    if (!authenticated) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_biometricEnabledKey, true);

    return true;
  }

  // ============================================================
  // NONAKTIFKAN LOGIN BIOMETRIK
  // ============================================================
  Future<bool> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_biometricEnabledKey, false);

    return true;
  }

  // ============================================================
  // CEK STATUS LOGIN BIOMETRIK
  // ============================================================
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // ============================================================
  // HAPUS PENGATURAN BIOMETRIK
  // ============================================================
  Future<void> clearBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_biometricEnabledKey);
  }
}
