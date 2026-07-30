import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';

// Pembungkus Animasi Memantul (Micro-interaction) untuk E-Wallet Selektor
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
  final DigiflazzService _digiflazzService = DigiflazzService();
  List<dynamic> _daftarProdukEwallet = [];
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

  // PERBAIKAN: Fungsi Nembak Digiflazz yang kebal dari Infinite Loading
  Future<void> _panggilProdukEwallet(String brand) async {
    setState(() {
      _sedangMemuat = true;
      _daftarProdukEwallet = []; // Kosongkan list sebelumnya
    });

    try {
      // Ambil data dengan batas waktu (timeout) maksimal 15 detik agar tidak muter-muter terus
      List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Koneksi ke server Digiflazz terputus (Timeout)"),
      );

      String kataKunciBrand = brand.toUpperCase().trim();
      
      // Mapping ke penamaan baku Digiflazz
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

      // Filter produk berdasarkan kategori E-Money & Brand
      List<dynamic> produkDisaring = semuaProduk.where((produk) {
        if (produk == null) return false;
        
        String kategori = (produk['category'] ?? '').toString().toUpperCase();
        String namaBrand = (produk['brand'] ?? '').toString().toUpperCase();
        
        // Cek jika produk ditutup oleh Digiflazz (jika ada field seller_product_status)
        bool isAktif = true;
        if (produk.containsKey('seller_product_status')) {
          isAktif = produk['seller_product_status'] == true;
        }

        // Tembak kategori E-Money atau Games (karena MAXIM kadang masuk kategori Games)
        bool kriteriaKategori = kategori.contains('E-MONEY') || kategori.contains('GAMES') || kategori.contains('VOUCHER');
        bool kriteriaBrand = namaBrand == kataKunciBrand || namaBrand.contains(kataKunciBrand);

        return kriteriaKategori && kriteriaBrand && isAktif;
      }).toList();

      // Urutkan dari harga paling murah
      produkDisaring.sort((a, b) {
        int hargaA = int.tryParse(a['price'].toString()) ?? 0;
        int hargaB = int.tryParse(b['price'].toString()) ?? 0;
        return hargaA.compareTo(hargaB);
      });

      if (mounted) {
        setState(() {
          _daftarProdukEwallet = produkDisaring;
          _sedangMemuat = false;
        });
      }
    } catch (e) {
      debugPrint("API Error: $e");
      if (mounted) {
        setState(() {
          _sedangMemuat = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat layanan. $e"),
            backgroundColor: WarnaDesaPay.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
            childAspectRatio: 1.25,
            children: [
              _buildModernMenuCard("DANA", "Top Up Instan", const Color(0xFF108EE9), Icons.account_balance_wallet_rounded),
              _buildModernMenuCard("OVO", "Proses Realtime", const Color(0xFF4C2A86), Icons.wallet_membership_rounded),
              _buildModernMenuCard("GoPay", "Gojek Ecosystem", const Color(0xFF00AED6), Icons.account_balance_wallet_outlined),
              _buildModernMenuCard("ShopeePay", "Belanja Praktis", const Color(0xFFEE4D2D), Icons.shopping_bag_rounded),
              _buildModernMenuCard("LinkAja", "BUMN Bersatu", const Color(0xFFE52229), Icons.currency_exchange_rounded),
              _buildModernMenuCard("MAXIM", "Driver & Customer", const Color(0xFFFFE600), Icons.local_taxi_rounded, textDark: true),
              _buildModernMenuCard("GRAB", "GrabPay Wallet", const Color(0xFF00B14F), Icons.directions_car_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernMenuCard(String title, String desc, Color color, IconData icon, {bool textDark = false}) {
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
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: textDark ? Colors.black87 : Colors.white, size: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textDark ? Colors.black87 : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
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
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: WarnaDesaPay.primary),
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
              ? const Center(child: CircularProgressIndicator(color: WarnaDesaPay.primary))
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              produk['product_name'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Kode: ${produk['buyer_sku_code']}",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ),
                            trailing: Text(
                              "Rp ${_formatCurrency(produk['price'])}",
                              style: const TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            onTap: () {
                              if (_nomorController.text.trim().isEmpty) {
                                _tampilkanSnackBarError("Mohon isi nomor tujuan terlebih dahulu!");
                                return;
                              }
                              _prosesBottomSheetKonfirmasi(produk);
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _formatCurrency(dynamic value) {
    int parsed = int.tryParse(value.toString()) ?? 0;
    return parsed.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _tampilkanSnackBarError(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: WarnaDesaPay.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _prosesBottomSheetKonfirmasi(dynamic produk) {
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
              _buildInvoiceRow("Layanan Produk", produk['product_name'] ?? '-'),
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
                  Text("Rp ${_formatCurrency(produk['price'])}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WarnaDesaPay.primary))
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
                    Navigator.pop(context);
                    _eksekusiKirimAPI(produk);
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

  void _eksekusiKirimAPI(dynamic produk) async {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: WarnaDesaPay.primary)),
    );

    try {
      Map<String, dynamic> hasil = await _digiflazzService.kirimTransaksi(
        buyerSkuCode: produk['buyer_sku_code'],
        customerNo: _nomorController.text,
      );

      if (mounted) Navigator.pop(context);

      String statusTransaksi = hasil['status'] ?? 'Gagal';
      String pesanServer = hasil['sn'] ?? hasil['message'] ?? 'Tidak ada serial number';

      if (mounted) _tampilkanResiStatus(isGagal: statusTransaksi == 'Gagal', produk: produk, statusTransaksi: statusTransaksi, pesanServer: pesanServer);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _tampilkanResiStatus(isGagal: true, produk: produk, statusTransaksi: "Gagal", pesanServer: e.toString());
      }
    }
  }

  void _tampilkanResiStatus({required bool isGagal, required dynamic produk, required String statusTransaksi, required String pesanServer}) {
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
              Icon(isGagal ? Icons.cancel_rounded : Icons.check_circle_rounded, size: 72, color: isGagal ? Colors.red.shade600 : Colors.green.shade600),
              const SizedBox(height: 16),
              Text(isGagal ? "Transaksi Gagal" : "Transaksi Diproses", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildInvoiceRow("Produk", produk['product_name'] ?? '-'),
                    _buildInvoiceRow("Tujuan", _nomorController.text),
                    _buildInvoiceRow("Status", statusTransaksi),
                    _buildInvoiceRow("Ref/SN", pesanServer),
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
