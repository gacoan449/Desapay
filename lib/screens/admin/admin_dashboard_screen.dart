import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/warna.dart';
import '../../widgets/menu_item.dart';

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
    _adminTabController = TabController(length: 5, vsync: this);
    _loadInitialConfiguration();
  }

  Future<void> _loadInitialConfiguration() async {
    try {
      DocumentSnapshot docApp = await _firestore.collection("pengaturan").doc("aplikasi").get();
      if (docApp.exists && mounted) {
        final data = docApp.data() as Map<String, dynamic>;
        setState(() {
          bannerController.text = data["teksBanner"] ?? "";
          promoController.text = data["teksPromo"] ?? "";
        });
      }
      
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

  // --- FUNGSI UPDATE FIREBASE KONTEN UI & KEUANGAN ---

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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "-";
    DateTime dt = timestamp.toDate();
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
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
              isScrollable: true, 
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
          _buildPanelKontenUI(),     
          _buildPanelPengguna(),     
          _buildPanelKeuangan(),     
          _buildPanelSistem(),       
          _buildPanelTiketCS(),      
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: KONTEN UI (KEMBALI NORMAL & LENGKAP)
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
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection("menu_layanan").orderBy("urutan").snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: WarnaDesaPay.primary)));
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text("Belum ada menu custom yang dibuat.", style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 12)));
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final item = docs[index].data() as Map<String, dynamic>;
                  bool isAktif = item["isAktif"] ?? false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: WarnaDesaPay.lightCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: WarnaDesaPay.lightField)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: WarnaDesaPay.primary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.grid_view_rounded, color: WarnaDesaPay.primary, size: 20)),
                      title: Text(item["nama"] ?? "-", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: WarnaDesaPay.textMain)),
                      subtitle: Text("ID Modul: ${item["id"]}", style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 11)),
                      trailing: Switch.adaptive(
                        value: isAktif, activeColor: WarnaDesaPay.success,
                        onChanged: (val) => _firestore.collection("menu_layanan").doc(item["id"]).update({"isAktif": val}),
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
  // TAB 2: PENGGUNA & REVIEW KYC PREMIUM
  // ==========================================
  Widget _buildPanelPengguna() {
    return StreamBuilder<QuerySnapshot>(
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
            
            String kycStatus = user["kycStatus"] ?? "Belum";
            String tipeAkun = user["tipeAkun"] ?? "Basic"; 
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isBlocked ? WarnaDesaPay.danger.withOpacity(0.05) : WarnaDesaPay.lightCard, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kycStatus == "Pending" ? WarnaDesaPay.warning : (isBlocked ? WarnaDesaPay.danger.withOpacity(0.3) : WarnaDesaPay.lightField))
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: WarnaDesaPay.primary.withOpacity(0.1), 
                        backgroundImage: (user["fotoProfil"] != null && user["fotoProfil"].toString().isNotEmpty) ? NetworkImage(user["fotoProfil"]) : null,
                        child: (user["fotoProfil"] == null || user["fotoProfil"].toString().isEmpty) ? const Icon(Icons.person, color: WarnaDesaPay.primary) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user["nama"] ?? "User Tanpa Nama", style: const TextStyle(fontWeight: FontWeight.bold, color: WarnaDesaPay.textMain)),
                            Text(user["email"] ?? "-", style: const TextStyle(fontSize: 11, color: WarnaDesaPay.textSub)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: tipeAkun == "Premium" ? WarnaDesaPay.warning : Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                              child: Text(tipeAkun.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: tipeAkun == "Premium" ? Colors.white : Colors.black54)),
                            )
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: !isBlocked,
                        activeColor: WarnaDesaPay.success,
                        onChanged: (val) => _firestore.collection("users").doc(userId).update({"isBlocked": !val}),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Saldo: Rp ${_formatCurrency(user["saldo"] ?? 0)}", style: const TextStyle(fontWeight: FontWeight.w900, color: WarnaDesaPay.primary)),
                      
                      if (kycStatus == "Pending")
                        ElevatedButton.icon(
                          icon: const Icon(Icons.verified_user_rounded, size: 14),
                          label: const Text("Cek KYC", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.warning, foregroundColor: Colors.white, minimumSize: const Size(0, 30)),
                          onPressed: () => _tampilkanDialogReviewKYC(userId, user["nama"], user["fotoKtp"], user["fotoSelfie"]),
                        )
                      else 
                        TextButton.icon(
                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                          label: const Text("Edit Saldo", style: TextStyle(fontSize: 12)),
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

  void _tampilkanDialogReviewKYC(String userId, String? nama, String? fotoKtp, String? fotoSelfie) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text("Review Dokumen KYC\n$nama", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Foto KTP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                height: 150, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: (fotoKtp != null && fotoKtp.isNotEmpty) ? Image.network(fotoKtp, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Text("Gagal muat foto"))) : const Center(child: Text("Tidak ada gambar KTP")),
              ),
              const SizedBox(height: 16),
              const Text("Foto Selfie dengan KTP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                height: 150, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: (fotoSelfie != null && fotoSelfie.isNotEmpty) ? Image.network(fotoSelfie, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Text("Gagal muat foto"))) : const Center(child: Text("Tidak ada gambar Selfie")),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _firestore.collection("users").doc(userId).update({"kycStatus": "Ditolak"});
              Navigator.pop(context);
              _tampilkanSnackBar("Dokumen ditolak.", isError: true);
            }, 
            child: const Text("Tolak", style: TextStyle(color: WarnaDesaPay.danger))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.success),
            onPressed: () {
              _firestore.collection("users").doc(userId).update({
                "kycStatus": "Terverifikasi",
                "tipeAkun": "Premium"
              });
              Navigator.pop(context);
              _tampilkanSnackBar("Akun berhasil diupgrade ke PREMIUM!", isError: false);
            },
            child: const Text("Setujui & Upgrade", style: TextStyle(color: Colors.white)),
          )
        ],
      );
    });
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
  // TAB 3: KEUANGAN (KEMBALI NORMAL LENGKAP)
  // ==========================================
  Widget _buildPanelKeuangan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: WarnaDesaPay.lightCard, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Setel Markup Profit Global", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                const Text("Sistem otomatis menambahkan nominal ini ke harga dasar dari API.", style: TextStyle(fontSize: 12, color: WarnaDesaPay.textSub)),
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
          
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection("pengaturan").doc("finansial").snapshots(),
            builder: (context, snapshot) {
              int saldoDigi = 0;
              int saldoTri = 0;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                saldoDigi = data["saldoDigiflazz"] ?? 0;
                saldoTri = data["saldoTriPay"] ?? 0;
              }
              return Row(
                children: [
                  Expanded(child: _buildInfoCard("Saldo Digiflazz", "Rp ${_formatCurrency(saldoDigi)}", Icons.api_rounded, WarnaDesaPay.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoCard("Saldo TriPay", "Rp ${_formatCurrency(saldoTri)}", Icons.payment_rounded, Colors.orange)),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          const Text("Live Mutasi Transaksi User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection("transaksi").orderBy("waktu", descending: true).limit(50).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: WarnaDesaPay.primary)));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Icon(Icons.analytics_outlined, size: 48, color: WarnaDesaPay.textSub.withOpacity(0.3)),
                      const SizedBox(height: 10),
                      const Text("Belum ada log transaksi terekam di database.", style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 13)),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                    decoration: BoxDecoration(color: WarnaDesaPay.lightCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: WarnaDesaPay.lightField)),
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
                            Text("Rp ${_formatCurrency(log["hargaJual"] ?? log["price"] ?? 0)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: WarnaDesaPay.textMain)),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: WarnaDesaPay.lightField)),
                        _buildDetailRow("Produk", log["product_name"] ?? log["buyer_sku_code"] ?? "-"),
                        _buildDetailRow("Tujuan", log["customer_no"] ?? log["tujuan"] ?? "-"),
                        _buildDetailRow("SN/Reff", log["sn"] ?? log["message"] ?? "-"),
                        _buildDetailRow("Waktu", _formatDate(log["waktu"] as Timestamp?)),
                      ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: WarnaDesaPay.textMain), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: SISTEM KEAMANAN & LOG (KEMBALI NORMAL LENGKAP)
  // ==========================================
  Widget _buildPanelSistem() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("system_logs").orderBy("timestamp", descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: WarnaDesaPay.primary));
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_rounded, size: 60, color: WarnaDesaPay.success.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text("Sistem Berjalan Aman", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: WarnaDesaPay.textMain)),
                const SizedBox(height: 8),
                const Text("Belum ada log error atau aktivitas mencurigakan yang terekam.", textAlign: TextAlign.center, style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 12)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final log = docs[index].data() as Map<String, dynamic>;
            String tipe = log["tipe"] ?? "INFO";
            String pesan = log["pesan"] ?? "-";
            String waktu = _formatDate(log["timestamp"] as Timestamp?);
            
            Color color = WarnaDesaPay.success;
            if (tipe.toUpperCase() == "ERROR" || tipe.toUpperCase() == "CRITICAL") color = WarnaDesaPay.danger;
            if (tipe.toUpperCase() == "WARNING" || tipe.toUpperCase() == "LOGIN_ATTEMPT") color = WarnaDesaPay.warning;

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
          },
        );
      },
    );
  }

  // ==========================================
  // TAB 5: TIKET CS (DENGAN FITUR BALAS)
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
            String status = tiket["status"] ?? "Pending"; 
            String balasan = tiket["balasanAdmin"] ?? ""; 
            
            Color statusColor = status == "Selesai" ? WarnaDesaPay.success : (status == "Proses" ? WarnaDesaPay.warning : WarnaDesaPay.danger);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: WarnaDesaPay.lightCard, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: statusColor, width: 5))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tiket["namaUser"] ?? "Anonymous", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButton<String>(
                          value: status,
                          underline: const SizedBox(),
                          iconSize: 16,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                          items: <String>['Pending', 'Proses', 'Selesai'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) _firestore.collection("keluhan_pelanggan").doc(tiketId).update({"status": newValue});
                          },
                        ),
                      )
                    ],
                  ),
                  Text("Kontak: ${tiket["phoneUser"] ?? "-"}", style: const TextStyle(color: WarnaDesaPay.primary, fontSize: 12)),
                  const SizedBox(height: 10),
                  
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: WarnaDesaPay.lightField, borderRadius: BorderRadius.circular(10)),
                    child: Text("\"${tiket["pesan"] ?? "-"}\"", style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                  
                  const SizedBox(height: 10),

                  if (balasan.isNotEmpty)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: WarnaDesaPay.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: WarnaDesaPay.success.withOpacity(0.3))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Balasan Admin:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: WarnaDesaPay.success)),
                          const SizedBox(height: 4),
                          Text(balasan, style: const TextStyle(fontSize: 12, color: WarnaDesaPay.textMain)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.reply_rounded, size: 16),
                      label: Text(balasan.isEmpty ? "Balas Pesan" : "Edit Balasan", style: const TextStyle(fontSize: 12)),
                      onPressed: () => _tampilkanDialogBalasCS(tiketId, balasan),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _tampilkanDialogBalasCS(String tiketId, String balasanLama) {
    TextEditingController balasController = TextEditingController(text: balasanLama);
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text("Balas Tiket Pengguna", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: balasController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Ketikkan balasan untuk pengguna...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.primary),
            onPressed: () {
              if (balasController.text.trim().isEmpty) return;
              _firestore.collection("keluhan_pelanggan").doc(tiketId).update({
                "balasanAdmin": balasController.text.trim(),
                "status": "Selesai",
              });
              Navigator.pop(context);
              _tampilkanSnackBar("Balasan berhasil dikirim", isError: false);
            },
            child: const Text("Kirim Balasan", style: TextStyle(color: Colors.white)),
          )
        ],
      );
    });
  }

  // --- REUSABLE WIDGETS KONTEN UI ---
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
