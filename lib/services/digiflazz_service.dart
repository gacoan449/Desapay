import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class DigiflazzService {
  // Endpoint resmi Digiflazz untuk menarik data daftar harga (pricelist)
  final String _baseUrl = 'https://digiflazz.com';
  
  // Data akun Anda (Sudah terisi otomatis)
  final String _username = 'rukaxigqnvno'; 
  final String _apiKey = 'dev-cfc06820-7b62-11f1-b538-03d592ffb07f'; 

  Future<List<dynamic>> ambilSemuaProduk() async {
    try {
      // Aturan enkripsi keamanan (Sign) mutlak sesuai dokumen panduan Digiflazz
      String signRaw = _username + _apiKey + 'pricelist';
      String sign = md5.convert(utf8.encode(signRaw)).toString();

      final response = await http.post(
        Uri.parse(_baseUrl),
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
        
        // MARKUP UNTUNG GLOBAL: Otomatis menaikkan semua harga modal server sebesar Rp 1.000
        int keuntunganKita = 1000;

        return produkAsli.map((item) {
          // Menambahkan harga modal dari Digiflazz dengan keuntungan Rp 1.000
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
}
