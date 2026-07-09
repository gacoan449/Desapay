import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class DigiflazzService {
  // Endpoint resmi Digiflazz
  final String _baseUrlPriceList = 'https://digiflazz.com';
  final String _baseUrlTransaction = 'https://digiflazz.com';
  
  // Data akun Anda (Development/Testing)
  final String _username = 'rukaxigqnvno'; 
  final String _apiKey = 'dev-cfc06820-7b62-11f1-b538-03d592ffb07f'; 

  // ==========================================
  // 1. FUNGSI AMBIL DAFTAR HARGA (PRICELIST)
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
  // 2. FUNGSI TEMBAK TRANSAKSI UTAMA (BARU)
  // ==========================================
  Future<Map<String, dynamic>> kirimTransaksi({
    required String buyerSkuCode, // Kode produk (contoh: xld10, pln20)
    required String customerNo,   // Nomor HP atau nomor meteran PLN pembeli
  }) async {
    try {
      // Membuat Ref ID unik otomatis berdasarkan waktu saat ini agar tidak bentrok
      String refId = "DESAPAY-${DateTime.now().millisecondsSinceEpoch}";

      // Aturan enkripsi transaksi Digiflazz: MD5(username + apiKey + ref_id)
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
        // Mengembalikan data hasil transaksi dari server (sukses/gagal/pending)
        return data['data'] ?? {'status': 'Gagal', 'message': 'Format response salah'};
      } else {
        return {'status': 'Gagal', 'message': 'Server merespon dengan status ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'Gagal', 'message': 'Terjadi gangguan koneksi: $e'};
    }
  }
}
