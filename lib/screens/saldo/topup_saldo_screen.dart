import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import Konfigurasi, Layanan, dan Widget Modular
import '../../config/warna.dart';
import '../../services/tripay_service.dart';
import '../../widgets/menu_item.dart'; // Untuk CustomBounce
import '../pembayaran/metode_pembayaran_screen.dart'; 
import '../saldo/invoice_screen.dart';

class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {
  final TextEditingController _nominalController = TextEditingController();
  final FocusNode _nominalFocus = FocusNode();
  
  bool _isLoading = false;
  int _currentNominal = 0;

  // Pilihan cepat (Quick Select) bergaya e-wallet modern
  final List<int> _pilihanNominal = [20000, 50000, 100000, 200000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    // Memantau perubahan teks untuk mencocokkan dengan pilihan cepat secara real-time
    _nominalController.addListener(() {
      final String rawText = _nominalController.text.replaceAll('.', '');
      final int parsed = int.tryParse(rawText) ?? 0;
      if (_currentNominal != parsed) {
        setState(() => _currentNominal = parsed);
      }
    });
    
    // Memberikan fokus otomatis ke input field saat layar dibuka
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) FocusScope.of(context).requestFocus(_nominalFocus);
    });
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _nominalFocus.dispose();
    super.dispose();
  }

  /// Memilih nominal dari Grid Quick Select
  void _pilihNominalCepat(int nominal) {
    _nominalFocus.unfocus(); // Tutup keyboard agar layar lega
    final String formatted = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(nominal);
    _nominalController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// 1. Navigasi ke pemilihan metode, 2. Jika terpilih, baru eksekusi tiket
  Future<void> _lanjutkanKePembayaran() async {
    if (_currentNominal < 10000) {
      _tampilkanNotifikasi("Minimal pengisian saldo adalah Rp 10.000", isError: true);
      return;
    }

    _nominalFocus.unfocus();

    // Arahkan ke pemilihan metode pembayaran
    final String? channelCode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MetodePembayaranScreen(nominal: _currentNominal.toString()),
      ),
    );

    // Jika user memilih metode (tidak batal), langsung eksekusi tiket
    if (channelCode != null) {
      _eksekusiMintaTiketTriPay(_currentNominal, channelCode);
    }
  }

  /// Eksekusi API TriPay dengan metode yang dipilih
  void _eksekusiMintaTiketTriPay(int nominal, String methodCode) async {
    setState(() => _isLoading = true);

    final User? currentUser = FirebaseAuth.instance.currentUser;
    String namaUser = "Member DesaPay";
    String emailUser = currentUser?.email ?? "member@desapay.id";
    String teleponUser = "080000000000";

    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          namaUser = data['nama'] ?? namaUser;
          teleponUser = data['nomorHp'] ?? data['telepon'] ?? teleponUser;
        }
      } catch (e) {
        debugPrint("Bypass: Gagal mengambil data user, menggunakan data default.");
      }
    }

    // Mengambil response Object (Type-Safe) dari domain layer TriPay
    final responseData = await TriPayService().buatTagihanClosedPayment(
      method: methodCode,
      amount: nominal,
      namaPelanggan: namaUser,
      emailPelanggan: emailUser,
      nomorHpPelanggan: teleponUser,
      namaProduk: 'Top Up Saldo DesaPay',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // LOGIKA BARU: Mengecek parameter 'isSukses' dari object TriPayInvoiceResult
    if (responseData.isSukses) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InvoiceScreen(tripayData: responseData)),
      );
    } else {
      _tampilkanNotifikasi(responseData.pesan, isError: true);
    }
  }

  String _formatAngka(int angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(angka);
  }

  void _tampilkanNotifikasi(String pesan, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isError ? WarnaDesaPay.danger : WarnaDesaPay.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Isi Saldo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ==========================================================
          // 1. LAYER KONTEN UTAMA (SCROLLABLE)
          // ==========================================================
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 120), // Bottom padding untuk area floating bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----------------------------------------------------
                // KARTU INPUT NOMINAL BESAR (GAYA E-WALLET PREMIUM)
                // ----------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mau isi saldo berapa?", 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WarnaDesaPay.textSub)
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text("Rp", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: WarnaDesaPay.textMain)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _nominalController,
                              focusNode: _nominalFocus,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _CurrencyInputFormatter(), // Custom formatter agar titik ribuan muncul otomatis
                              ],
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: WarnaDesaPay.textMain, letterSpacing: 1.0),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "0",
                                hintStyle: TextStyle(color: Colors.grey),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32, thickness: 1.5, color: WarnaDesaPay.lightField),
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                          SizedBox(width: 8),
                          Text("Minimal pengisian Rp 10.000", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                        ],
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // ----------------------------------------------------
                // PILIHAN CEPAT (GRID CHIPS)
                // ----------------------------------------------------
                const Text("Pilihan Cepat", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: WarnaDesaPay.textMain)),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2, // Proporsi lebar:tinggi kartu
                  ),
                  itemCount: _pilihanNominal.length,
                  itemBuilder: (context, index) {
                    final int nominal = _pilihanNominal[index];
                    final bool isSelected = _currentNominal == nominal;

                    return CustomBounce(
                      onTap: () => _pilihNominalCepat(nominal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? WarnaDesaPay.primary.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? WarnaDesaPay.primary : WarnaDesaPay.lightField,
                            width: isSelected ? 2 : 1.5,
                          ),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                          ]
                        ),
                        child: Text(
                          "Rp ${_formatAngka(nominal)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w800, 
                            fontSize: 15, 
                            color: isSelected ? WarnaDesaPay.primary : WarnaDesaPay.textMain
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ==========================================================
          // 2. LAYER BOTTOM ACTION BAR (FLOATING BUTTON)
          // ==========================================================
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), // Padding bawah ekstra untuk area gesture OS
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))
                ]
              ),
              child: CustomBounce(
                onTap: _isLoading ? () {} : _lanjutkanKePembayaran,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _currentNominal < 10000 
                        ? Colors.grey.shade300 
                        : WarnaDesaPay.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _currentNominal < 10000 ? [] : [
                      BoxShadow(color: WarnaDesaPay.primary.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          "PILIH METODE PEMBAYARAN", 
                          style: TextStyle(
                            color: _currentNominal < 10000 ? Colors.grey.shade500 : Colors.white, 
                            fontWeight: FontWeight.w800, 
                            fontSize: 14, 
                            letterSpacing: 0.5
                          )
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper Class: Memformat input teks menjadi nominal Rupiah secara otomatis saat diketik
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int selectionIndexFromTheRight = newValue.text.length - newValue.selection.end;
    final String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    final int value = int.parse(cleanText);
    final String newText = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length - selectionIndexFromTheRight,
      ),
    );
  }
}
