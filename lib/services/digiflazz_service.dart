import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class DigiflazzService {
  // Menggunakan URL resmi Digiflazz untuk menarik data
  final String _baseUrl = 'https://digiflazz.com';
  
  // Masukkan username Digiflazz Anda yang menggunakan huruf kecil semua
  final String _username = 'desapay'; 
  // Nanti setelah di-ACC, ganti teks ini dengan API Key asli dari dashboard Digiflazz Anda
  final String _apiKey = 'api_key_rahasia_anda'; 

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
        
        // MARKUP UNTUNG GLOBAL: Otomatis menaikkan semua harga modal server sebesar Rp 500
        int keuntunganKita = 500;

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
}
