import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Dibutuhkan untuk mendapatkan UID pengguna
import '../../config/warna.dart';
import '../../services/firestore_service.dart'; // Pastikan path ini benar sesuai struktur Anda

// Pembungkus Animasi Memantul (Micro-interaction) Premium untuk Komponen List & Tombol
class CustomBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const CustomBounce({super.key, required this.child, required this.onTap});

  @override
  State<CustomBounce> createState() => _CustomBounceState();
}

class _CustomBounceState extends State<CustomBounce> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class PlnScreen extends StatefulWidget {
  const PlnScreen({super.key});

  @override
  State<PlnScreen> createState() => _PlnScreenState();
}

class _PlnScreenState extends State<PlnScreen> {
  bool _isMenuTokenAktif = false;
  final TextEditingController _nomorController = TextEditingController();
  List<Map<String, dynamic>> _daftarToken = [];
  bool _sedangMemuat = false;

  @override
  void dispose() {
    _nomorController.dispose();
    super.dispose();
  }

  //==========================================
  // AMBIL PRODUK DARI FIRESTORE (SIAP GO LIVE)
  //==========================================
  Future<void> _panggilProdukFirestore() async {
    setState(() => _sedangMemuat = true);
    try {
      // Mengambil dari database Firestore Anda
      List<Map<String, dynamic>> semuaProduk = await FirestoreService.ambilProdukAktif();
      
      // Filter khusus kategori PLN
      List<Map<String, dynamic>> produkPln = semuaProduk.where((produk) {
        final kategori = (produk['category'] ?? '').toString().toUpperCase();
        return kategori == 'PLN' || kategori.contains('PLN');
      }).toList();

      // Urutkan dari harga termurah ke termahal
      produkPln.sort((a, b) {
        int hargaA = (a['cost'] as num? ?? 0).toInt() + (a['margin'] as num? ?? 0).toInt();
        int hargaB = (b['cost'] as num? ?? 0).toInt() + (b['margin'] as num? ?? 0).toInt();
        return hargaA.compareTo(hargaB);
      });

      setState(() => _daftarToken = produkPln);
    } catch (e) {
      setState(() => _daftarToken = []);
    }
    setState(() => _sedangMemuat = false);
  }

