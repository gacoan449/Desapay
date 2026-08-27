import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// ============================================================
/// DIGIFLAZZ SERVICE - DESAPAY
///
/// Tugas service ini hanya:
/// 1. Ambil produk Digiflazz
/// 2. Cek saldo Digiflazz
/// 3. Kirim transaksi
/// 4. Deposit
///
/// PENTING:
/// Tidak ada perhitungan margin di sini.
///
/// Harga dari Digiflazz = HARGA MODAL.
/// Margin dan harga jual diatur oleh Admin Dashboard
/// dan disimpan di Firestore.
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
  // ==========================================================
  // URL API
  // ==========================================================

  static const String _baseUrlPriceList =
      'https://api.digiflazz.com/v1/price-list';

  static const String _baseUrlTransaction =
      'https://api.digiflazz.com/v1/transaction';

  static const String _baseUrlDeposit =
      'https://api.digiflazz.com/v1/deposit';

  static const String _baseUrlCekSaldo =
      'https://api.digiflazz.com/v1/cek-saldo';

  // ==========================================================
  // KREDENSIAL DARI .ENV
  // ==========================================================

  String get _username =>
      dotenv.env['DIGIFLAZZ_USERNAME']?.trim() ?? '';

  String get _apiKey =>
      dotenv.env['DIGIFLAZZ_API_KEY']?.trim() ?? '';

  // ==========================================================
  // GENERATE SIGN
  // ==========================================================

  String _generateSign(String suffix) {
    final rawString =
        _username + _apiKey + suffix;

    return md5
        .convert(utf8.encode(rawString))
        .toString();
  }

  // ==========================================================
  // VALIDASI KREDENSIAL
  // ==========================================================

  void _validateCredential() {
    if (_username.isEmpty) {
      throw Exception(
        'DIGIFLAZZ_USERNAME belum dikonfigurasi.',
      );
    }

    if (_apiKey.isEmpty) {
      throw Exception(
        'DIGIFLAZZ_API_KEY belum dikonfigurasi.',
      );
    }
  }

  // ==========================================================
  // MAINTENANCE
  // ==========================================================

  void _validasiJamMaintenance() {
    final jamSekarang =
        DateTime.now().hour;

    if (jamSekarang >= 23) {
      throw Exception(
        'Sistem sedang dalam jadwal pemeliharaan rutin '
        '(23:00 - 00:00 WIB). '
        'Mohon coba beberapa saat lagi.',
      );
    }
  }

  // ==========================================================
  // PRICE LIST
  //
  // HASIL:
  // Harga "price" tetap harga MODAL asli Digiflazz.
  //
  // TIDAK ADA:
  // - margin
  // - harga jual
  // - harga coret
  // - asymmetric pricing
  // ==========================================================

  @override
  Future<List<dynamic>> ambilSemuaProduk() async {
    _validateCredential();

    try {
      final sign =
          _generateSign('pricelist');

      final response =
          await http
              .post(
                Uri.parse(
                  _baseUrlPriceList,
                ),
                headers: const {
                  'Content-Type':
                      'application/json',
                },
                body: jsonEncode({
                  'cmd': 'prepaid',
                  'username':
                      _username,
                  'sign': sign,
                }),
              )
              .timeout(
                const Duration(
                  seconds: 20,
                ),
              );

      if (response.statusCode != 200) {
        throw Exception(
          'Server price-list merespon '
          'HTTP ${response.statusCode}',
        );
      }

      final Map<String, dynamic>
          result =
          jsonDecode(response.body);

      final data = result['data'];

      if (data is! List) {
        throw Exception(
          result['data'] is Map
              ? result['data']['message']
                      ?.toString() ??
                  'Data produk tidak valid.'
              : 'Data produk tidak valid.',
        );
      }

      // ========================================================
      // KEMBALIKAN DATA ASLI DIGIFLAZZ
      // TANPA MARGIN
      // ========================================================

      return data.map((item) {
        return Map<String, dynamic>.from(
          item as Map,
        );
      }).toList();
    } catch (e) {
      throw Exception(
        'Gagal memuat daftar produk Digiflazz: $e',
      );
    }
  }

  // ==========================================================
  // ALIAS PRICE LIST
  //
  // Dibuat agar AdminDashboardScreen bisa memanggil:
  //
  // DigiflazzService().priceList()
  //
  // ==========================================================

  Future<Map<String, dynamic>> priceList() async {
    final products =
        await ambilSemuaProduk();

    return {
      'data': products,
    };
  }

  // ==========================================================
  // CEK SALDO
  // ==========================================================

  @override
  Future<int> cekSaldoModal() async {
    _validateCredential();

    try {
      final sign =
          _generateSign('depo');

      final response =
          await http
              .post(
                Uri.parse(
                  _baseUrlCekSaldo,
                ),
                headers: const {
                  'Content-Type':
                      'application/json',
                },
                body: jsonEncode({
                  'cmd': 'deposit',
                  'username':
                      _username,
                  'sign': sign,
                }),
              )
              .timeout(
                const Duration(
                  seconds: 20,
                ),
              );

      if (response.statusCode != 200) {
        throw Exception(
          'Server cek saldo merespon '
          'HTTP ${response.statusCode}',
        );
      }

      final Map<String, dynamic>
          result =
          jsonDecode(response.body);

      final data = result['data'];

      if (data is Map &&
          data['deposit'] != null) {
        return int.tryParse(
              data['deposit'].toString(),
            ) ??
            0;
      }

      return 0;
    } catch (e) {
      throw Exception(
        'Gagal mengambil saldo Digiflazz: $e',
      );
    }
  }

  // ==========================================================
  // ALIAS SALDO
  //
  // Digunakan Admin Dashboard.
  //
  // ==========================================================

  Future<Map<String, dynamic>> saldo() async {
    final jumlahSaldo =
        await cekSaldoModal();

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
    _validateCredential();

    try {
      _validasiJamMaintenance();

      // --------------------------------------------------------
      // Pastikan produk benar-benar ada
      // --------------------------------------------------------

      final semuaProduk =
          await ambilSemuaProduk();

      final produkDipilih =
          semuaProduk.cast<Map>().firstWhere(
        (product) =>
            product['buyer_sku_code']
                ?.toString() ==
            buyerSkuCode,
        orElse: () => <String, dynamic>{},
      );

      if (produkDipilih.isEmpty) {
        return {
          'status': 'Gagal',
          'message':
              'Produk tidak ditemukan atau sudah tidak aktif.',
        };
      }

      // --------------------------------------------------------
      // CEK SALDO MODAL
      // --------------------------------------------------------

      final hargaModal =
          int.tryParse(
                produkDipilih['price']
                        ?.toString() ??
                    '0',
              ) ??
              0;

      final saldo =
          await cekSaldoModal();

      if (saldo < hargaModal) {
        return {
          'status': 'Gagal',
          'message':
              'Stok sedang kosong, mohon coba beberapa saat lagi.',
        };
      }

      // --------------------------------------------------------
      // REF ID
      // --------------------------------------------------------

      final refId =
          'DESAPAY-${DateTime.now().millisecondsSinceEpoch}';

      final sign =
          _generateSign(refId);

      // --------------------------------------------------------
      // REQUEST TRANSAKSI
      // --------------------------------------------------------

      final response =
          await http
              .post(
                Uri.parse(
                  _baseUrlTransaction,
                ),
                headers: const {
                  'Content-Type':
                      'application/json',
                },
                body: jsonEncode({
                  'username':
                      _username,
                  'buyer_sku_code':
                      buyerSkuCode,
                  'customer_no':
                      customerNo,
                  'ref_id':
                      refId,
                  'sign':
                      sign,
                }),
              )
              .timeout(
                const Duration(
                  seconds: 45,
                ),
              );

      if (response.statusCode != 200) {
        return {
          'status': 'Gagal',
          'message':
              'Server transaksi merespon '
              'HTTP ${response.statusCode}',
        };
      }

      final Map<String, dynamic>
          result =
          jsonDecode(response.body);

      final data =
          result['data'];

      if (data is Map) {
        return Map<String, dynamic>.from(
          data,
        );
      }

      return {
        'status': 'Gagal',
        'message':
            'Format respon transaksi tidak valid.',
      };
    } catch (e) {
      return {
        'status': 'Gagal',
        'message':
            'Terjadi gangguan transaksi: $e',
      };
    }
  }

  // ==========================================================
  // ALIAS TRANSACTION
  //
  // Agar AdminDashboard bisa memanggil:
  //
  // DigiflazzService().transaction(...)
  //
  // ==========================================================

  Future<Map<String, dynamic>> transaction({
    required String refId,
  }) async {
    _validateCredential();

    try {
      final sign =
          _generateSign(refId);

      final response =
          await http
              .post(
                Uri.parse(
                  _baseUrlTransaction,
                ),
                headers: const {
                  'Content-Type':
                      'application/json',
                },
                body: jsonEncode({
                  'commands':
                      'status-pasca',
                  'username':
                      _username,
                  'ref_id':
                      refId,
                  'sign':
                      sign,
                }),
              )
              .timeout(
                const Duration(
                  seconds: 30,
                ),
              );

      if (response.statusCode != 200) {
        throw Exception(
          'Server transaksi merespon '
          'HTTP ${response.statusCode}',
        );
      }

      final Map<String, dynamic>
          result =
          jsonDecode(response.body);

      return result;
    } catch (e) {
      throw Exception(
        'Gagal mengecek transaksi: $e',
      );
    }
  }

  // ==========================================================
  // MINTA TIKET DEPOSIT
  // ==========================================================

  @override
  Future<Map<String, dynamic>> mintaTiketDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  }) async {
    _validateCredential();

    try {
      final sign =
          _generateSign('deposit');

      final response =
          await http
              .post(
                Uri.parse(
                  _baseUrlDeposit,
                ),
                headers: const {
                  'Content-Type':
                      'application/json',
                },
                body: jsonEncode({
                  'username':
                      _username,
                  'amount':
                      jumlahNominal,
                  'Bank':
                      bank.toUpperCase(),
                  'owner_name':
                      namaPemilik.trim(),
                  'sign':
                      sign,
                }),
              )
              .timeout(
                const Duration(
                  seconds: 30,
                ),
              );

      if (response.statusCode != 200) {
        return {
          'status': 'Gagal',
          'message':
              'Server deposit merespon '
              'HTTP ${response.statusCode}',
        };
      }

      final Map<String, dynamic>
          result =
          jsonDecode(response.body);

      if (result['data'] is Map) {
        return Map<String, dynamic>.from(
          result['data'],
        );
      }

      return {
        'status': 'Gagal',
        'message':
            'Format data tiket deposit tidak sesuai.',
      };
    } catch (e) {
      return {
        'status': 'Gagal',
        'message':
            'Terjadi masalah jaringan deposit: $e',
      };
    }
  }

  // ==========================================================
  // CEK STATUS DEPOSIT
  // ==========================================================

  @override
  Future<Map<String, dynamic>> cekStatusDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  }) async {
    _validateCredential();

    try {
      final sign =
          _generateSign('deposit');

      final response =
          await http
              .post(
                Uri.parse(
                  _baseUrlDeposit,
                ),
                headers: const {
                  'Content-Type':
                      'application/json',
                },
                body: jsonEncode({
                  'username':
                      _username,
                  'amount':
                      jumlahNominal,
                  'Bank':
                      bank.toUpperCase(),
                  'owner_name':
                      namaPemilik.trim(),
                  'sign':
                      sign,
                }),
              )
              .timeout(
                const Duration(
                  seconds: 25,
                ),
              );

      if (response.statusCode != 200) {
        return {};
      }

      final Map<String, dynamic>
          result =
          jsonDecode(response.body);

      if (result['data'] is Map) {
        return Map<String, dynamic>.from(
          result['data'],
        );
      }

      return {};
    } catch (e) {
      return {};
    }
  }
}
