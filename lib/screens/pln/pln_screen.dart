import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';

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
  final DigiflazzService _digiflazzService = DigiflazzService();
  List<dynamic> _daftarToken = [];
  bool _sedangMemuat = false;

  @override
  void dispose() {
    _nomorController.dispose();
    super.dispose();
  }

  Future<void> _panggilProdukDigiflazz() async {
    setState(() => _sedangMemuat = true);
    try {
      List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk();
      List<dynamic> produkPln = semuaProduk.where((produk) {
        final kategori = (produk['category'] ?? '').toString().toUpperCase();
        final brand = (produk['brand'] ?? '').toString().toUpperCase();
        return kategori.contains('PLN') && brand.contains('PLN');
      }).toList();

      produkPln.sort((a, b) => (int.tryParse(a['price'].toString()) ?? 0).compareTo(int.tryParse(b['price'].toString()) ?? 0));
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
      backgroundColor: const Color(0xffF8FAFC),
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
                  "Token Listrik",
                  "Prabayar / Isi Ulang",
                  const Color(0xFFFFB300),
                  Icons.flash_on_rounded,
                  () {
                    setState(() => _isMenuTokenAktif = true);
                    _panggilProdukDigiflazz();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernMenuCard(
                  "Tagihan PLN",
                  "Pascabayar Bulanan",
                  const Color(0xFF0086FF),
                  Icons.receipt_long_rounded,
                  () {
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

  Widget _buildModernMenuCard(String title, String desc, Color color, IconData icon, VoidCallback onTap) {
    return CustomBounce(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
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
                  fillColor: const Color(0xFFF1F5F9),
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
                            "Produk token tidak ditemukan.\nPastikan status koneksi server pusat aktif.",
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
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
                                "Kode SKU: ${produk['buyer_sku_code']}",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ),
                            trailing: Text(
                              "Rp ${rupiah(produk['price'])}",
                              style: TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
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
                              _prosesBottomSheetInvoice(produk);
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // PREMIUM BOTTOM SHEET INVOICE
  void _prosesBottomSheetInvoice(dynamic produk) {
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
              _buildInvoiceRow("Nama Layanan", produk['product_name'] ?? '-'),
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
                    "Rp ${rupiah(produk['price'])}",
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
                    Navigator.pop(context);
                    _eksekusiTransaksiAPI(produk);
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

  // EKSEKUSI API & DIGITAL SLIP SLIDE SHEET
  void _eksekusiTransaksiAPI(dynamic produk) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic> hasil = await _digiflazzService.kirimTransaksi(
      buyerSkuCode: produk['buyer_sku_code'],
      customerNo: _nomorController.text,
    );

    if (mounted) Navigator.pop(context);

    String status = (hasil['status'] ?? 'Gagal').toString().toUpperCase();
    String pesanServer = hasil['sn'] ?? hasil['message'] ?? 'Tidak ada serial number';

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          bool isSukses = status == 'SUKSES';
          bool isGagal = status == 'GAGAL';

          Color statusColor = Colors.orange;
          IconData statusIcon = Icons.access_time_rounded;

          if (isSukses) {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle_rounded;
          } else if (isGagal) {
            statusColor = Colors.red;
            statusIcon = Icons.cancel_rounded;
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 72, color: statusColor),
                const SizedBox(height: 16),
                Text(
                  isSukses ? "Transaksi Sukses" : isGagal ? "Transaksi Gagal" : "Transaksi Diproses",
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
                      _buildInvoiceRow("Produk", produk['product_name'] ?? '-'),
                      _buildInvoiceRow("ID Pelanggan", _nomorController.text),
                      _buildInvoiceRow("Total Bayar", "Rp ${rupiah(produk['price'])}"),
                      _buildInvoiceRow("Token / Ref SN", pesanServer),
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
}
