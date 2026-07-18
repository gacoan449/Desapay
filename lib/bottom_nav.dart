import 'package:flutter/material.dart';
import '../config/warna.dart';

// Import Layar Utama
import '../screens/home/home_screen.dart';
import '../screens/riwayat/riwayat_screen.dart';
import '../screens/profil/profil_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  // indexedStack menjaga state halaman tetap terjaga saat user berpindah tab
  final List<Widget> _pages = const [
    HomeScreen(),
    RiwayatScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg, // Menggunakan palet standar DesaPay
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      // ==========================================
      // LUXURY FLOATING BOTTOM NAVIGATION BAR
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
                  setState(() {
                    _currentIndex = index;
                  });
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
