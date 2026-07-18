import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../config/warna.dart';
import '../../services/riwayat_service.dart'; // Menggunakan RiwayatService Core yang sudah kita bangun
import '../../widgets/menu_item.dart'; // Menggunakan CustomBounce demi konsistensi sentuhan premium

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RiwayatService _riwayatService = RiwayatService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? "demo_uid";

  @override
  void initState() {
    super.initState();
    // Mengontrol 3 tab utama: Semua, Berhasil, Pending/Gagal
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Helper format mata uang Rupiah
  String _formatRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);
  }

  /// Helper untuk mengambil warna visual status transaksi secara dinamis
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sukses':
      case 'berhasil':
        return WarnaDesaPay.success;
      case 'pending':
      case 'menunggu':
        return WarnaDesaPay.warning;
      case 'gagal':
      default:
        return WarnaDesaPay.danger;
    }
  }

  /// Helper untuk mengambil ikon visual status transaksi secara dinamis
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'sukses':
      case 'berhasil':
        return Icons.check_circle_rounded;
      case 'pending':
      case 'menunggu':
        return Icons.watch_later_rounded;
      case 'gagal':
      default:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Menghapus tombol back karena ini menu utama Tab Utama
        title: const Text(
          "Riwayat Transaksi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            width: double.infinity,
            child: TabBar(
              controller: _tabController,
              indicatorColor: WarnaDesaPay.primary,
              indicatorWeight: 3,
              labelColor: WarnaDesaPay.primary,
              unselectedLabelColor: WarnaDesaPay.textSub,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
        children: [
          _buildDaftarRiwayat(filter: 'semua'),
          _buildDaftarRiwayat(filter: 'berhasil'),
          _buildDaftarRiwayat(filter: 'pending_gagal'),
        ],
      ),
    );
  }

  // =========================================================================
  // PIPI DATA REAL-TIME STREAM BUILDER (ANTI HARDCODED DATA)
  // =========================================================================
  Widget _buildDaftarRiwayat({required String filter}) {
    // Menghubungkan Stream secara reaktif ke Firestore data log transaksi DesaPay
    return StreamBuilder<List<dynamic>>(
      stream: _riwayatService.streamRiwayatTransaksi(uid: _uid, filter: filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: WarnaDesaPay.primary),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_rounded, size: 64, color: WarnaDesaPay.textSub.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  "Belum ada riwayat transaksi",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WarnaDesaPay.textSub),
                ),
              ],
            ),
          );
        }

        final listTransaksi = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: listTransaksi.length,
          itemBuilder: (context, index) {
            final tx = listTransaksi[index];
            final String status = tx['status'] ?? 'gagal';
            final Color statusColor = _getStatusColor(status);

            return CustomBounce(
              onTap: () {
                // Arahkan ke halaman detail resi/struk cetak di fase berikutnya
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: WarnaDesaPay.shadow.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      // Indikator Warna Garis Vertikal Sisi Kiri (Premium Highlight)
                      Container(
                        width: 5,
                        height: 84,
                        color: statusColor,
                      ),
                      
                      // Isi Konten Struk Transaksi Moduler
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 1. INFO LAYANAN & TUJUAN
                              Expanded(
                                child: Row(
                                  children: [
                                    // Bulatan Ikon Status (Mencerminkan desain di screenshot)
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getStatusIcon(status),
                                        color: statusColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    
                                    // Deskripsi Teks Nama Produk & Nomor
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            tx['nama_produk'] ?? "Layanan PPOB",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: WarnaDesaPay.textMain,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Tujuan: ${tx['nomor_tujuan'] ?? '-'}",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: WarnaDesaPay.textSub,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 8),

                              // 2. NOMINAL HARGA & TAG STATUS TEXT
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatRupiah(tx['harga'] ?? 0),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: WarnaDesaPay.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
