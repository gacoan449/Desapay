import 'package:cloud_functions/cloud_functions.dart';

/// PIN transaksi dikelola di Cloud Functions.
/// Hash, salt, percobaan gagal, dan lockout tidak pernah dibaca/ditulis client.
class PinService {
  PinService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast2');

  final FirebaseFunctions _functions;

  Future<bool> hasPin() async {
    try {
      final result =
          await _functions.httpsCallable('getTransactionPinStatus').call();
      final dynamic data = result.data;
      return data is Map && data['hasPin'] == true;
    } on FirebaseFunctionsException {
      rethrow;
    }
  }

  Future<String?> createPin({
    required String pin,
    required String confirmation,
  }) async {
    if (!_isValidPin(pin)) return 'PIN harus terdiri dari 6 digit angka.';
    if (pin != confirmation) return 'Konfirmasi PIN tidak cocok.';
    try {
      await _functions.httpsCallable('setTransactionPin').call(
        <String, dynamic>{'pin': pin, 'confirmation': confirmation},
      );
      return null;
    } on FirebaseFunctionsException catch (e) {
      return _message(e, 'Gagal membuat PIN transaksi.');
    } catch (_) {
      return 'Gagal membuat PIN transaksi. Periksa koneksi lalu coba lagi.';
    }
  }

  Future<String?> changePin({
    required String oldPin,
    required String newPin,
    required String confirmation,
  }) async {
    if (!_isValidPin(oldPin)) return 'PIN lama harus terdiri dari 6 digit angka.';
    if (!_isValidPin(newPin)) return 'PIN baru harus terdiri dari 6 digit angka.';
    if (newPin != confirmation) return 'Konfirmasi PIN baru tidak cocok.';
    if (oldPin == newPin) return 'PIN baru harus berbeda dari PIN lama.';

    try {
      await _functions.httpsCallable('changeTransactionPin').call(
        <String, dynamic>{
          'old_pin': oldPin,
          'new_pin': newPin,
          'confirmation': confirmation,
        },
      );
      return null;
    } on FirebaseFunctionsException catch (e) {
      return _message(e, 'Gagal mengubah PIN transaksi.');
    } catch (_) {
      return 'Gagal mengubah PIN transaksi. Periksa koneksi lalu coba lagi.';
    }
  }

  Future<bool> verifyPin(String pin) async {
    if (!_isValidPin(pin)) return false;
    try {
      final result = await _functions.httpsCallable('verifyTransactionPin').call(
        <String, dynamic>{'pin': pin},
      );
      final dynamic data = result.data;
      return data is Map && data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  bool _isValidPin(String pin) => RegExp(r'^\d{6}$').hasMatch(pin);

  String _message(FirebaseFunctionsException e, String fallback) {
    final message = e.message?.trim();
    if (message == null || message.isEmpty) return fallback;
    return message;
  }
}
