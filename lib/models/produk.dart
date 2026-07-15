class Produk {
  final String kode;
  final String nama;
  final int harga;

  const Produk({
    required this.kode,
    required this.nama,
    required this.harga,
  });

  // ===================================================
  // 1. FACTORY FROM JSON (SAFE TYPE-CASTING COMPLIANT)
  // ===================================================
  /// Membuat objek [Produk] secara aman dari respons mentah Map/JSON API
  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      // Mengubah key 'buyer_sku_code' dari Digiflazz, fallback ke 'kode' jika lokal
      kode: (json["buyer_sku_code"] ?? json["kode"] ?? "").toString(),
      // Mengubah key 'product_name' dari Digiflazz, fallback ke 'nama' jika lokal
      nama: (json["product_name"] ?? json["nama"] ?? "-").toString(),
      // DIKOREKSI: Proteksi mutlak tipe data int untuk mencegah error type-casting double/string
      harga: int.tryParse((json["price"] ?? json["harga"] ?? 0).toString()) ?? 0,
    );
  }

  // ===================================================
  // 2. TO JSON (UNTUK LOCAL CACHING OFFLINE)
  // ===================================================
  /// Mengonversi objek [Produk] menjadi format Map/JSON untuk local storage
  Map<String, dynamic> toJson() {
    return {
      "kode": kode,
      "nama": nama,
      "harga": harga,
    };
  }

  // ===================================================
  // 3. COPY WITH HELPER (STATE-MANAGEMENT FRIENDLY)
  // ===================================================
  /// Memudahkan modifikasi parameter objek secara independen dan aman
  Produk copyWith({
    String? kode,
    String? nama,
    int? harga,
  }) {
    return Produk(
      kode: kode ?? this.kode,
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
    );
  }

  // ===================================================
  // 4. TO STRING OVERRIDE (FOR LUXURY DEBUGGING)
  // ===================================================
  @override
  String toString() {
    return 'Produk(kode: $kode, nama: $nama, harga: $harga)';
  }
}
