import '../models/produk.dart';
import 'digiflazz_service.dart';

/// Kontrak Abstraksi Layanan Manajemen Produk PPOB DesaPay (Domain Layer)
abstract class IProdukService {
  Future<List<Produk>> dapatkanProdukBerdasarkanKategori({
    required KategoriProduk kategori,
    String? provider,
  });
  List<Produk> dapatkanFallbackPulsaTelkomsel();
}

/// Implementasi Layanan Manajemen Produk PPOB DesaPay (Data Layer)
class ProdukService implements IProdukService {
  final IDigiflazzService _digiflazzService;

  /// Dependency Injection via Constructor menjamin fleksibilitas testing arsitektur
  ProdukService({required IDigiflazzService digiflazzService})
      : _digiflazzService = digiflazzService;

  // =========================================================================
  // FALLBACK OFFLINE LOCAL DATA (Menjaga UX Premium saat Server Mengalami RTO)
  // =========================================================================
  @override
  List<Produk> dapatkanFallbackPulsaTelkomsel() {
    return const [
      Produk(
        kode: "TSEL5",
        nama: "Pulsa Telkomsel 5.000",
        harga: 6500,
        provider: "TELKOMSEL",
        kategori: KategoriProduk.pulsa,
      ),
      Produk(
        kode: "TSEL10",
        nama: "Pulsa Telkomsel 10.000",
        harga: 11500,
        provider: "TELKOMSEL",
        kategori: KategoriProduk.pulsa,
      ),
      Produk(
        kode: "TSEL20",
        nama: "Pulsa Telkomsel 20.000",
        harga: 21500,
        provider: "TELKOMSEL",
        kategori: KategoriProduk.pulsa,
      ),
      Produk(
        kode: "TSEL50",
        nama: "Pulsa Telkomsel 50.000",
        harga: 51000,
        provider: "TELKOMSEL",
        kategori: KategoriProduk.pulsa,
      ),
      Produk(
        kode: "TSEL100",
        nama: "Pulsa Telkomsel 100.000",
        harga: 100500,
        provider: "TELKOMSEL",
        kategori: KategoriProduk.pulsa,
      ),
    ];
  }

  // =========================================================================
  // REALTIME CORE FETCHING LOGIC (Mengambil data API & Menyaring Secara Cepat)
  // =========================================================================
  @override
  Future<List<Produk>> dapatkanProdukBerdasarkanKategori({
    required KategoriProduk kategori,
    String? provider,
  }) async {
    try {
      // 1. Ambil data mentah yang sudah ter-markup Rp 1.000 dari Digiflazz
      final List<dynamic> rawProdukList = await _digiflazzService.ambilSemuaProduk();
      
      if (rawProdukList.isEmpty) {
        // Jika data kosong (karena timeout/ggn API), berikan data fallback lokal jika mencari pulsa Telkomsel
        if (kategori == KategoriProduk.pulsa && (provider == null || provider.toUpperCase() == 'TELKOMSEL')) {
          return dapatkanFallbackPulsaTelkomsel();
        }
        return [];
      }

      // 2. Transformasi data JSON menjadi List Object Model Produk (Type-Safe)
      final List<Produk> seluruhProduk = rawProdukList.map((item) {
        return Produk.fromDigiflazz(Map<String, dynamic>.from(item));
      }).toList();

      // 3. Lakukan filter komprehensif berdasarkan Kategori dan Provider
      return seluruhProduk.where((produk) {
        final bool matchKategori = produk.kategori == kategori;
        final bool matchProvider = provider == null || 
            produk.provider.toUpperCase() == provider.toUpperCase().trim();
        
        // Produk mewah harus menyembunyikan item yang status gangguan dari provider pusat
        return matchKategori && matchProvider && produk.tersedia;
      }).toList();

    } catch (e) {
      // Jika terjadi error exception sistem, sistem Fintech DesaPay tidak boleh crash/force close.
      // Kita kembalikan data fallback darurat agar pengguna tetap mendapatkan antarmuka responsif.
      if (kategori == KategoriProduk.pulsa && (provider == null || provider.toUpperCase() == 'TELKOMSEL')) {
        return dapatkanFallbackPulsaTelkomsel();
      }
      return [];
    }
  }
}
