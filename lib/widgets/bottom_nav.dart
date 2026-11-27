import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/warna.dart';

import '../screens/home/home_screen.dart';
import '../screens/riwayat/riwayat_screen.dart';
import '../screens/ppob/ppob_generic_screen.dart';
import '../screens/profil/profil_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  // =========================================================
  // HALAMAN UTAMA DESAPAY
  // =========================================================

  static const List<Widget> _pages = [
    HomeScreen(),
    RiwayatScreen(),
    PpobGenericScreen(kategori: 'E-Money'),
    ProfilScreen(),
  ];

  // =========================================================
  // PERUBAHAN TAB
  // =========================================================

  void _changeTab(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.selectionClick();

    setState(() {
      _currentIndex = index;
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,

      // =======================================================
      // INDEXED STACK
      //
      // Home, Riwayat, Dompet dan Profil tetap mempertahankan
      // state masing-masing ketika user berpindah tab.
      // =======================================================

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // =======================================================
      // BOTTOM NAVIGATION
      // =======================================================

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: WarnaDesaPay.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              10,
              7,
              10,
              7,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _changeTab,

                // =================================================
                // TAMPILAN
                // =================================================

                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,

                selectedItemColor:
                    WarnaDesaPay.primary,

                unselectedItemColor:
                    WarnaDesaPay.textSub,

                selectedFontSize: 11,
                unselectedFontSize: 10,

                selectedLabelStyle:
                    const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.15,
                ),

                unselectedLabelStyle:
                    const TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),

                showUnselectedLabels: true,

                // =================================================
                // MENU
                // =================================================

                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding:
                          EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.home_outlined,
                        size: 25,
                      ),
                    ),
                    activeIcon: Padding(
                      padding:
                          EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.home_rounded,
                        size: 26,
                      ),
                    ),
                    label: 'Beranda',
                  ),

                  BottomNavigationBarItem(
                    icon: Padding(
                      padding:
                          EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 25,
                      ),
                    ),
                    activeIcon: Padding(
                      padding:
                          EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 26,
                      ),
                    ),
                    label: 'Riwayat',
                  ),

                  BottomNavigationBarItem(
                    icon: Padding(
                      padding:
                          EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 25,
                      ),
                    ),
                    activeIcon: Padding(
                      padding:
                          EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 26,
                      ),
                    ),
                    label: 'Dompet',
                  ),

                  BottomNavigationBarItem(
                    icon: Padding(
                      padding:
                          EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 25,
                      ),
                    ),
                    activeIcon: Padding(
                      padding:
                          EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.person_rounded,
                        size: 26,
                      ),
                    ),
                    label: 'Profil',
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
