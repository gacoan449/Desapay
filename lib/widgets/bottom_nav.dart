import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import Konfigurasi
import '../config/warna.dart';

// PERBAIKAN: Jalur impor diperbaiki mengarah ke folder screens
import '../screens/home/home_screen.dart';
import '../screens/riwayat/riwayat_screen.dart';
import '../screens/pindai/pindai_qris_screen.dart';
import '../screens/ewallet/ewallet_screen.dart';
import '../screens/profil/profil_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  // IndexedStack menjaga state halaman tetap terjaga saat user berpindah tab
  final List<Widget> _pages = const [
    HomeScreen(),
    RiwayatScreen(),
    SizedBox.shrink(), // Index 2 (QRIS) ditangani oleh Navigator.push, bukan tab statis
    EwalletScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Menyelaraskan warna status bar HP dengan aplikasi
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // ==========================================
      // LUXURY 5-ITEM BOTTOM NAVIGATION BAR
      // ==========================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: WarnaDesaPay.shadow.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                
                selectedItemColor: WarnaDesaPay.primary,
                unselectedItemColor: WarnaDesaPay.textSub,
                
                selectedFontSize: 11,
                unselectedFontSize: 11,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),

                onTap: (index) {
                  if (index == 2) {
                    // Jika tombol Pay (Tengah) ditekan, buka layar QRIS di atasnya
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PindaiQrisScreen()));
                  } else {
                    setState(() => _currentIndex = index);
                  }
                },

                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.home_rounded, size: 26),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.home_filled, size: 26),
                    ),
                    label: "Beranda",
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.receipt_long_outlined, size: 26),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.receipt_long_rounded, size: 26),
                    ),
                    label: "Riwayat",
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [WarnaDesaPay.primary, WarnaDesaPay.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: WarnaDesaPay.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                        ]
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
                    ), 
                    label: "Pay"
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.account_balance_wallet_rounded, size: 26),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.account_balance_wallet_rounded, size: 26), // Memperbaiki icon style dompet
                    ),
                    label: "Dompet",
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.person_outline_rounded, size: 26),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.person_rounded, size: 26),
                    ),
                    label: "Profil",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
