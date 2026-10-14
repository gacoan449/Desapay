import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// PIN dikelola sepenuhnya oleh Cloud Functions; hash dan penghitung percobaan
/// tidak pernah dibaca atau ditulis langsung oleh aplikasi.
class PinService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-southeast2');

  bool _validPin(String pin) => RegExp(r'^\\d{6}$').hasMatch(pin);
  bool _weakPin(String pin) =>
      RegExp(r'^(\\d)\\1{5}$').hasMatch(pin) ||
      pin == '123456' ||
      pin == '654321';

  Future<bool> hasPin() async {
    if (_auth.currentUser == null) return false;
    try {
      final result = await _functions.httpsCallable('pinHasPin').call();
      return result.data is Map && result.data['hasPin'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> createPin({
    required String pin,
    required String confirmation,
  }) async {
    if (_auth.currentUser == null) return 'Silakan login kembali.';
    if (!_validPin(pin)) return 'PIN harus terdiri dari 6 digit angka.';
    if (pin != confirmation) return 'Konfirmasi PIN tidak cocok.';
    if (_weakPin(pin)) return 'PIN terlalu mudah ditebak.';
    try {
      await _functions.httpsCallable('pinCreate').call({'pin': pin});
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Gagal membuat PIN.';
    } catch (_) {
      return 'Tidak dapat terhubung ke layanan PIN. Coba lagi.';
    }
  }

  Future<String?> changePin({
    required String oldPin,
    required String newPin,
    required String confirmation,
  }) async {
    if (_auth.currentUser == null) return 'Silakan login kembali.';
    if (!_validPin(oldPin) || !_validPin(newPin)) {
      return 'PIN harus terdiri dari 6 digit angka.';
    }
    if (newPin != confirmation) return 'Konfirmasi PIN tidak cocok.';
    if (oldPin == newPin) return 'PIN baru harus berbeda dari PIN lama.';
    if (_weakPin(newPin)) return 'PIN terlalu mudah ditebak.';
    try {
      await _functions.httpsCallable('pinChange').call({
        'oldPin': oldPin,
        'newPin': newPin,
      });
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Gagal mengubah PIN.';
    } catch (_) {
      return 'Tidak dapat terhubung ke layanan PIN. Coba lagi.';
    }
  }

  Future<bool> verifyPin(String pin) async {
    if (_auth.currentUser == null || !_validPin(pin)) return false;
    try {
      await _functions.httpsCallable('pinVerify').call({'pin': pin});
      return true;
    } on FirebaseFunctionsException {
      return false;
    }
  }

  /// Otorisasi terikat ke requestId, SKU dan nomor tujuan; hanya bisa dipakai
  /// sekali oleh backend dan kedaluwarsa dalam lima menit.
  Future<String> authorizePurchase({
    required String pin,
    required String requestId,
    required String sku,
    required String customerNo,
  }) async {
    if (_auth.currentUser == null) throw Exception('Silakan login kembali.');
    if (!_validPin(pin)) throw Exception('PIN harus terdiri dari 6 digit angka.');
    final result = await _functions.httpsCallable('pinAuthorizePurchase').call({
      'pin': pin,
      'requestId': requestId,
      'sku': sku,
      'customerNo': customerNo,
    });
    final data = result.data;
    if (data is! Map || data['authorizationId'] is! String) {
      throw Exception('Otorisasi PIN tidak valid.');
    }
    return data['authorizationId'] as String;
  }
}
