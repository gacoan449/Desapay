import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class DigiflazzService {
  // ===================================================
  // ENDPOINT RESMI API DIGIFLAZZ (UPDATED & CORRECTED)
  // ===================================================
  static const String _baseUrlTransaction = 'https://api.digiflazz.com/v1/transaction';
  static const String _baseUrlDeposit = 'https://api.digiflazz.com/v1/deposit';
  static const String _baseUrlCekSaldo = 'https://api.digiflazz.com/v1/cek-saldo';
  
  // Data akun testing/production Anda
  final String _username = 'rukaxigqnvno'; 
  final String _apiKey = "ba2b7ab6-33b0-5a48-b7f7-56a2f1b30d0b";

  // ===================================================
  // 1. FUNGSI AMBIL DAFTAR HARGA + MARKUP UNTUNG Rp 1.000
  // ===================================================
  Future<List<dynamic>> ambilSemuaProduk() async {
    try {
      final String signRaw = _username + _apiKey + 'pricelist';
      final String sign = md5.convert(utf8.encode(signRaw)).toString();

      final response = await http.post(
        Uri.parse(_baseUrlTransaction), // DIKOREKSI: Menggunakan endpoint transaksi yang benar
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "cmd": "prepaid",
          "username": _username,
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> produkAsli = data['data'] ?? [];
        
        const int keuntunganKita = 1000;

        // Type-safe mapping untuk menghindari crash konversi data numerik
        return produkAsli.map((item) {
          final int hargaAsli = int.tryParse(item['price'].toString()) ?? 0;
          item['price'] = hargaAsli + keuntunganKita;
          return item;
        }).toList();
      } else {
        if (kDebugMode) print("Pricelist Error: Status Code ${response.statusCode}");
        return [];
      }
    } catch (e) {
      if (kDebugMode) print("Pricelist Exception: $e");
      return [];
    }
  }

  // ===================================================
  // 2. FUNGSI TEMBAK TRANSAKSI PULSA/TOKEN/E-WALLET/PPOB
  // ===================================================
  Future<Map<String, dynamic>> kirimTransaksi({
    required String buyerSkuCode, 
    required String customerNo,   
  }) async {
    try {
      final String refId = "DESAPAY-${DateTime.now().millisecondsSinceEpoch}";
      final String signRaw = _username + _apiKey + refId;
      final String sign = md5.convert(utf8.encode(signRaw)).toString();

      final response = await http.post(
        Uri.parse(_baseUrlTransaction), // DIKOREKSI: Menggunakan endpoint transaksi yang benar
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _username,
          "buyer_sku_code": buyerSkuCode,
          "customer_no": customerNo,
          "ref_id": refId,
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {'status': 'Gagal', 'message': 'Format respon server tidak sesuai'};
      } else {
        return {'status': 'Gagal', 'message': 'Server merespon dengan status ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'Gagal', 'message': 'Terjadi gangguan koneksi sistem: $e'};
    }
  }

  // ===================================================
  // 3. FUNGSI MINTA TIKET DEPOSIT / ISI SALDO AGEN
  // ===================================================
  Future<Map<String, dynamic>> mintaTiketDeposit({
    required int jumlahNominal, 
  }) async {
    try {
      final String signRaw = _username + _apiKey + 'deposit';
      final String sign = md5.convert(utf8.encode(signRaw)).toString();

      final response = await http.post(
        Uri.parse(_baseUrlDeposit), // DIKOREKSI: Menggunakan endpoint deposit yang benar
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _username,
          "amount": jumlahNominal,
          "Bank": "BCA", 
          "owner_name": "Pemilik DesaPay", 
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {'status': 'Gagal', 'message': 'Format respon server tidak sesuai'};
      } else {
        return {'status': 'Gagal', 'message': 'Server merespon dengan status ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'Gagal', 'message': 'Terjadi gangguan koneksi: $e'};
    }
  }

  // ===================================================
  // 4. FUNGSI CEK STATUS TRANSFER DEPOSIT AGEN
  // ===================================================
  Future<Map<String, dynamic>> cekStatusDeposit({
    required int jumlahNominal,
  }) async {
    try {
      final String signRaw = _username + _apiKey + 'deposit';
      final String sign = md5.convert(utf8.encode(signRaw)).toString();

      final response = await http.post(
        Uri.parse(_baseUrlDeposit), // DIKOREKSI: Menggunakan endpoint deposit yang benar
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _username,
          "amount": jumlahNominal,
          "Bank": "BCA",
          "owner_name": "Pemilik DesaPay",
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
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
  Future<int> cekSaldoModal() async {
    try {
      final String signRaw = _username + _apiKey + "depo";
      final String sign = md5.convert(utf8.encode(signRaw)).toString();

      final response = await http.post(
        Uri.parse(_baseUrlCekSaldo),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "cmd": "deposit",
          "username": _username,
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Proteksi null safety pada ekstraksi nilai saldo modal agen
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
