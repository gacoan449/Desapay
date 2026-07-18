import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Kontrak Layanan Digiflazz Service untuk DesaPay (Domain Layer)
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

/// Implementasi Layanan Integrasi API Digiflazz (Data Layer)
class DigiflazzService implements IDigiflazzService {
  static const String _baseUrlPriceList = 'https://api.digiflazz.com/v1/price-list';
  static const String _baseUrlTransaction = 'https://api.digiflazz.com/v1/transaction';
  static const String _baseUrlDeposit = 'https://api.digiflazz.com/v1/deposit';
  static const String _baseUrlCekSaldo = 'https://api.digiflazz.com/v1/cek-saldo';

  /// Mengambil data kredensial secara aman dari environment variables (.env)
  String get _username => dotenv.env['DIGIFLAZZ_USERNAME'] ?? '';
  String get _apiKey => dotenv.env['DIGIFLAZZ_API_KEY'] ?? '';

  /// Helper internal untuk melakukan enkripsi MD5 sesuai regulasi Digiflazz
  String _generateSign(String suffix) {
    final String rawString = _username + _apiKey + suffix;
    return md5.convert(utf8.encode(rawString)).toString();
  }

  // ===================================================
  // 1. FUNGSI AMBIL DAFTAR HARGA + MARKUP UNTUNG Rp 1.000
  // ===================================================
  @override
  Future<List<dynamic>> ambilSemuaProduk() async {
    try {
      final String sign = _generateSign('pricelist');

      final response = await http.post(
        Uri.parse(_baseUrlPriceList),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "cmd": "prepaid",
          "username": _username,
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Memeriksa struktur objek data dari respon Digiflazz
        if (data['data'] != null && data['data'] is List) {
          final List<dynamic> produkAsli = data['data'];
          const int keuntunganKita = 1000;

          return produkAsli.map((item) {
            final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
            final int hargaAsli = int.tryParse(itemMap['price'].toString()) ?? 0;
            itemMap['price'] = hargaAsli + keuntunganKita;
            return itemMap;
          }).toList();
        }
        
        if (data['data'] != null && data['data']['message'] != null) {
          throw Exception(data['data']['message']);
        }
        return [];
      } else {
        throw Exception("Server merespon dengan kode status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Gagal memuat daftar produk Digiflazz: ${e.toString()}");
    }
  }

  // ===================================================
  // 2. FUNGSI TEMBAK TRANSAKSI PULSA/TOKEN/E-WALLET/PPOB
  // ===================================================
  @override
  Future<Map<String, dynamic>> kirimTransaksi({
    required String buyerSkuCode,
    required String customerNo,
  }) async {
    try {
      final String refId = "DESAPAY-${DateTime.now().millisecondsSinceEpoch}";
      final String sign = _generateSign(refId);

      final response = await http.post(
        Uri.parse(_baseUrlTransaction),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _username,
          "buyer_sku_code": buyerSkuCode,
          "customer_no": customerNo,
          "ref_id": refId,
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        return {'status': 'Gagal', 'message': 'Format respon data transaksi tidak valid'};
      } else {
        return {'status': 'Gagal', 'message': 'Server transaksi merespon dengan kode: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'Gagal', 'message': 'Terjadi gangguan koneksi transaksi: ${e.toString()}'};
    }
  }

  // ===================================================
  // 3. FUNGSI MINTA TIKET DEPOSIT / ISI SALDO AGEN
  // ===================================================
  @override
  Future<Map<String, dynamic>> mintaTiketDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  }) async {
    try {
      final String sign = _generateSign('deposit');

      final response = await http.post(
        Uri.parse(_baseUrlDeposit),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _username,
          "amount": jumlahNominal,
          "Bank": bank.toUpperCase(),
          "owner_name": namaPemilik.trim(),
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        return {'status': 'Gagal', 'message': 'Format data tiket deposit tidak sesuai'};
      } else {
        return {'status': 'Gagal', 'message': 'Server deposit merespon dengan kode: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'Gagal', 'message': 'Terjadi masalah jaringan deposit: ${e.toString()}'};
    }
  }

  // ===================================================
  // 4. FUNGSI CEK STATUS TRANSFER DEPOSIT AGEN
  // ===================================================
  @override
  Future<Map<String, dynamic>> cekStatusDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  }) async {
    try {
      final String sign = _generateSign('deposit');

      final response = await http.post(
        Uri.parse(_baseUrlDeposit),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _username,
          "amount": jumlahNominal,
          "Bank": bank.toUpperCase(),
          "owner_name": namaPemilik.trim(),
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        return {};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  // ===================================================
  // 5. FUNGSI CEK SALDO MODAL UTAMA AGEN
  // ===================================================
  @override
  Future<int> cekSaldoModal() async {
    try {
      final String sign = _generateSign('depo');

      final response = await http.post(
        Uri.parse(_baseUrlCekSaldo),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "cmd": "deposit",
          "username": _username,
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['deposit'] != null) {
          return int.tryParse(data['data']['deposit'].toString()) ?? 0;
        }
        return 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }
}
