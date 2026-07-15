import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/warna.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium untuk Tombol Panel Admin
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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late TabController _adminTabController;
  
  final promoController = TextEditingController();
  final bannerController = TextEditingController();
  final namaMenuController = TextEditingController();
  final ikonController = TextEditingController();
  
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _adminTabController = TabController(length: 3, vsync: this);
    _loadInitialConfiguration();
  }

  Future<void> _loadInitialConfiguration() async {
    try {
      DocumentSnapshot doc = await _firestore.collection("pengaturan").doc("aplikasi").get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        bannerController.text = data["teksBanner"] ?? "";
        promoController.text = data["teksPromo"] ?? "";
      }
    } catch (_) {}
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

  Future<void> simpanPerubahan() async {
    if (promoController.text.trim().isEmpty || bannerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Semua kolom pengaturan wajib diisi"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await _firestore.collection("pengaturan").doc("aplikasi").set({
        "teksPromo": promoController.text.trim(),
        "teksBanner": bannerController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Konfigurasi Konten DesaPay Berhasil Diperbarui!"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan data: $e"), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> tambahMenuLayanan() async {
    if (namaMenuController.text.trim().isEmpty || ikonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama menu dan kode ikon wajib diisi"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    try {
      String idMenu = namaMenuController.text.trim().toLowerCase().replaceAll(' ', '_');
      await _firestore.collection("menu_layanan").doc(idMenu).set({
        "id": idMenu,
        "nama": namaMenuController.text.trim(),
        "ikon": ikonController.text.trim(),
        "isAktif": true,
        "urutan": 1,
      });

      if (!mounted) return;
      namaMenuController.clear();
      ikonController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Menu Layanan Live Terpasang Sukses!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambah menu: $e"), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void tampilkanBottomSheetTambahMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text("Tambah Grid Menu Baru (Live)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildModernInput(controller: namaMenuController, label: "Nama Modul Menu", hint: "Contoh: Voucher Game, Aktivasi Kartu"),
              const SizedBox(height: 16),
              _buildModernInput(controller: ikonController, label: "Kode Aksen Ikon Material", hint: "Contoh: games_rounded, card_membership"),
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
                  onPressed: tambahMenuLayanan,
                  child: const Text("Publikasikan Menu Secara Live", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(dynamic value) {
    int parsed = int.tryParse(value.toString()) ?? 0;
    return parsed.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B), // Dark Slate Grey Mewah
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("HQ Command Center", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
            Text("DesaPay Administrator Mode", style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w500)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF0F172A),
            child: TabBar(
              controller: _adminTabController,
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.grey.shade400,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.tune_rounded, size: 18), text: "KONTEN UI"),
                Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: "LIVE MUTASI"),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.amp_stories_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Text("Kampanye & Informasi Saldo Banner", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 18),
                _buildModernInput(controller: bannerController, label: "Teks Banner Informasi Saldo", hint: "Tulis pengumuman maintenance/promo saldo...", maxLines: 2),
                const SizedBox(height: 16),
                _buildModernInput(controller: promoController, label: "Teks Ticker Promo Berjalan", hint: "Tulis promo berjalan di dashboard utama...", maxLines: 2),
                const SizedBox(height: 20),
                CustomBounce(
                  onTap: simpanPerubahan,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.amber.shade700, Colors.orange.shade600]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: loading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("UPDATE REALTIME PLATFORM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Manajemen Grid Akses Menu", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.blue),
                label: const Text("Tambah Menu", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: tampilkanBottomSheetTambahMenu,
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection("menu_layanan").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("Belum ada menu yang dibuat custom.", style: TextStyle(color: Colors.grey, fontSize: 12)));
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final item = docs[index].data() as Map<String, dynamic>;
                  bool isAktif = item["isAktif"] ?? false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(item["nama"] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text("ID Modul: ${item["id"]}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      trailing: Switch.adaptive(
                        value: isAktif,
                        activeColor: Colors.green,
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
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: LIVE MUTASI TRANSAKSI DIGIFLAZZ METER
  // ==========================================
  Widget _buildPanelLiveMutasi() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("transaksi").orderBy("waktu", descending: true).limit(40).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text("Belum ada logs transaksi terekam di gateway.", style: TextStyle(color: Colors.grey, fontSize: 13)),
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
            Color statusColor = status == "SUKSES" ? Colors.green : status == "GAGAL" ? Colors.red : Colors.orange;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                      Text("Nominal Jual: Rp ${_formatCurrency(log["hargaJual"] ?? log["price"] ?? 0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow("Produk PPOB", log["product_name"] ?? log["buyer_sku_code"] ?? "-"),
                  _buildDetailRow("ID/No Tujuan", log["customer_no"] ?? log["tujuan"] ?? "-"),
                  _buildDetailRow("Serial Number", log["sn"] ?? log["message"] ?? "-"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // TAB 3: USER KELUHAN & HELPDESK STREAM
  // ==========================================
  Widget _buildPanelTiketCS() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("keluhan_pelanggan").orderBy("waktuMasuk", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_chat_read_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text("Bersih! Tidak ada antrean tiket keluhan masuk.", style: TextStyle(color: Colors.grey, fontSize: 13)),
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
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border(left: BorderSide(color: isResolved ? Colors.grey : Colors.red, width: 4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tiket["namaUser"] ?? "Anonymous Member", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text("No. Kontak: ${tiket["phoneUser"] ?? "-"}", style: TextStyle(color: WarnaDesaPay.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          "Pesan Kendala:\n\"${tiket["pesan"] ?? "-"}\"",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: isResolved,
                    activeColor: Colors.grey,
                    onChanged: (val) {
                      _firestore.collection("keluhan_pelanggan").doc(docs[index].id).update({"isResolved": val});
                    },
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildModernInput({required TextEditingController controller, required String label, required String hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.normal),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
