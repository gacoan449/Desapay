import 'package:cloud_functions/cloud_functions.dart';

/// Pemanggil Cloud Functions untuk alur penarikan saldo DesaPay.
/// requestId harus dibuat sekali per percobaan baru dan dipakai ulang
/// jika request yang sama diulang setelah timeout.
class WithdrawalService {
  WithdrawalService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: 'asia-southeast2',
            );

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> requestWithdrawal({
    required String requestId,
    required int amount,
    required String destinationType,
    required String destinationName,
    required String destinationAccount,
    required String destinationAccountName,
  }) async {
    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('requestWithdrawal').call(
      <String, dynamic>{
        'request_id': requestId,
        'amount': amount,
        'destination_type': destinationType,
        'destination_name': destinationName,
        'destination_account': destinationAccount,
        'destination_account_name': destinationAccountName,
      },
    );

    final dynamic data = result.data;
    if (data is! Map) {
      throw StateError('Respons penarikan tidak valid.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> reviewWithdrawal({
    required String requestId,
    required String action,
    String reason = '',
  }) async {
    final String normalizedAction = action.trim().toUpperCase();
    if (normalizedAction != 'APPROVE' &&
        normalizedAction != 'REJECT') {
      throw ArgumentError.value(
        action,
        'action',
        'Gunakan APPROVE atau REJECT.',
      );
    }

    final HttpsCallableResult<dynamic> result =
        await _functions.httpsCallable('adminReviewWithdrawal').call(
      <String, dynamic>{
        'request_id': requestId,
        'action': normalizedAction,
        'reason': reason,
      },
    );

    final dynamic data = result.data;
    if (data is! Map) {
      throw StateError('Respons review penarikan tidak valid.');
    }

    return Map<String, dynamic>.from(data);
  }
}