  String rupiah(dynamic angka) {
    int value = int.tryParse(angka.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC), // Warna background abu-abu sangat terang (bersih)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        title: Text(
          _isMenuTokenAktif ? "Beli Token Listrik" : "Layanan Listrik PLN",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_isMenuTokenAktif) {
              setState(() {
                _isMenuTokenAktif = false;
                _nomorController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isMenuTokenAktif ? _tampilanFormToken() : _tampilanMenuUtama(),
    );
  }

  //==========================================
  // TAMPILAN MENU UTAMA (DESAIN PREMIUM BIRU/PUTIH)
  //==========================================
  Widget _tampilanMenuUtama() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pilih Jenis Layanan PLN",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernMenuCard(
                  title: "Token Listrik",
                  desc: "Prabayar / Isi Ulang",
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0072FF), Color(0xFF00C6FF)], // Gradasi Biru Keren
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  icon: Icons.flash_on_rounded,
                  onTap: () {
                    setState(() => _isMenuTokenAktif = true);
                    _panggilProdukFirestore();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernMenuCard(
                  title: "Tagihan PLN",
                  desc: "Pascabayar Bulanan",
                  gradient: LinearGradient(
                    colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade400], // Gradasi Biru-Abu elegan
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  icon: Icons.receipt_long_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Layanan Tagihan PLN Pascabayar sedang dalam pemeliharaan berkala."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernMenuCard({
    required String title,
    required String desc,
    required Gradient gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CustomBounce(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            )
          ],
        ),
      ),
    );
  }

  //==========================================
  // TAMPILAN FORM INPUT & LIST TOKEN
  //==========================================
  Widget _tampilanFormToken() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CONTAINER INPUT ID PELANGGAN PREMIUM
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nomor Meter / ID Pelanggan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nomorController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9), // Biru keputihan yang sangat terang
                  hintText: "Contoh: 53123456789",
                  hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 0),
                  prefixIcon: Icon(Icons.electric_bolt_rounded, color: WarnaDesaPay.primary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Text(
            "Pilih Nominal Token Listrik",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade800),
          ),
        ),
        
        // LIST VIEW NOMINAL PRABAYAR
        Expanded(
          child: _sedangMemuat
              ? const Center(child: CircularProgressIndicator())
              : _daftarToken.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.electrical_services_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text(
                            "Produk token tidak ditemukan.\nPastikan produk telah ditambahkan di sistem.",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _daftarToken.length,
                      itemBuilder: (context, index) {
                        final produk = _daftarToken[index];
                        
                        // Menghitung harga modal + margin
                        final int modal = (produk['cost'] as num? ?? 0).toInt();
                        final int margin = (produk['margin'] as num? ?? 0).toInt();
                        final int jual = modal + margin;

                        return CustomBounce(
                          onTap: () {
                            if (_nomorController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Mohon isi nomor meteran / ID pelanggan Anda!"),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            _prosesBottomSheetInvoice(produk, jual);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.04), // Shadow biru tipis
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ],
                              border: Border.all(color: Colors.blue.withOpacity(0.05)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.flash_on_rounded, color: WarnaDesaPay.primary),
                              ),
                              title: Text(
                                produk['name'] ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Kode SKU: ${produk['sku']}",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ),
                              trailing: Text(
                                "Rp ${rupiah(jual)}",
                                style: TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  //==========================================
  // PREMIUM BOTTOM SHEET INVOICE
  //==========================================
  void _prosesBottomSheetInvoice(Map<String, dynamic> produk, int jual) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Konfirmasi Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow("Kategori Produk", "Listrik PLN Prabayar"),
              _buildInvoiceRow("Nama Layanan", produk['name'] ?? '-'),
              _buildInvoiceRow("No. Meter / ID", _nomorController.text),
              _buildInvoiceRow("Sumber Dana", "Saldo Utama DesaPay"),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Tagihan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    "Rp ${rupiah(jual)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WarnaDesaPay.primary),
                  )
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarnaDesaPay.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Tutup bottom sheet
                    _eksekusiTransaksiPusat(produk, jual);
                  },
                  child: const Text("Konfirmasi & Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  //==========================================
  // EKSEKUSI TRANSAKSI KE FIRESTORE
  //==========================================
  void _eksekusiTransaksiPusat(Map<String, dynamic> produk, int jual) async {
    // Menampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Dapatkan UID User
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'USER_UNKNOWN';

      // 2. Buat ID Referensi Unik Transaksi
      final refId = 'DPAY-PLN-${DateTime.now().millisecondsSinceEpoch}';

      // 3. Susun data transaksi
      final int modal = (produk['cost'] as num? ?? 0).toInt();
      final int margin = (produk['margin'] as num? ?? 0).toInt();

      final trxData = {
        'ref_id': refId,
        'uid': uid,
        'sku': produk['sku'],
        'productName': produk['name'],
        'category': produk['category'],
        'brand': produk['brand'],
        'customerNo': _nomorController.text,
        'amount': jual,      
        'cost': modal,       
        'margin': margin,    
        'status': 'PENDING', // Cloud function Anda akan memproses dan mengupdate ini
        'isTest': false,
      };

      // 4. Simpan ke database
      await FirestoreService.simpanTransaksi(trxData);

      if (mounted) Navigator.pop(context); // Tutup Loading

      // 5. Tampilkan Receipt (Struk)
      _tampilkanSlipReceipt(
        status: "PENDING",
        pesan: "Transaksi token sedang diproses sistem. Silakan periksa riwayat secara berkala.",
        produkName: produk['name'] ?? '',
        jual: jual,
      );

    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup Loading
      _tampilkanSlipReceipt(
        status: "GAGAL",
        pesan: "Sistem gagal mencatat transaksi: $e",
        produkName: produk['name'] ?? '',
        jual: jual,
      );
    }
  }

  void _tampilkanSlipReceipt({
    required String status,
    required String pesan,
    required String produkName,
    required int jual,
  }) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool isSukses = status == "SUKSES";
        bool isGagal = status == "GAGAL";

        Color statusColor = Colors.orange;
        IconData statusIcon = Icons.access_time_rounded;
        String titleReceipt = "Transaksi Diproses";

        if (isSukses) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle_rounded;
          titleReceipt = "Transaksi Sukses";
        } else if (isGagal) {
          statusColor = Colors.red;
          statusIcon = Icons.cancel_rounded;
          titleReceipt = "Transaksi Gagal";
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 72, color: statusColor),
              const SizedBox(height: 16),
              Text(
                titleReceipt,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildInvoiceRow("Produk", produkName),
                    _buildInvoiceRow("ID Pelanggan", _nomorController.text),
                    _buildInvoiceRow("Total Bayar", "Rp ${rupiah(jual)}"),
                    _buildInvoiceRow("Keterangan", pesan),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (!isGagal) {
                      setState(() {
                        _nomorController.clear();
                        _isMenuTokenAktif = false;
                      });
                    }
                  },
                  child: const Text("Selesai", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
