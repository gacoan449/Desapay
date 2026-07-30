import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import Konfigurasi & Widget Modular Utama
import '../../config/warna.dart';
import '../../widgets/menu_item.dart'; 

/// Halaman Command Center / Panel Admin DesaPay (100% REAL DATA)
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
  // TAB 1: KONTEN UI
  // ==========================================
  Widget _buildPanelKontenUI() {
    return const Center(child: Text("Bagian Konten UI (Kode Anda Tetap Sama)"));
    // Gunakan kembali kode _buildPanelKontenUI() Anda di sini. 
    // Saya persingkat agar fokus pada perbaikan Pengguna & Tiket CS.
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
            
            // Variabel Baru untuk KYC & Premium
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
                        backgroundImage: user["fotoProfil"] != null ? NetworkImage(user["fotoProfil"]) : null,
                        child: user["fotoProfil"] == null ? const Icon(Icons.person, color: WarnaDesaPay.primary) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user["nama"] ?? "User Tanpa Nama", style: const TextStyle(fontWeight: FontWeight.bold, color: WarnaDesaPay.textMain)),
                            Text(user["email"] ?? "-", style: const TextStyle(fontSize: 11, color: WarnaDesaPay.textSub)),
                            const SizedBox(height: 4),
                            // Badge Tipe Akun
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tipeAkun == "Premium" ? WarnaDesaPay.warning : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4)
                              ),
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
                      
                      // Tombol Review KYC Muncul Jika Status "Pending"
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

  // DIALOG REVIEW KYC UNTUK UPGRADE PREMIUM
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
                child: fotoKtp != null ? Image.network(fotoKtp, fit: BoxFit.cover) : const Center(child: Text("Tidak ada gambar")),
              ),
              const SizedBox(height: 16),
              const Text("Foto Selfie dengan KTP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                height: 150, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: fotoSelfie != null ? Image.network(fotoSelfie, fit: BoxFit.cover) : const Center(child: Text("Tidak ada gambar")),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Tolak KYC
              _firestore.collection("users").doc(userId).update({"kycStatus": "Ditolak"});
              Navigator.pop(context);
              _tampilkanSnackBar("Dokumen ditolak.", isError: true);
            }, 
            child: const Text("Tolak", style: TextStyle(color: WarnaDesaPay.danger))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.success),
            onPressed: () {
              // Setujui KYC & Upgrade ke Premium
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
  // TAB 3: KEUANGAN & TAB 4: SISTEM (Abaikan Sementara, Biarkan Seperti Kode Asli Anda)
  // ==========================================
  Widget _buildPanelKeuangan() => const Center(child: Text("Kode Keuangan Tetap Sama"));
  Widget _buildPanelSistem() => const Center(child: Text("Kode Sistem Tetap Sama"));

  // ==========================================
  // TAB 5: TIKET CS & SISTEM BALASAN (REAL DATA)
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
                  
                  // Pesan dari Pengguna
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: WarnaDesaPay.lightField, borderRadius: BorderRadius.circular(10)),
                    child: Text("\"${tiket["pesan"] ?? "-"}\"", style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                  
                  const SizedBox(height: 10),

                  // Area Balasan Admin
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
                  
                  // Tombol untuk Membalas
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

  // DIALOG BALAS TIKET CS
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
                "status": "Selesai", // Otomatis ubah status jadi Selesai
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
}
