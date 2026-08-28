import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tambahkan ini untuk UID Transaksi
import '../../config/warna.dart';
import '../../services/firestore_service.dart'; // Ganti ke Firestore Service

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
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
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

class EwalletScreen extends StatefulWidget {
  final String? jenisEwallet;
  const EwalletScreen({this.jenisEwallet, super.key});

  @override
  State<EwalletScreen> createState() => _EwalletScreenState();
}

class _EwalletScreenState extends State<EwalletScreen> {
  bool _isMenuDetailAktif = false;
  String _ewalletTerpilih = "";
  final TextEditingController _nomorController = TextEditingController();
  List<Map<String, dynamic>> _daftarProdukEwallet = [];
  bool _sedangMemuat = false;

  @override
  void initState() {
    super.initState();
    if (widget.jenisEwallet != null) {
      _ewalletTerpilih = widget.jenisEwallet!;
      _isMenuDetailAktif = true;
      _panggilProdukEwallet(widget.jenisEwallet!);
    }
  }

  @override
  void dispose() {
    _nomorController.dispose();
    super.dispose();
  }

  //==========================================
  // AMBIL PRODUK DARI FIRESTORE (SIAP GO LIVE)
  //==========================================
  Future<void> _panggilProdukEwallet(String brand) async {
    setState(() {
      _sedangMemuat = true;
      _daftarProdukEwallet = [];
    });

    try {
      // Ambil data produk aktif dari Firestore
      List<Map<String, dynamic>> semuaProduk = await FirestoreService.ambilProdukAktif();

      String kataKunciBrand = brand.toUpperCase().trim();
      
      // Mapping ke penamaan baku (tergantung dari data Digiflazz di Firestore)
      if (kataKunciBrand.contains("GOJEK") || kataKunciBrand.contains("GOPAY")) {
        kataKunciBrand = "GO-PAY"; 
      } else if (kataKunciBrand.contains("GRAB")) {
        kataKunciBrand = "GRAB";
      } else if (kataKunciBrand.contains("MAXIM")) {
        kataKunciBrand = "MAXIM";
      } else if (kataKunciBrand.contains("SHOPEE")) {
        kataKunciBrand = "SHOPEEPAY";
      } else if (kataKunciBrand.contains("LINK")) {
        kataKunciBrand = "LINKAJA";
      }

      // Filter produk
      List<Map<String, dynamic>> produkDisaring = semuaProduk.where((produk) {
        String kategori = (produk['category'] ?? '').toString().toUpperCase();
        String namaBrand = (produk['brand'] ?? '').toString().toUpperCase();
        
        // Tembak kategori E-Money atau Games (karena MAXIM kadang masuk kategori Games)
        bool kriteriaKategori = kategori.contains('E-MONEY') || kategori.contains('GAMES') || kategori.contains('VOUCHER');
        bool kriteriaBrand = namaBrand == kataKunciBrand || namaBrand.contains(kataKunciBrand);

        return kriteriaKategori && kriteriaBrand;
      }).toList();

      // Urutkan dari harga paling murah (Modal + Margin)
      produkDisaring.sort((a, b) {
        int hargaA = (a['cost'] as num? ?? 0).toInt() + (a['margin'] as num? ?? 0).toInt();
        int hargaB = (b['cost'] as num? ?? 0).toInt() + (b['margin'] as num? ?? 0).toInt();
        return hargaA.compareTo(hargaB);
      });

      if (mounted) {
        setState(() {
          _daftarProdukEwallet = produkDisaring;
          _sedangMemuat = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sedangMemuat = false;
        });
        _tampilkanSnackBarError("Gagal memuat layanan. $e");
      }
    }
  }

