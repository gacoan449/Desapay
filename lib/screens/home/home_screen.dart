// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart'; // Wajib untuk efek mewah

// --- INTEGRASI LAYER INDUSTRIAL GRADE ---
import 'package:desapay/presentation/widgets/home/premium_app_bar.dart';
import 'package:desapay/presentation/widgets/home/saldo_section.dart';
import 'package:desapay/presentation/widgets/home/menu_grid_section.dart';
import 'package:desapay/presentation/widgets/home/promo_banner_carousel.dart';
import 'package:desapay/presentation/widgets/home/transaction_feed_ticker.dart';
import 'package:desapay/presentation/widgets/home/qris_floating_action.dart';
import 'package:desapay/presentation/widgets/home/fraud_shield_banner.dart';
import 'package:desapay/presentation/widgets/home/deals_engine_carousel.dart';
import 'package:desapay/presentation/widgets/home/user_status_monitor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeDashboardMonitoring();
  }

  Future<void> _initializeDashboardMonitoring() async {
    // Logic: Cek Security, Root Detection, & Fetch Data Awal
    debugPrint("Desapay System: Monitoring initialized...");
  }

  // Fitur Wajib E-Wallet: Sinkronisasi Ulang Data
  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact(); // Getaran halus saat di-refresh
    // TODO: Panggil State Management (Provider/Bloc/GetX) untuk fetch ulang saldo & feed
    await Future.delayed(const Duration(seconds: 2)); 
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA), // Warna dasar yang lebih clean & mahal
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF0086FF),
        backgroundColor: Colors.white,
        strokeWidth: 3,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ), // Memastikan selalu bisa ditarik meskipun konten sedikit
          slivers: [
            // 1. DYNAMIC PREMIUM HEADER
            SliverAppBar(
              expandedHeight: 110,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF0054A6),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0054A6), Color(0xFF0086FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Memasukkan PremiumAppBar buatan Anda ke dalam struktur Sliver
              title: const PremiumAppBar().animate().fadeIn(duration: 500.ms),
              titleSpacing: 0,
            ),

            // 2. MAIN DASHBOARD CONTENT
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const UserStatusMonitor(),
                  const SizedBox(height: 16),
                  
                  // Saldo Section dengan animasi geser masuk
                  const SaldoSection()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                      
                  const SizedBox(height: 24),
                  const PromoBannerCarousel(),
                  
                  const SizedBox(height: 24),
                  
                  // Grid PPOB dengan animasi delay
                  const MenuGridSection()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut),
                      
                  const SizedBox(height: 20),
                  const TransactionFeedTicker(),
                  const SizedBox(height: 16),
                  
                  // Fitur Keamanan Industri
                  const FraudShieldBanner()
                      .animate()
                      .fadeIn(delay: 400.ms),
                      
                  const SizedBox(height: 24),
                  const DealsEngineCarousel(),
                  
                  const SizedBox(height: 120), // Spacer agar list tidak tertutup FAB
                ]),
              ),
            ),
          ],
        ),
      ),
      
      // 3. FLOATING ACTION BUTTON (QRIS)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const QrisFloatingAction()
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: 0, end: -5, duration: 1500.ms, curve: Curves.easeInOut), 
          // Efek mengambang (levitate) mewah pada QRIS
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
