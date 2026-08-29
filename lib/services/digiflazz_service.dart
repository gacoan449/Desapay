import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// ============================================================
/// DIGIFLAZZ SERVICE - DESAPAY (VERSI AMAN)
///
/// PERBAIKAN: Seluruh logika hash MD5 dan API Key dihapus dari klien.
/// Aplikasi sekarang berkomunikasi murni melalui Firebase Cloud Functions.
/// 
/// Pastikan Anda telah membuat HttpsCallable functions berikut di `index.js`:
/// 1. digiflazzPriceList
/// 2. digiflazzCekSaldo
/// 3. digiflazzKirimTransaksi
/// 4. digiflazzCekTransaksi
/// 5. digiflazzMintaDeposit
/// ============================================================

abstract class IDigiflazzService {
  Future<List<dynamic>> ambilSemuaProduk();

  Future<Map<String, dynamic>> kirimTransaksi({
    required String buyerSkuCode,
    required String customerNo,
  });

  Future<Map<String, dynamic>> mintaTiketDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  });

  Future<Map<String, dynamic>> cekStatusDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  });

  Future<int> cekSaldoModal();
}

class DigiflazzService implements IDigiflazzService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ==========================================================
  // PRICE LIST
  // ==========================================================
  @override
  Future<List<dynamic>> ambilSemuaProduk() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('digiflazzPriceList');
      final result = await callable.call();

      final data = result.data;

      // Antisipasi struktur balikan dari backend
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

  // ALIAS PRICE LIST (Untuk Admin Dashboard)
  Future<Map<String, dynamic>> priceList() async {
    final products = await ambilSemuaProduk();
    return {
      'data': products,
    };
  }

  // ==========================================================
  // CEK SALDO
  // ==========================================================
  @override
  Future<int> cekSaldoModal() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('digiflazzCekSaldo');
      final result = await callable.call();

      final data = result.data;
      if (data is Map && data['data'] != null && data['data']['deposit'] != null) {
        return int.tryParse(data['data']['deposit'].toString()) ?? 0;
      }

      return 0;
    } catch (e) {
      debugPrint('Gagal cek saldo dari Cloud Functions: $e');
      throw Exception('Gagal mengambil saldo Digiflazz: $e');
    }
  }

  // ALIAS SALDO (Untuk Admin Dashboard)
  Future<Map<String, dynamic>> saldo() async {
    final jumlahSaldo = await cekSaldoModal();
    return {
      'data': {
        'deposit': jumlahSaldo,
      },
    };
  }

  // ==========================================================
  // KIRIM TRANSAKSI
  // ==========================================================
  @override
  Future<Map<String, dynamic>> kirimTransaksi({
    required String buyerSkuCode,
    required String customerNo,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('digiflazzKirimTransaksi');
      final result = await callable.call({
        'buyer_sku_code': buyerSkuCode,
        'customer_no': customerNo,
      });

      final data = result.data;

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return {
        'status': 'Gagal',
        'message': 'Format respon transaksi tidak valid.',
      };
    } catch (e) {
      debugPrint('Error fungsi digiflazzKirimTransaksi: $e');
      return {
        'status': 'Gagal',
        'message': 'Terjadi gangguan transaksi di server.',
      };
    }
  }

  // ALIAS TRANSACTION (Untuk cek status dari Admin Dashboard)
  Future<Map<String, dynamic>> transaction({
    required String refId,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('digiflazzCekTransaksi');
      final result = await callable.call({
        'ref_id': refId,
      });

      final data = result.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception('Format respon tidak valid');
    } catch (e) {
      throw Exception('Gagal mengecek transaksi: $e');
    }
  }

  // ==========================================================
  // DEPOSIT
  // ==========================================================
  @override
  Future<Map<String, dynamic>> mintaTiketDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('digiflazzMintaDeposit');
      final result = await callable.call({
        'amount': jumlahNominal,
        'Bank': bank,
        'owner_name': namaPemilik,
      });

      final data = result.data;

      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data']);
      }

      return {
        'status': 'Gagal',
        'message': 'Format data tiket deposit tidak sesuai.',
      };
    } catch (e) {
      return {
        'status': 'Gagal',
        'message': 'Terjadi masalah jaringan deposit: $e',
      };
    }
  }

  @override
  Future<Map<String, dynamic>> cekStatusDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('digiflazzMintaDeposit');
      final result = await callable.call({
        'amount': jumlahNominal,
        'Bank': bank,
        'owner_name': namaPemilik,
      });

      final data = result.data;
      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data']);
      }

      return {};
    } catch (e) {
      return {};
    }
  }
}
