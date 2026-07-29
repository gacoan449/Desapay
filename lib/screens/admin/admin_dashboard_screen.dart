import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import Konfigurasi & Widget Modular
import '../../config/warna.dart';
import '../../widgets/menu_item.dart'; 

/// Halaman Command Center / Panel Admin DesaPay (Versi Super Admin)
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _adminTabController;
  
  // Controller untuk Konten UI
  final TextEditingController promoController = TextEditingController();
  final TextEditingController bannerController = TextEditingController();
  final TextEditingController namaMenuController = TextEditingController();
  final TextEditingController ikonController = TextEditingController();
  
  // Controller untuk Keuangan
  final TextEditingController markupController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ✅ PERBAIKAN: Menjadi 5 Tab untuk mengakomodasi semua fitur skala Enterprise
    _adminTabController = TabController(length: 5, vsync: this);
    _loadInitialConfiguration();
  }

  Future<void> _loadInitialConfiguration() async {
    try {
      // Load Promo
      DocumentSnapshot docApp = await _firestore.collection("pengaturan").doc("aplikasi").get();
      if (docApp.exists && mounted) {
        final data = docApp.data() as Map<String, dynamic>;
        setState(() {
          bannerController.text = data["teksBanner"] ?? "";
          promoController.text = data["teksPromo"] ?? "";
        });
      }
      
      // Load Pengaturan Keuangan (Markup)
      DocumentSnapshot docFin = await _firestore.collection("pengaturan").doc("finansial").get();
      if (docFin.exists && mounted) {
        final data = docFin.data() as Map<String, dynamic>;
        setState(() {
          markupController.text = (data["globalMarkup"] ?? 0).toString();
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
    markupController.dispose();
    super.dispose();
  }

  // --- FUNGSI UPDATE FIREBASE ---

  Future<void> _simpanPerubahanPromo() async {
    if (promoController.text.trim().isEmpty || bannerController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _firestore.collection("pengaturan").doc("aplikasi").set({
        "teksPromo": promoController.text.trim(),
        "teksBanner": bannerController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _tampilkanSnackBar("Konfigurasi UI Berhasil Diperbarui!", isError: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _simpanMarkupGlobal() async {
    if (markupController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _firestore.collection("pengaturan").doc("finansial").set({
        "globalMarkup": int.parse(markupController.text.trim()),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _tampilkanSnackBar("Markup Global Harga PPOB Disimpan!", isError: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _tambahMenuLayanan() async {
    if (namaMenuController.text.trim().isEmpty || ikonController.text.trim().isEmpty) return;
    try {
      String idMenu = namaMenuController.text.trim().toLowerCase().replaceAll(' ', '_');
      await _firestore.collection("menu_layanan").doc(idMenu).set({
        "id": idMenu,
        "nama": namaMenuController.text.trim(),
        "ikon": ikonController.text.trim(),
        "isAktif": true,
        "urutan": 99, 
      });
      namaMenuController.clear();
      ikonController.clear();
      Navigator.pop(context); 
      _tampilkanSnackBar("Menu Live Terpasang!", isError: false);
    } catch (e) {
      _tampilkanSnackBar("Gagal: $e", isError: true);
    }
  }

  // --- FUNGSI BANTUAN UI ---

  void _tampilkanSnackBar(String pesan, {required bool isError}) {
    if (!mounted) return;
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
        backgroundColor: WarnaDesaPay.darkCard,
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
              isScrollable: true, // ✅ Agar tidak berdesakan karena tabnya banyak
              indicatorColor: WarnaDesaPay.warning,
              indicatorWeight: 3,
              labelColor: WarnaDesaPay.warning,
              unselectedLabelColor: WarnaDesaPay.textSub,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.tune_rounded, size: 18), text: "KONTEN UI"),
                Tab(icon: Icon(Icons.people_alt_rounded, size: 18), text: "PENGGUNA"),
                Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 18), text: "KEUANGAN"),
                Tab(icon: Icon(Icons.security_rounded, size: 18), text: "SISTEM"),
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
          _buildPanelKontenUI(),     // Tab 1
          _buildPanelPengguna(),     // Tab 2 (Baru)
          _buildPanelKeuangan(),     // Tab 3 (Diperluas)
          _buildPanelSistem(),       // Tab 4 (Baru)
          _buildPanelTiketCS(),      // Tab 5 (Diperbarui)
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: KONTEN UI (Mirip Gambar Anda)
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
            decoration: BoxDecoration(color: WarnaDesaPay.lightCard, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.amp_stories_rounded, color: WarnaDesaPay.warning), SizedBox(width: 8), Text("Kampanye & Teks Berjalan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain))]),
                const SizedBox(height: 20),
                _buildModernInput(context: context, controller: bannerController, label: "Teks Pengumuman Header", hint: "Tulis pengumuman..."),
                const SizedBox(height: 16),
                _buildModernInput(context: context, controller: promoController, label: "Teks Ticker Beranda", hint: "Tulis promo berjalan..."),
                const SizedBox(height: 24),
                CustomBounce(
                  onTap: _simpanPerubahanPromo,
                  child: Container(
                    width: double.infinity, height: 50,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [WarnaDesaPay.warning, Color(0xFFD97706)]), borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("UPDATE REALTIME PLATFORM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text("Manajemen Modul Layanan", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain)),
          const SizedBox(height: 12),
          // Stream builder menu OTA (sama seperti sebelumnya) disingkat untuk keterbacaan
          const Center(child: Text("Sistem Menu OTA Aktif.", style: TextStyle(color: WarnaDesaPay.textSub))),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MANAJEMEN PENGGUNA & SALDO (BARU)
  // ==========================================
  Widget _buildPanelPengguna() {
    return StreamBuilder<QuerySnapshot>(
      // Membaca koleksi users di Firestore
      stream: _firestore.collection("users").orderBy("createdAt", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: WarnaDesaPay.primary));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text("Belum ada pengguna terdaftar."));
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final user = docs[index].data() as Map<String, dynamic>;
            final userId = docs[index].id;
            bool isBlocked = user["isBlocked"] ?? false;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isBlocked ? WarnaDesaPay.danger.withOpacity(0.05) : WarnaDesaPay.lightCard, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isBlocked ? WarnaDesaPay.danger.withOpacity(0.3) : WarnaDesaPay.lightField)
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: WarnaDesaPay.primary.withOpacity(0.1), child: const Icon(Icons.person, color: WarnaDesaPay.primary)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user["nama"] ?? "User Tanpa Nama", style: const TextStyle(fontWeight: FontWeight.bold, color: WarnaDesaPay.textMain)),
                            Text(user["email"] ?? "-", style: const TextStyle(fontSize: 12, color: WarnaDesaPay.textSub)),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: !isBlocked, // Terbalik: Jika on berarti aktif, off berarti blokir
                        activeColor: WarnaDesaPay.success,
                        inactiveThumbColor: WarnaDesaPay.danger,
                        onChanged: (val) {
                          _firestore.collection("users").doc(userId).update({"isBlocked": !val});
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Saldo: Rp ${_formatCurrency(user["saldo"] ?? 0)}", style: const TextStyle(fontWeight: FontWeight.w900, color: WarnaDesaPay.primary)),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: const Text("Edit Saldo"),
                        onPressed: () => _tampilkanDialogEditSaldo(userId, user["saldo"] ?? 0),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _tampilkanDialogEditSaldo(String userId, int saldoSaatIni) {
    TextEditingController saldoController = TextEditingController(text: saldoSaatIni.toString());
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text("Adjustment Saldo Manual"),
        content: TextField(
          controller: saldoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Masukkan Nominal Baru"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              _firestore.collection("users").doc(userId).update({"saldo": int.parse(saldoController.text)});
              Navigator.pop(context);
              _tampilkanSnackBar("Saldo berhasil diubah manual", isError: false);
            },
            child: const Text("Simpan"),
          )
        ],
      );
    });
  }

  // ==========================================
  // TAB 3: KONTROL KEUANGAN & MUTASI (DIPERLUAS)
  // ==========================================
  Widget _buildPanelKeuangan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PANEL MARKUP
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: WarnaDesaPay.lightCard, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Setel Markup Profit Global", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                const Text("Sistem akan otomatis menambahkan nominal ini ke harga dasar dari Digiflazz.", style: TextStyle(fontSize: 12, color: WarnaDesaPay.textSub)),
                const SizedBox(height: 16),
                _buildModernInput(context: context, controller: markupController, label: "Markup Keuntungan (Rp)", hint: "Contoh: 150"),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _simpanMarkupGlobal,
                  style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.success, minimumSize: const Size(double.infinity, 45)),
                  child: const Text("SIMPAN PROFIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          // PANEL SALDO API
          Row(
            children: [
              Expanded(child: _buildInfoCard("Saldo Digiflazz", "Rp 1.450.000", Icons.api_rounded, WarnaDesaPay.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildInfoCard("Saldo TriPay", "Rp 320.000", Icons.payment_rounded, Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Live Mutasi Transaksi User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          // (Di sini masukkan StreamBuilder untuk collection "transaksi" seperti kode sebelumnya)
          const Center(child: Text("Data mutasi realtime dimuat di sini.", style: TextStyle(color: WarnaDesaPay.textSub))),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: WarnaDesaPay.textMain)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: SISTEM KEAMANAN & LOG (BARU)
  // ==========================================
  Widget _buildPanelSistem() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("system_logs").orderBy("timestamp", descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        // Jika belum ada data dummy, kita tampilkan template designnya
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text("Log Aktivitas Server & Keamanan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 20),
            _buildLogItem("OTP_SENT", "Kode OTP dikirim ke 085642131263 via WhatsApp. Status: Sukses.", "10 Menit lalu", WarnaDesaPay.success),
            _buildLogItem("API_ERROR", "Digiflazz Timeout: Gagal melakukan pengecekan saldo.", "1 Jam lalu", WarnaDesaPay.danger),
            _buildLogItem("LOGIN_ATTEMPT", "Percobaan login gagal dari IP 114.120.x.x (Email: hacker@test.com).", "3 Jam lalu", WarnaDesaPay.warning),
          ],
        );
      },
    );
  }

  Widget _buildLogItem(String tipe, String pesan, String waktu, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 4)), color: WarnaDesaPay.lightCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tipe, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: color)),
              Text(waktu, style: const TextStyle(fontSize: 10, color: WarnaDesaPay.textSub)),
            ],
          ),
          const SizedBox(height: 6),
          Text(pesan, style: const TextStyle(fontSize: 12, color: WarnaDesaPay.textMain)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 5: TIKET CS (DIPERBARUI DENGAN STATUS 3 TINGKAT)
  // ==========================================
  Widget _buildPanelTiketCS() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("keluhan_pelanggan").orderBy("waktuMasuk", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: WarnaDesaPay.primary));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text("Inbox Bersih!", style: TextStyle(color: WarnaDesaPay.textSub)));
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final tiket = docs[index].data() as Map<String, dynamic>;
            final tiketId = docs[index].id;
            String status = tiket["status"] ?? "Pending"; // Pending, Proses, Selesai
            
            Color statusColor = status == "Selesai" ? WarnaDesaPay.success : (status == "Proses" ? WarnaDesaPay.warning : WarnaDesaPay.danger);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WarnaDesaPay.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: statusColor, width: 5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tiket["namaUser"] ?? "Anonymous", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      // Dropdown Status
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButton<String>(
                          value: status,
                          underline: const SizedBox(),
                          iconSize: 16,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                          items: <String>['Pending', 'Proses', 'Selesai'].map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _firestore.collection("keluhan_pelanggan").doc(tiketId).update({"status": newValue});
                            }
                          },
                        ),
                      )
                    ],
                  ),
                  Text("Kontak: ${tiket["phoneUser"] ?? "-"}", style: const TextStyle(color: WarnaDesaPay.primary, fontSize: 12)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: WarnaDesaPay.lightField, borderRadius: BorderRadius.circular(10)),
                    child: Text("\"${tiket["pesan"] ?? "-"}\"", style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- REUSABLE WIDGETS ---
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
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: WarnaDesaPay.lightField, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: WarnaDesaPay.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
