import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class DigiflazzService {
  // Semua Alamat URL Resmi Digiflazz
  final String _baseUrlPriceList = 'https://digiflazz.com';
  final String _baseUrlTransaction = 'https://digiflazz.com';
  final String _baseUrlDeposit = 'https://digiflazz.com';
  
  // Data akun testing Anda (Ganti ke Production Key jika nanti sudah siap rilis)
  final String _username = 'rukaxigqnvno'; 
  final String _apiKey = 'dev-cfc06820-7b62-11f1-b538-03d592ffb07f'; 

  // ==========================================
  // 1. FUNGSI AMBIL DAFTAR HARGA + UNTUNG 1RB
  // ==========================================
  Future<List<dynamic>> ambilSemuaProduk() async {
    try {
      String signRaw = _username + _apiKey + 'pricelist';
      String sign = md5.convert(utf8.encode(signRaw)).toString();

      final response = await http.post(
        Uri.parse(_baseUrlPriceList),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "cmd": "prepaid",
          "username": _username,
          "sign": sign
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> produkAsli = data['data'] ?? [];
        
        // MARKUP UNTUNG GLOBAL: Rp 1.000
        int keuntunganKita = 1000;

        return produkAsli.map((item) {
          item['price'] = (item['price'] ?? 0) + keuntunganKita;
          return item;
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // 2. FUNGSI TEMBAK TRANSAKSI PULSA/TOKEN/E-WALLET
  // ==========================================
  Future<Map<String, dynamic>> kirimTransaksi({
    required String buyerSkuCode, 
    required String customerNo,   
  }) async {
    try {
      // Membuat Nomor Referensi unik otomatis agar transaksi tidak bentrok
      String refId = "DESAPAY-${DateTime.now().millisecondsSinceEpoch}";

      String signRaw = _username + _apiKey + refId;
      String sign = md5.convert(utf8.encode(signRaw)).toString();

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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {'status': 'Gagal', 'message': 'Format response salah'};
      } else {
        return {'status': 'Gagal', 'message': 'Server merespon dengan status ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'Gagal', 'message': 'Terjadi gangguan koneksi: $e'};
    }
  }

  // ==========================================
  // 3. FUNGSI MINTA TIKET DEPOSIT / ISI SALDO
  // ==========================================
  Future<Map<String, dynamic>> mintaTiketDeposit({
    required int jumlahNominal, 
  }) async {
    try {
      String signRaw = _username + _apiKey + 'deposit';
      String sign = md5.convert(utf8.encode(signRaw)).toString();

      final response = await http.post(
        Uri.parse(_baseUrlDeposit),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _username,
          "amount": jumlahNominal,
          "Bank": "BCA", 
          "owner_name": "Pemilik DesaPay", 
          "sign": sign
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {'status': 'Gagal', 'message': 'Format response salah'};
      } else {
        return {'status': 'Gagal', 'message': 'Server merespon dengan status ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'Gagal', 'message': 'Terjadi gangguan koneksi: $e'};
    }
  }
}
