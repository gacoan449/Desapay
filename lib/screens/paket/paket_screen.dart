import 'package:flutter/material.dart';

class PaketScreen extends StatefulWidget {
  const PaketScreen({super.key});

  @override
  State<PaketScreen> createState() => _PaketScreenState();
}

class _PaketScreenState extends State<PaketScreen> {
  final TextEditingController _nomorController = TextEditingController();
  String _operatorTerdeteksi = "-";

  // DATABASE SIMULASI PRODUK DIGIFLAZZ (Mewakili Semua Operator)
  final List<Map<String, dynamic>> _produkDigiflazzRaw = [
    // TELKOMSEL
    {"kode": "T1", "nama": "Telkomsel Data Flash 1GB", "harga_modal": 12000, "desc": "Masa aktif 30 hari. Full 24 Jam di semua jaringan."},
    {"kode": "T2", "nama": "Telkomsel Combo Sakti 15GB", "harga_modal": 72000, "desc": "Kuota Utama 15GB + 300 Menit Nelpon + 400 SMS Telkomsel."},
    // INDOSAT
    {"kode": "I1", "nama": "Indosat Freedom Internet 2GB", "harga_modal": 14500, "desc": "Kuota utama berlaku 30 hari full tanpa pembagian zonasi."},
    {"kode": "I2", "nama": "Indosat Freedom Combo 30GB", "harga_modal": 89000, "desc": "Kuota Utama 30GB + Nelpon Puas Sepuasnya ke sesama Indosat."},
    // XL
    {"kode": "X1", "nama": "XL Xtra Combo Flex 5GB", "harga_modal": 22000, "desc": "Masa aktif 30 hari + Bebas pilih bonus kuota aplikasi di Jakarta."},
    {"kode": "X2", "nama": "XL Xtra HotRod Max 40GB", "harga_modal": 125000, "desc": "Kuota besar 40GB Nasional di jaringan super cepat 4G/5G."},
    // AXIS
    {"kode": "A1", "nama": "Axis Bronet 2GB 24 Jam", "harga_modal": 9500, "desc": "Kuota data internet gratis Axis 2GB berlaku penuh selama 30 hari."},
    {"kode": "A2", "nama": "Axis Owsem 16GB + Games", "harga_modal": 43000, "desc": "Kuota Utama + Kuota Malam + Kuota Unlimited Games sepuasnya."},
    // THREE (3)
    {"kode": "31", "nama": "Tri Happy 3GB Bulanan", "harga_modal": 16000, "desc": "Kuota Happy 3GB full 24 jam gratis tanpa kuota lokal/malam."},
    {"kode": "32", "nama": "Tri AlwaysOn (AON) 50GB", "harga_modal": 98000, "desc": "Masa aktif kuota mengikuti masa aktif kartu SIM Anda (Masa aktif panjang)."},
    // SMARTFREN
    {"kode": "S1", "nama": "Smartfren Unlimited Harian 1GB/Hari", "harga_modal": 25000, "desc": "Masa aktif 28 Hari dengan FUP 1GB per hari kecepatan penuh."},
    {"kode": "S2", "nama": "Smartfren Kuota Nonstop 45GB", "harga_modal": 67000, "desc": "Kuota utama 45GB + akses internet nonstop setelah kuota habis."},
  ];

  List<Map<String, dynamic>> _produkDitampilkan = [];

  // 1. RUMUS LOGIKA AMBIL UNTUNG (MARKUP HARGA)
  int hitungHargaJual(int hargaModal) {
    if (hargaModal < 50000) {
      return hargaModal + 1000; // Nominal dikit, untung Rp1.000
    } else {
      return hargaModal + 2000; // Nominal banyak, untung Rp2.000
    }
  }

  // 2. LOGIKA DETEKSI OTOMATIS MULTI OPERATOR INDONESIA
  void _cekNomor(String nomor) {
    if (nomor.length >= 4) {
      String prefiks = nomor.substring(0, 4);
      String operatorDitemukan = "-";
      
      final Map<String, List<String>> daftarPrefiksOperator = {
        "TELKOMSEL": ['0811', '0812', '0813', '0821', '0822', '0823', '0851', '0852', '0853'],
        "INDOSAT": ['0814', '0815', '0816', '0855', '0856', '0857', '0858'],
        "XL": ['0817', '0818', '0819', '0859', '0877', '0878'],
        "AXIS": ['0831', '0832', '0833', '0838'],
        "THREE": ['0895', '0896', '0897', '0898', '0899'],
        "SMARTFREN": ['0881', '0882', '0883', '0884', '0885', '0886', '0887', '0888', '0889']
      };

      for (var entry in daftarPrefiksOperator.entries) {
        if (entry.value.contains(prefiks)) {
          operatorDitemukan = entry.key;
          break;
        }
      }

      setState(() {
        _operatorTerdeteksi = operatorDitemukan;
        if (operatorDitemukan != "-") {
          _produkDitampilkan = _produkDigiflazzRaw.where((produk) {
            return produk['nama'].toString().toUpperCase().contains(operatorDitemukan);
          }).toList();
        } else {
          _produkDitampilkan = [];
        }
      });
    } else {
      setState(() {
        _operatorTerdeteksi = "-";
        _produkDitampilkan = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF0F172A); 
    const colorAccent = Color(0xFFF59E0B);  
    const colorCard = Color(0xFF1E293B);    
    const colorTextLight = Color(0xFFF8FAFC); 

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text('Isi Paket Data', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: colorPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            decoration: const BoxDecoration(
              color: colorPrimary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nomor Pelanggan",
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nomorController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                  onChanged: _cekNomor,
                  decoration: InputDecoration(
                    hintText: "Contioh: 0812xxxx",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 0),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    prefixIcon: const Icon(Icons.phone_android, color: colorAccent),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 14, color: colorPrimary),
                          const SizedBox(width: 4),
                          Text(
                            _operatorTerdeteksi,
                            style: const TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: colorAccent, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _produkDitampilkan.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.perm_phone_msg_outlined, size: 60, color: colorPrimary.withOpacity(0.15)),
                        const SizedBox(height: 12),
                        Text(
                          "Masukkan nomor HP pelanggan Anda",
                          style: TextStyle(color: colorPrimary.withOpacity(0.4), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Produk akan otomatis muncul sesuai operator",
                          style: TextStyle(color: colorPrimary.withOpacity(0.3), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _produkDitampilkan.length,
                    itemBuilder: (context, index) {
                      final item = _produkDitampilkan[index];
                      int modal = item['harga_modal'];
                      int hargaJual = hitungHargaJual(modal);

                      String hargaFormat = hargaJual.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
                        (Match m) => '${m}.'
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: colorCard, 
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorPrimary.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ExpansionTile(
