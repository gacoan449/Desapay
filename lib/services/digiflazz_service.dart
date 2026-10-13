import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// ============================================================
/// DIGIFLAZZ SERVICE - DESAPAY (VERSI AMAN)
///
/// Seluruh kredensial provider tetap berada di Cloud Functions.
/// ============================================================

abstract class IDigiflazzService {
  Future<List<dynamic>> ambilSemuaProduk();

  Future<Map<String, dynamic>> kirimTransaksi({
    required String buyerSkuCode,
    required String customerNo,
  });

  Future<Map<String, dynamic>> mintaTiketDeposit({
    required int jumlahNominal,
    String bank = '',
    String namaPemilik = '',
  });

  Future<Map<String, dynamic>> cekStatusDeposit({
    required int jumlahNominal,
    String bank = '',
    String namaPemilik = '',
  });

  Future<int> cekSaldoModal();
}

class DigiflazzService implements IDigiflazzService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-southeast2');

  @override
  Future<List<dynamic>> ambilSemuaProduk() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('digiflazzPriceList');
      final result = await callable.call();
      final data = result.data;

      if (data is Map && data['data'] is List) {
        return List<dynamic>.from(data['data']);
      } else if (data is List) {
        return List<dynamic>.from(data);
      }

      throw Exception('Data produk tidak valid.');
    } catch (e) {
      debugPrint('Gagal memuat produk dari Cloud Functions: $e');
      throw Exception('Gagal memuat daftar produk Digiflazz: $e');
    }
  }

  Future<Map<String, dynamic>> priceList() async => {'data': await ambilSemuaProduk()};

  @override
  Future<int> cekSaldoModal() async {
    try {
      final result = await _functions.httpsCallable('digiflazzCekSaldo').call();
      final data = result.data;
      if (data is Map && data['data'] is Map && data['data']['deposit'] != null) {
        return int.tryParse(data['data']['deposit'].toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Gagal cek saldo dari Cloud Functions: $e');
      throw Exception('Gagal mengambil saldo Digiflazz: $e');
    }
  }

  Future<Map<String, dynamic>> saldo() async => {'data': {'deposit': await cekSaldoModal()}};

  @override
  Future<Map<String, dynamic>> kirimTransaksi({
    required String buyerSkuCode,
    required String customerNo,
  }) async {
    try {
      final result = await _functions.httpsCallable('digiflazzKirimTransaksi').call({
        'buyer_sku_code': buyerSkuCode,
        'customer_no': customerNo,
      });
      final data = result.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'status': 'Gagal', 'message': 'Format respon transaksi tidak valid.'};
    } catch (e) {
      debugPrint('Error fungsi digiflazzKirimTransaksi: $e');
      return {'status': 'Gagal', 'message': 'Terjadi gangguan transaksi di server.'};
    }
  }

  Future<Map<String, dynamic>> transaction({required String refId}) async {
    try {
      final result = await _functions.httpsCallable('digiflazzCekTransaksi').call({'ref_id': refId});
      final data = result.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw Exception('Format respon tidak valid');
    } catch (e) {
      throw Exception('Gagal mengecek transaksi: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> mintaTiketDeposit({
    required int jumlahNominal,
    String bank = '',
    String namaPemilik = '',
  }) async {
    try {
      final result = await _functions.httpsCallable('digiflazzMintaDeposit').call({
        'amount': jumlahNominal,
        'Bank': bank,
        'owner_name': namaPemilik,
      });
      final data = result.data;
      if (data is Map && data['data'] is Map) return Map<String, dynamic>.from(data['data']);
      return {'status': 'Gagal', 'message': 'Format data tiket deposit tidak sesuai.'};
    } catch (e) {
      return {'status': 'Gagal', 'message': 'Terjadi masalah jaringan deposit: $e'};
    }
  }

  @override
  Future<Map<String, dynamic>> cekStatusDeposit({
    required int jumlahNominal,
    String bank = '',
    String namaPemilik = '',
  }) async {
    try {
      final result = await _functions.httpsCallable('digiflazzMintaDeposit').call({
        'amount': jumlahNominal,
        'Bank': bank,
        'owner_name': namaPemilik,
      });
      final data = result.data;
      if (data is Map && data['data'] is Map) return Map<String, dynamic>.from(data['data']);
      return {};
    } catch (_) {
      return {};
    }
  }
}
