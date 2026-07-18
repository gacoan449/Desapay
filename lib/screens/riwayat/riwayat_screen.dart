import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../config/warna.dart';
import '../../models/transaksi.dart';
import '../../services/riwayat_service.dart';
import '../../widgets/menu_item.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);
  }

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
        automaticallyImplyLeading: false,
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

  Widget _buildDaftarRiwayat({required String filter}) {
    return StreamBuilder<List<Transaksi>>(
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
                const Text(
                  "Belum ada riwayat transaksi",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WarnaDesaPay.textSub),
                ),
              ],
            ),
          );
        }

        final List<Transaksi> listTransaksi = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: listTransaksi.length,
          itemBuilder: (context, index) {
            final Transaksi tx = listTransaksi[index];
            // PERBAIKAN MUTLAK: Mengambil nilai representasi String dari data Enum secara aman
            final String status = tx.status.name; 
            final Color statusColor = _getStatusColor(status);

            return CustomBounce(
              onTap: () {},
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
                      Container(
                        width: 5,
                        height: 84,
                        color: statusColor,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            tx.namaProduk,
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
                                            "Tujuan: ${tx.nomorTujuan}",
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatRupiah(tx.hargaNominal),
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
