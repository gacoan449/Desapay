import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import Konfigurasi & Widget Modular Utama (CTO Standard)
import '../../config/warna.dart';
import '../../widgets/menu_item.dart'; // Menggunakan CustomBounce pusat terstandardisasi

/// Halaman Command Center / Panel Admin DesaPay (Privat & Terenkripsi)
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _adminTabController;
  
  final TextEditingController promoController = TextEditingController();
  final TextEditingController bannerController = TextEditingController();
  final TextEditingController namaMenuController = TextEditingController();
  final TextEditingController ikonController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _adminTabController = TabController(length: 3, vsync: this);
    _loadInitialConfiguration();
  }

  /// Memuat konfigurasi teks promosi dan banner yang sedang live
  Future<void> _loadInitialConfiguration() async {
    try {
      DocumentSnapshot doc = await _firestore.collection("pengaturan").doc("aplikasi").get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          bannerController.text = data["teksBanner"] ?? "";
          promoController.text = data["teksPromo"] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat konfigurasi admin: $e");
    }
  }

  @override
  void dispose() {
    _adminTabController.dispose();
    promoController.dispose();
    bannerController.dispose();
    namaMenuController.dispose();
    ikonController.dispose();
    super.dispose();
  }

  /// Menyimpan perubahan teks promo langsung ke aplikasi pengguna (Real-time)
  Future<void> _simpanPerubahanPromo() async {
    if (promoController.text.trim().isEmpty || bannerController.text.trim().isEmpty) {
      _tampilkanSnackBar("Semua kolom pengaturan teks wajib diisi", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection("pengaturan").doc("aplikasi").set({
        "teksPromo": promoController.text.trim(),
        "teksBanner": bannerController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _tampilkanSnackBar("Konfigurasi Promosi DesaPay Berhasil Diperbarui secara Live!", isError: false);
    } catch (e) {
      if (!mounted) return;
      _tampilkanSnackBar("Gagal menyimpan data: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menambah tombol menu PPOB baru langsung tanpa update APK (Over-the-Air)
  Future<void> _tambahMenuLayanan() async {
    if (namaMenuController.text.trim().isEmpty || ikonController.text.trim().isEmpty) {
      _tampilkanSnackBar("Nama menu dan kode ikon wajib diisi", isError: true);
      return;
    }

    try {
      String idMenu = namaMenuController.text.trim().toLowerCase().replaceAll(' ', '_');
      await _firestore.collection("menu_layanan").doc(idMenu).set({
        "id": idMenu,
        "nama": namaMenuController.text.trim(),
        "ikon": ikonController.text.trim(),
        "isAktif": true,
        "urutan": 99, // Taruh di urutan paling belakang secara default
      });

      if (!mounted) return;
      namaMenuController.clear();
      ikonController.clear();
      Navigator.pop(context); // Tutup BottomSheet
      _tampilkanSnackBar("Menu Layanan Baru Live Terpasang Sukses!", isError: false);
    } catch (e) {
      if (!mounted) return;
      _tampilkanSnackBar("Gagal menambah menu: $e", isError: true);
    }
  }

  /// Menampilkan laci bawah untuk input menu baru
  void _tampilkanBottomSheetTambahMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
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
                  decoration: BoxDecoration(color: WarnaDesaPay.textSub.withOpacity(0.3), borderRadius: BorderRadius.circular(10))
                )
              ),
              const SizedBox(height: 24),
              const Text("Tambah Grid Menu Baru (Live OTA)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain)),
              const SizedBox(height: 20),
              _buildModernInput(context: context, controller: namaMenuController, label: "Nama Modul Menu", hint: "Contoh: Voucher Game"),
              const SizedBox(height: 16),
              _buildModernInput(context: context, controller: ikonController, label: "Kode Aksen Ikon Material", hint: "Contoh: gamepad_rounded"),
              const SizedBox(height: 32),
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
                  onPressed: _tambahMenuLayanan,
                  child: const Text("Publikasikan Menu Secara Live", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _tampilkanSnackBar(String pesan, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isError ? WarnaDesaPay.danger : WarnaDesaPay.success,
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    int parsed = int.tryParse(value.toString()) ?? 0;
    return parsed.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.darkCard, // Dark Slate Grey Mewah khusus Admin
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("HQ Command Center", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5)),
            Text("DesaPay Administrator Mode", style: TextStyle(fontSize: 11, color: WarnaDesaPay.warning, fontWeight: FontWeight.w600)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: WarnaDesaPay.darkBg,
            child: TabBar(
              controller: _adminTabController,
              indicatorColor: WarnaDesaPay.warning,
              indicatorWeight: 3,
              labelColor: WarnaDesaPay.warning,
              unselectedLabelColor: WarnaDesaPay.textSub,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.tune_rounded, size: 18), text: "KONTEN UI"),
                Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: "MUTASI"),
                Tab(icon: Icon(Icons.support_agent_rounded, size: 18), text: "TIKET CS"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _adminTabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildPanelKontenUI(),
          _buildPanelLiveMutasi(),
          _buildPanelTiketCS(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: KONTEN CONTROL PANEL & GRID MENU
  // ==========================================
  Widget _buildPanelKontenUI() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PANEL PROMO
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WarnaDesaPay.lightCard, 
              borderRadius: BorderRadius.circular(24), 
              boxShadow: [BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.amp_stories_rounded, color: WarnaDesaPay.warning),
                    SizedBox(width: 8),
                    Text("Kampanye & Teks Berjalan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildModernInput(context: context, controller: bannerController, label: "Teks Pengumuman Header", hint: "Tulis pengumuman maintenance/promo...", maxLines: 2),
                const SizedBox(height: 16),
                _buildModernInput(context: context, controller: promoController, label: "Teks Ticker Beranda", hint: "Tulis promo berjalan di dashboard...", maxLines: 2),
                const SizedBox(height: 24),
                CustomBounce(
                  onTap: _simpanPerubahanPromo,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [WarnaDesaPay.warning, Color(0xFFD97706)]), // Amber to Amber 600
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("UPDATE REALTIME PLATFORM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // PANEL MANAJEMEN MENU
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Manajemen Modul Layanan", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain)),
              CustomBounce(
                onTap: _tampilkanBottomSheetTambahMenu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: WarnaDesaPay.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_circle_rounded, size: 16, color: WarnaDesaPay.primary),
                      SizedBox(width: 4),
                      Text("Tambah", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: WarnaDesaPay.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection("menu_layanan").orderBy("urutan").snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: WarnaDesaPay.primary)));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("Belum ada menu custom yang dibuat.", style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 12)));
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final item = docs[index].data() as Map<String, dynamic>;
                  bool isAktif = item["isAktif"] ?? false;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: WarnaDesaPay.lightCard, 
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WarnaDesaPay.lightField)
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: WarnaDesaPay.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.grid_view_rounded, color: WarnaDesaPay.primary, size: 20), // Placeholder ikon
                      ),
                      title: Text(item["nama"] ?? "-", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: WarnaDesaPay.textMain)),
                      subtitle: Text("ID Modul: ${item["id"]}", style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 11)),
                      trailing: Switch.adaptive(
                        value: isAktif,
                        activeColor: WarnaDesaPay.success,
                        onChanged: (val) {
                          _firestore.collection("menu_layanan").doc(item["id"]).update({"isAktif": val});
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: LIVE MUTASI TRANSAKSI
  // ==========================================
  Widget _buildPanelLiveMutasi() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("transaksi").orderBy("waktu", descending: true).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: WarnaDesaPay.primary));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 48, color: WarnaDesaPay.textSub.withOpacity(0.3)),
                const SizedBox(height: 10),
                const Text("Belum ada log transaksi terekam di sistem.", style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 13)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final log = docs[index].data() as Map<String, dynamic>;
            String status = (log["status"] ?? "PENDING").toString().toUpperCase();
            
            Color statusColor;
            if (status.contains("SUKSES") || status.contains("BERHASIL")) {
              statusColor = WarnaDesaPay.success;
            } else if (status.contains("GAGAL")) {
              statusColor = WarnaDesaPay.danger;
            } else {
              statusColor = WarnaDesaPay.warning;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WarnaDesaPay.lightCard, 
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                      ),
                      Text(
                        "Rp ${_formatCurrency(log["hargaJual"] ?? log["price"] ?? 0)}", 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: WarnaDesaPay.textMain)
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: WarnaDesaPay.lightField),
                  ),
                  _buildDetailRow("Produk", log["product_name"] ?? log["buyer_sku_code"] ?? "-"),
                  _buildDetailRow("Tujuan", log["customer_no"] ?? log["tujuan"] ?? "-"),
                  _buildDetailRow("SN/Reff", log["sn"] ?? log["message"] ?? "-"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // TAB 3: HELPDESK TIKET KELUHAN
  // ==========================================
  Widget _buildPanelTiketCS() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("keluhan_pelanggan").orderBy("waktuMasuk", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: WarnaDesaPay.primary));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_chat_read_rounded, size: 48, color: WarnaDesaPay.textSub.withOpacity(0.3)),
                const SizedBox(height: 10),
                const Text("Inbox Bersih! Tidak ada keluhan pelanggan.", style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 13)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final tiket = docs[index].data() as Map<String, dynamic>;
            bool isResolved = tiket["isResolved"] ?? false;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WarnaDesaPay.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border(left: BorderSide(color: isResolved ? WarnaDesaPay.success : WarnaDesaPay.danger, width: 5)),
                boxShadow: [BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tiket["namaUser"] ?? "Anonymous", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WarnaDesaPay.textMain)),
                        const SizedBox(height: 2),
                        Text("Kontak: ${tiket["phoneUser"] ?? "-"}", style: const TextStyle(color: WarnaDesaPay.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: WarnaDesaPay.lightField,
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            "\"${tiket["pesan"] ?? "-"}\"",
                            style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 12, height: 1.4, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Text(isResolved ? "SELESAI" : "OPEN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isResolved ? WarnaDesaPay.success : WarnaDesaPay.danger)),
                      Switch.adaptive(
                        value: isResolved,
                        activeColor: WarnaDesaPay.success,
                        onChanged: (val) {
                          _firestore.collection("keluhan_pelanggan").doc(docs[index].id).update({"isResolved": val});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value, 
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: WarnaDesaPay.textMain), 
              textAlign: TextAlign.end, 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            )
          ),
        ],
      ),
    );
  }

  // ✅ PERBAIKAN: Fungsi ini sudah menggunakan InputDecoration langsung (Bukan copyWith)
  Widget _buildModernInput({required BuildContext context, required TextEditingController controller, required String label, required String hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: WarnaDesaPay.textSub, letterSpacing: 0.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: WarnaDesaPay.textMain),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
            filled: true,
            fillColor: WarnaDesaPay.lightBg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: WarnaDesaPay.lightField, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: WarnaDesaPay.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
