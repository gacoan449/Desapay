import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../models/transaksi.dart';
import '../../services/transaksi_service.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium saat Kartu Riwayat Ditekan
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
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
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

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Transaksi> _semuaData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _semuaData = TransaksiService.semua();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String rupiah(dynamic angka) {
    int value = int.tryParse(angka.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  List<Transaksi> _filterData(String statusFilter) {
    if (statusFilter == "SEMUA") return _semuaData;
    return _semuaData.where((item) {
      final status = (item.status).toString().toUpperCase();
      if (statusFilter == "SUKSES") return status == "SUKSES" || status == "BERHASIL";
      return status != "SUKSES" && status != "BERHASIL";
    }).toList();
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s == "SUKSES" || s == "BERHASIL") return Colors.green.shade600;
    if (s == "GAGAL") return Colors.red.shade600;
    return Colors.orange.shade600;
  }

  IconData _getStatusIcon(String status) {
    final s = status.toUpperCase();
    if (s == "SUKSES" || s == "BERHASIL") return Icons.check_circle_rounded;
    if (s == "GAGAL") return Icons.cancel_rounded;
    return Icons.access_time_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Riwayat Transaksi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        // SEGMENTED FILTER TABS ALA E-WALLET PREMIUM
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            width: double.infinity,
            child: TabBar(
              controller: _tabController,
              indicatorColor: WarnaDesaPay.primary,
              labelColor: WarnaDesaPay.primary,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "Semua"),
                Tab(text: "Berhasil"),
                Tab(text: "Pending / Gagal"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDaftarRiwayat(_filterData("SEMUA")),
          _buildDaftarRiwayat(_filterData("SUKSES")),
          _buildDaftarRiwayat(_filterData("PENDING")),
        ],
      ),
    );
  }

  Widget _buildDaftarRiwayat(List<Transaksi> daftar) {
    if (daftar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "Belum Ada Transaksi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              "Riwayat transaksi kategori ini masih kosong.",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: daftar.length,
      itemBuilder: (context, index) {
        final item = daftar[index];
        final Color statusColor = _getStatusColor(item.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: CustomBounce(
            onTap: () => _tampilkanDetailResiBottomSheet(item),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  // BORDER INDIKATOR STATUS DI SISI KIRI LAYAKNYA CARD DIGITAL PREMIUM
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: statusColor, width: 5),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getStatusIcon(item.status), color: statusColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.produk,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tujuan: ${item.tujuan}",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Rp ${rupiah(item.harga)}",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // PREMIUM DIGITAL INVOICE RECEIPT SLIP SHEET
  void _tampilkanDetailResiBottomSheet(Transaksi item) {
    final Color statusColor = _getStatusColor(item.status);
    final String statusText = item.status.toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Icon(_getStatusIcon(item.status), size: 64, color: statusColor),
              const SizedBox(height: 12),
              Text(
                statusText == "SUKSES" || statusText == "BERHASIL" ? "Transaksi Berhasil" : statusText == "GAGAL" ? "Transaksi Gagal" : "Transaksi Diproses",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow("Nama Layanan / Produk", item.produk),
              _buildInvoiceRow("Nomor Identitas Tujuan", item.tujuan),
              _buildInvoiceRow("Metode Pembayaran", "Saldo Utama DesaPay"),
              _buildInvoiceRow("Status Transaksi", statusText),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Transaksi", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    "Rp ${rupiah(item.harga)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WarnaDesaPay.primary),
                  )
                ],
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
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup Salinan Resi", style: TextStyle(fontWeight: FontWeight.bold)),
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
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