  String _formatCurrency(dynamic value) {
    int parsed = int.tryParse(value.toString()) ?? 0;
    return parsed.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _tampilkanSnackBarError(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: WarnaDesaPay.danger ?? Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        title: Text(
          _isMenuDetailAktif ? "Top Up $_ewalletTerpilih" : "Top Up E-Wallet",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_isMenuDetailAktif && widget.jenisEwallet == null) {
              setState(() {
                _isMenuDetailAktif = false;
                _nomorController.clear();
                _daftarProdukEwallet.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isMenuDetailAktif ? _tampilanFormEwallet() : _tampilanMenuUtama(),
    );
  }

  //==========================================
  // TAMPILAN MENU UTAMA (GRID MODERN)
  //==========================================
  Widget _tampilanMenuUtama() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pilih Vendor E-Wallet",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.15, // Disesuaikan agar card lebih proporsional
            children: [
              _buildModernMenuCard(
                title: "DANA",
                desc: "Top Up Instan",
                gradient: const LinearGradient(colors: [Color(0xFF108EE9), Color(0xFF4BA6EB)]),
                icon: Icons.account_balance_wallet_rounded,
              ),
              _buildModernMenuCard(
                title: "OVO",
                desc: "Proses Realtime",
                gradient: const LinearGradient(colors: [Color(0xFF4C2A86), Color(0xFF6A3DB5)]),
                icon: Icons.wallet_membership_rounded,
              ),
              _buildModernMenuCard(
                title: "GoPay",
                desc: "Gojek Ecosystem",
                gradient: const LinearGradient(colors: [Color(0xFF00AED6), Color(0xFF00C7F5)]),
                icon: Icons.account_balance_wallet_outlined,
              ),
              _buildModernMenuCard(
                title: "ShopeePay",
                desc: "Belanja Praktis",
                gradient: const LinearGradient(colors: [Color(0xFFEE4D2D), Color(0xFFFF7359)]),
                icon: Icons.shopping_bag_rounded,
              ),
              _buildModernMenuCard(
                title: "LinkAja",
                desc: "BUMN Bersatu",
                gradient: const LinearGradient(colors: [Color(0xFFE52229), Color(0xFFFF5258)]),
                icon: Icons.currency_exchange_rounded,
              ),
              _buildModernMenuCard(
                title: "MAXIM",
                desc: "Driver & Customer",
                gradient: const LinearGradient(colors: [Color(0xFFFFE600), Color(0xFFFFEB3B)]),
                icon: Icons.local_taxi_rounded,
                textDark: true,
              ),
              _buildModernMenuCard(
                title: "GRAB",
                desc: "GrabPay Wallet",
                gradient: const LinearGradient(colors: [Color(0xFF00B14F), Color(0xFF00D15D)]),
                icon: Icons.directions_car_rounded,
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
    bool textDark = false
  }) {
    return CustomBounce(
      onTap: () {
        setState(() {
          _ewalletTerpilih = title;
          _isMenuDetailAktif = true;
        });
        _panggilProdukEwallet(title);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: textDark ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: textDark ? Colors.black87 : Colors.white, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textDark ? Colors.black87 : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 10,
                    color: textDark ? Colors.black54 : Colors.white70,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  //==========================================
  // TAMPILAN FORM INPUT & LIST PRODUK
  //==========================================
  Widget _tampilanFormEwallet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nomor Handphone / ID Akun $_ewalletTerpilih",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nomorController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  hintText: "Contoh: 081234567890",
                  hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 0),
                  prefixIcon: Icon(Icons.phone_android_rounded, color: WarnaDesaPay.primary),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            "Pilih Nominal Pengisian Saldo",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade800),
          ),
        ),
        Expanded(
          child: _sedangMemuat
              ? const Center(child: CircularProgressIndicator())
              : _daftarProdukEwallet.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            "Produk sedang tidak tersedia di server.\nSilakan coba beberapa saat lagi.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _daftarProdukEwallet.length,
                      itemBuilder: (context, index) {
                        final produk = _daftarProdukEwallet[index];
                        
                        // Kalkulasi harga jual
                        final int modal = (produk['cost'] as num? ?? 0).toInt();
                        final int margin = (produk['margin'] as num? ?? 0).toInt();
                        final int jual = modal + margin;

                        return CustomBounce(
                          onTap: () {
                            if (_nomorController.text.trim().isEmpty) {
                              _tampilkanSnackBarError("Mohon isi nomor tujuan terlebih dahulu!");
                              return;
                            }
                            _prosesBottomSheetKonfirmasi(produk, jual);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))
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
                                child: Icon(Icons.account_balance_wallet, color: WarnaDesaPay.primary),
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
                                "Rp ${_formatCurrency(jual)}",
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
  // BOTTOM SHEET INVOICE KONFIRMASI
  //==========================================
  void _prosesBottomSheetKonfirmasi(Map<String, dynamic> produk, int jual) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text("Konfirmasi Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow("Layanan Produk", produk['name'] ?? '-'),
              _buildInvoiceRow("Nomor Tujuan", _nomorController.text),
              _buildInvoiceRow("Provider Vendor", _ewalletTerpilih),
              _buildInvoiceRow("Metode Saldo", "Saldo Utama DesaPay"),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Pembayaran", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text("Rp ${_formatCurrency(jual)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WarnaDesaPay.primary))
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
                    Navigator.pop(context); // Tutup dialog
                    _eksekusiKirimPusat(produk, jual);
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
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  //==========================================
  // EKSEKUSI TRANSAKSI KE FIRESTORE
  //==========================================
  void _eksekusiKirimPusat(Map<String, dynamic> produk, int jual) async {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'USER_UNKNOWN';
      final refId = 'DPAY-EWL-${DateTime.now().millisecondsSinceEpoch}';

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
        'status': 'PENDING',
        'isTest': false,
      };

      // Simpan riwayat PENDING ke Firestore
      await FirestoreService.simpanTransaksi(trxData);

      if (mounted) Navigator.pop(context); // Tutup Loading

      // Tampilkan Receipt PENDING
      _tampilkanResiStatus(
        isGagal: false, 
        produkName: produk['name'] ?? '-', 
        statusTransaksi: "PENDING", 
        pesanServer: "Sedang diproses sistem. Silakan periksa riwayat."
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _tampilkanResiStatus(
          isGagal: true, 
          produkName: produk['name'] ?? '-', 
          statusTransaksi: "Gagal", 
          pesanServer: "Gagal mencatat transaksi: $e"
        );
      }
    }
  }

  void _tampilkanResiStatus({required bool isGagal, required String produkName, required String statusTransaksi, required String pesanServer}) {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isGagal ? Icons.cancel_rounded : Icons.access_time_rounded, size: 72, color: isGagal ? Colors.red.shade600 : Colors.orange.shade500),
              const SizedBox(height: 16),
              Text(isGagal ? "Transaksi Gagal" : "Transaksi Diproses", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildInvoiceRow("Produk", produkName),
                    _buildInvoiceRow("Tujuan", _nomorController.text),
                    _buildInvoiceRow("Status", statusTransaksi),
                    _buildInvoiceRow("Keterangan", pesanServer),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isGagal ? Colors.red : WarnaDesaPay.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (!isGagal) {
                      setState(() {
                        _nomorController.clear();
                        _isMenuDetailAktif = false;
                      });
                    }
                  },
                  child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
