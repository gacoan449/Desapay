import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/warna.dart';
import '../../services/saldo_service.dart';

// ============================================================
// SCREEN MODULER
// ============================================================
import '../pulsa/pulsa_screen.dart' hide CustomBounce;
import '../pln/pln_screen.dart' hide CustomBounce;
import '../saldo/topup_saldo_screen.dart' hide CustomBounce;
import '../notifikasi/notifikasi_screen.dart' hide CustomBounce;
import '../ppob/ppob_generic_screen.dart' hide CustomBounce;
import '../ppob/semua_layanan_screen.dart' hide CustomBounce;

// ============================================================
// WIDGET
// ============================================================
import '../../widgets/menu_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ISaldoService _saldoService = SaldoService();

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  bool _isSaldoHidden = false;

  late PageController _pageController;

  int _currentBannerIndex = 0;

  Timer? _bannerTimer;

  // ============================================================
  // USER LOGIN TERKINI
  // ============================================================
  //
  // Tidak disimpan sebagai final agar selalu mengambil sesi
  // Firebase Authentication terbaru.
  //
  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  // ============================================================
  // BANNER UTAMA
  // ============================================================
  final List<_BannerData> _promoBanners = const [
    _BannerData(
      image:
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=1200&q=85',
      badge: 'DESAPAY',
      title: 'Semua kebutuhan digital',
      subtitle:
          'Praktis, cepat, dan langsung dari aplikasi.',
    ),
    _BannerData(
      image:
          'https://images.unsplash.com/photo-1556740749-887f6717d7e4?w=1200&q=85',
      badge: 'TRANSAKSI CEPAT',
      title: 'Pulsa & paket data',
      subtitle:
          'Pilih layanan favoritmu tanpa ribet.',
    ),
    _BannerData(
      image:
          'https://images.unsplash.com/photo-1556740738-b6a63e27c4df?w=1200&q=85',
      badge: 'HEMAT',
      title: 'Bayar tagihan lebih mudah',
      subtitle:
          'PLN, internet, BPJS, PDAM dan lainnya.',
    ),
  ];

  // ============================================================
  // INIT
  // ============================================================
  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.94,
    );

    _startBannerAnimation();
  }

  void _startBannerAnimation() {
    _bannerTimer = Timer.periodic(
      const Duration(seconds: 4),
      (timer) {
        if (!mounted) return;
        if (!_pageController.hasClients) return;
        if (_promoBanners.isEmpty) return;

        if (_currentBannerIndex <
            _promoBanners.length - 1) {
          _currentBannerIndex++;
        } else {
          _currentBannerIndex = 0;
        }

        _pageController.animateToPage(
          _currentBannerIndex,
          duration:
              const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================
  String _formatRupiah(int number) {
    final String value =
        number.abs().toString();

    final String formatted =
        value.replaceAllMapped(
      RegExp(
        r'(\d{1,3})(?=(\d{3})+(?!\d))',
      ),
      (Match m) => '${m[1]}.',
    );

    if (number < 0) {
      return '-$formatted';
    }

    return formatted;
  }

  // ============================================================
  // WHATSAPP CS
  // ============================================================
  Future<void> _launchWA() async {
    const String phone =
        '6285642131263';

    const String message =
        'Halo CS DesaPay, saya butuh bantuan terkait transaksi akun saya.';

    final Uri waUrl = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    try {
      final bool canLaunch =
          await canLaunchUrl(waUrl);

      if (!canLaunch) {
        debugPrint(
          'WhatsApp URL tidak dapat dibuka.',
        );
        return;
      }

      await launchUrl(
        waUrl,
        mode:
            LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint(
        'Error membuka WhatsApp: $e',
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================
  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // ROUTING PPOB
  // ============================================================
  //
  // Home hanya mengirim KEY kategori ke screen layanan.
  // Label UI tidak digunakan sebagai security boundary.
  //
  // ============================================================

  void _bukaLayananGenerik({
    required String firestoreKey,
    required String displayName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PpobGenericScreen(
          kategori: firestoreKey,
        ),
      ),
    );
  }

  // ============================================================
  // QUERY PRODUK FIRESTORE
  // ============================================================
  //
  // Collection resmi aplikasi:
  // products
  //
  // Field status:
  // active
  //
  // isTest juga dipastikan false agar produk test tidak tampil.
  //
  Future<int> _jumlahProdukAktif(
    String category,
  ) async {
    try {
      final QuerySnapshot snapshot =
          await _db
              .collection('products')
              .where(
                'category',
                isEqualTo: category,
              )
              .where(
                'active',
                isEqualTo: true,
              )
              .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint(
        'Gagal membaca jumlah produk: $e',
      );

      return 0;
    }
  }

  // ============================================================
  // MENU CARD DENGAN COUNTER FIRESTORE
  // ============================================================
  Widget _buildSmartMenu({
    required IconData icon,
    required String title,
    required String firestoreKey,
    required Color badgeColor,
    required Color iconColor,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('products')
          .where(
            'category',
            isEqualTo: firestoreKey,
          )
          .where(
            'active',
            isEqualTo: true,
          )
          .where(
            'isTest',
            isEqualTo: false,
          )
          .limit(1)
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        return MenuItem(
          icon: icon,
          title: title,
          badgeColor: badgeColor,
          iconColor: iconColor,
          onTap: () {
            _bukaLayananGenerik(
              firestoreKey:
                  firestoreKey,
              displayName: title,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(
    BuildContext context,
  ) {
    final User? user =
        _currentUser;

    final String accountLabel =
        user?.phoneNumber ??
            user?.email ??
            'Akun DesaPay';

    return Scaffold(
      backgroundColor:
          WarnaDesaPay.lightBg,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color:
            WarnaDesaPay.primary,
        backgroundColor:
            Colors.white,
        child:
            CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(
            parent:
                BouncingScrollPhysics(),
          ),
          slivers: [
            // ====================================================
            // HEADER
            // ====================================================
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              elevation: 0,
              backgroundColor:
                  WarnaDesaPay.primary,
              surfaceTintColor:
                  Colors.transparent,
              flexibleSpace:
                  FlexibleSpaceBar(
                background:
                    Container(
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      colors: [
                        WarnaDesaPay
                            .primary,
                        const Color(
                          0xFF1D4ED8,
                        ),
                        WarnaDesaPay
                            .secondary,
                      ],
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                    ),
                  ),
                  child:
                      SafeArea(
                    bottom: false,
                    child:
                        Padding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        0,
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          // ----------------------------------------
                          // TOP BAR
                          // ----------------------------------------
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .all(2),
                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .white
                                          .withOpacity(
                                        0.20,
                                      ),
                                      shape: BoxShape
                                          .circle,
                                    ),
                                    child:
                                        const CircleAvatar(
                                      radius: 19,
                                      backgroundColor:
                                          WarnaDesaPay
                                              .primary,
                                      child:
                                          Icon(
                                        Icons
                                            .person_rounded,
                                        size: 23,
                                        color: Colors
                                            .white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 11,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        'DesaPay',
                                        style:
                                            TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize:
                                              14,
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 2,
                                      ),
                                      Text(
                                        accountLabel,
                                        style:
                                            TextStyle(
                                          color: Colors
                                              .white
                                              .withOpacity(
                                            0.78,
                                          ),
                                          fontSize:
                                              11,
                                          fontWeight:
                                              FontWeight
                                                  .w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CustomBounce(
                                    onTap:
                                        _launchWA,
                                    child:
                                        _headerIconButton(
                                      Icons
                                          .headset_mic_rounded,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 9,
                                  ),
                                  CustomBounce(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  const NotifikasiScreen(),
                                        ),
                                      );
                                    },
                                    child:
                                        Stack(
                                      clipBehavior:
                                          Clip.none,
                                      children: [
                                        _headerIconButton(
                                          Icons
                                              .notifications_active_rounded,
                                        ),
                                        Positioned(
                                          right:
                                              2,
                                          top: 1,
                                          child:
                                              Container(
                                            width:
                                                8,
                                            height:
                                                8,
                                            decoration:
                                                const BoxDecoration(
                                              color:
                                                  Color(
                                                0xFFFF3B30,
                                              ),
                                              shape:
                                                  BoxShape
                                                      .circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // ----------------------------------------
                          // SALDO
                          // ----------------------------------------
                          Text(
                            'Total Saldo',
                            style:
                                TextStyle(
                              color: Colors
                                  .white
                                  .withOpacity(
                                0.78,
                              ),
                              fontSize:
                                  12,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          StreamBuilder<int>(
                            stream:
                                user == null
                                    ? const Stream<
                                        int>.empty()
                                    : _saldoService
                                        .streamSaldo(
                                        user.uid,
                                      ),
                            builder:
                                (
                              context,
                              snapshot,
                            ) {
                              final int saldo =
                                  snapshot.data ??
                                      0;

                              return Row(
                                children: [
                                  const Text(
                                    'Rp',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .white,
                                      fontSize:
                                          15,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Expanded(
                                    child:
                                        Text(
                                      _isSaldoHidden
                                          ? '••••••'
                                          : _formatRupiah(
                                              saldo,
                                            ),
                                      maxLines:
                                          1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize:
                                            30,
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                        letterSpacing:
                                            0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  CustomBounce(
                                    onTap:
                                        () {
                                      setState(
                                        () {
                                          _isSaldoHidden =
                                              !_isSaldoHidden;
                                        },
                                      );
                                    },
                                    child:
                                        Container(
                                      padding:
                                          const EdgeInsets
                                              .all(
                                        7,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: Colors
                                            .white
                                            .withOpacity(
                                          0.14,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          10,
                                        ),
                                      ),
                                      child:
                                          Icon(
                                        _isSaldoHidden
                                            ? Icons
                                                .visibility_off_rounded
                                            : Icons
                                                .visibility_rounded,
                                        color:
                                            Colors
                                                .white,
                                        size:
                                            19,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(
                            height: 17,
                          ),

                          // ----------------------------------------
                          // ISI SALDO FULL WIDTH
                          // ----------------------------------------
                          CustomBounce(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const TopupSaldoScreen(),
                                ),
                              );
                            },
                            child:
                                Container(
                              height:
                                  52,
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    15,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .white
                                    .withOpacity(
                                  0.14,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  16,
                                ),
                                border:
                                    Border.all(
                                  color: Colors
                                      .white
                                      .withOpacity(
                                    0.18,
                                  ),
                                ),
                              ),
                              child:
                                  Row(
                                children: [
                                  Container(
                                    width:
                                        35,
                                    height:
                                        35,
                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .white
                                          .withOpacity(
                                        0.18,
                                      ),
                                      shape:
                                          BoxShape
                                              .circle,
                                    ),
                                    child:
                                        const Icon(
                                      Icons
                                          .add_rounded,
                                      color:
                                          Colors
                                              .white,
                                      size:
                                          23,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 11,
                                  ),
                                  const Expanded(
                                    child:
                                        Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          'Isi Saldo',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.white,
                                            fontSize:
                                                13,
                                            fontWeight:
                                                FontWeight
                                                    .w800,
                                          ),
                                        ),
                                        SizedBox(
                                          height:
                                              2,
                                        ),
                                        Text(
                                          'Tambah saldo dengan cepat',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.white70,
                                            fontSize:
                                                10,
                                            fontWeight:
                                                FontWeight
                                                    .w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons
                                        .arrow_forward_ios_rounded,
                                    color: Colors
                                        .white70,
                                    size:
                                        14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ====================================================
            // CONTENT
            // ====================================================
            SliverToBoxAdapter(
              child:
                  Container(
                decoration:
                    const BoxDecoration(
                  color:
                      WarnaDesaPay.lightBg,
                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        Radius.circular(
                      24,
                    ),
                    topRight:
                        Radius.circular(
                      24,
                    ),
                  ),
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // BANNER PROMO
                    // ==================================================
                    SizedBox(
                      height: 168,
                      child:
                          PageView.builder(
                        controller:
                            _pageController,
                        itemCount:
                            _promoBanners
                                .length,
                        onPageChanged:
                            (index) {
                          if (!mounted) {
                            return;
                          }

                          setState(() {
                            _currentBannerIndex =
                                index;
                          });
                        },
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final banner =
                              _promoBanners[
                                  index];

                          return CustomBounce(
                            onTap:
                                () {},
                            child:
                                Container(
                              margin:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    5,
                              ),
                              decoration:
                                  BoxDecoration(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  22,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        WarnaDesaPay
                                            .shadow
                                            .withOpacity(
                                      0.15,
                                    ),
                                    blurRadius:
                                        18,
                                    offset:
                                        const Offset(
                                      0,
                                      9,
                                    ),
                                  ),
                                ],
                              ),
                              child:
                                  ClipRRect(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  22,
                                ),
                                child:
                                    Stack(
                                  fit: StackFit
                                      .expand,
                                  children: [
                                    Image.network(
                                      banner.image,
                                      fit: BoxFit
                                          .cover,
                                      errorBuilder:
                                          (
                                        _,
                                        __,
                                        ___,
                                      ) {
                                        return Container(
                                          decoration:
                                              const BoxDecoration(
                                            gradient:
                                                LinearGradient(
                                              colors: [
                                                Color(
                                                  0xFF1D4ED8,
                                                ),
                                                Color(
                                                  0xFF0F766E,
                                                ),
                                              ],
                                              begin:
                                                  Alignment
                                                      .topLeft,
                                              end:
                                                  Alignment
                                                      .bottomRight,
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    Container(
                                      decoration:
                                          const BoxDecoration(
                                        gradient:
                                            LinearGradient(
                                          colors: [
                                            Colors
                                                .black54,
                                            Colors
                                                .transparent,
                                            Colors
                                                .black26,
                                          ],
                                          begin:
                                              Alignment
                                                  .centerLeft,
                                          end:
                                              Alignment
                                                  .centerRight,
                                        ),
                                      ),
                                    ),

                                    Positioned(
                                      left: 18,
                                      top: 18,
                                      child:
                                          Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal:
                                              10,
                                          vertical:
                                              5,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .white
                                              .withOpacity(
                                            0.18,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            30,
                                          ),
                                          border:
                                              Border.all(
                                            color: Colors
                                                .white
                                                .withOpacity(
                                              0.20,
                                            ),
                                          ),
                                        ),
                                        child:
                                            Text(
                                          banner.badge,
                                          style:
                                              const TextStyle(
                                            color: Colors
                                                .white,
                                            fontSize:
                                                9,
                                            fontWeight:
                                                FontWeight
                                                    .w900,
                                            letterSpacing:
                                                0.8,
                                          ),
                                        ),
                                      ),
                                    ),

                                    Positioned(
                                      left: 18,
                                      right: 20,
                                      bottom: 17,
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            banner.title,
                                            maxLines:
                                                1,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.white,
                                              fontSize:
                                                  19,
                                              fontWeight:
                                                  FontWeight
                                                      .w900,
                                            ),
                                          ),
                                          const SizedBox(
                                            height:
                                                4,
                                          ),
                                          Text(
                                            banner.subtitle,
                                            maxLines:
                                                2,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.white70,
                                              fontSize:
                                                  11,
                                              fontWeight:
                                                  FontWeight
                                                      .w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==================================================
                    // INDICATOR
                    // ==================================================
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children:
                          List.generate(
                        _promoBanners
                            .length,
                        (index) {
                          final bool active =
                              index ==
                                  _currentBannerIndex;

                          return AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds:
                                  250,
                            ),
                            width:
                                active ? 20 : 6,
                            height: 5,
                            margin:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  2,
                            ),
                            decoration:
                                BoxDecoration(
                              color: active
                                  ? WarnaDesaPay
                                      .primary
                                  : WarnaDesaPay
                                      .primary
                                      .withOpacity(
                                    0.22,
                                  ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==================================================
                    // HEADER MENU
                    // ==================================================
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                      ),
                      child:
                          Row(
                        children: [
                          const Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Layanan DesaPay',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                    color:
                                        WarnaDesaPay
                                            .textMain,
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      3,
                                ),
                                Text(
                                  'Semua kebutuhan dalam satu aplikasi',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        10,
                                    color:
                                        WarnaDesaPay
                                            .textSub,
                                    fontWeight:
                                        FontWeight
                                            .w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CustomBounce(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const SemuaLayananScreen(),
                                ),
                              );
                            },
                            child:
                                Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    10,
                                vertical: 7,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    WarnaDesaPay
                                        .primary
                                        .withOpacity(
                                  0.08,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),
                              child:
                                  const Row(
                                children: [
                                  Text(
                                    'Lihat semua',
                                    style:
                                        TextStyle(
                                      color:
                                          WarnaDesaPay
                                              .primary,
                                      fontSize:
                                          10,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        4,
                                  ),
                                  Icon(
                                    Icons
                                        .arrow_forward_ios_rounded,
                                    size:
                                        10,
                                    color:
                                        WarnaDesaPay
                                            .primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // MENU GRID
                    // ==================================================
                    Container(
                      margin:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                      ),
                      padding:
                          const EdgeInsets
                              .all(
                        14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          22,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withOpacity(
                              0.035,
                            ),
                            blurRadius:
                                20,
                            offset:
                                const Offset(
                              0,
                              8,
                            ),
                          ),
                        ],
                      ),
                      child:
                          GridView.count(
                        crossAxisCount:
                            4,
                        shrinkWrap:
                            true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        mainAxisSpacing:
                            22,
                        crossAxisSpacing:
                            8,
                        padding:
                            EdgeInsets.zero,
                        children: [
                          // =================================================
                          // 1. TELEKOMUNIKASI
                          // =================================================
                          MenuItem(
                            icon: Icons
                                .phone_android_rounded,
                            title:
                                'Pulsa',
                            badgeColor:
                                const Color(
                              0xFFEFF6FF,
                            ),
                            iconColor:
                                WarnaDesaPay
                                    .primary,
                            onTap: () {
                              Navigator
                                  .push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const PulsaScreen(),
                                ),
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .wifi_tethering_rounded,
                            title:
                                'Paket Data',
                            badgeColor:
                                const Color(
                              0xFFF0FDF4,
                            ),
                            iconColor:
                                const Color(
                              0xFF16A34A,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Data',
                                displayName:
                                    'Paket Data',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .phone_in_talk_rounded,
                            title:
                                'Telp & SMS',
                            badgeColor:
                                const Color(
                              0xFFFEF2F2,
                            ),
                            iconColor:
                                const Color(
                              0xFFDC2626,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Telpon dan SMS',
                                displayName:
                                    'Telp & SMS',
                              );
                            },
                          ),

                          MenuItem(
                            icon:
                                Icons.bolt_rounded,
                            title:
                                'Token PLN',
                            badgeColor:
                                const Color(
                              0xFFFFFBEB,
                            ),
                            iconColor:
                                const Color(
                              0xFFD97706,
                            ),
                            onTap: () {
                              Navigator
                                  .push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const PlnScreen(),
                                ),
                              );
                            },
                          ),

                          // =================================================
                          // 2. GAME & DIGITAL
                          // =================================================
                          MenuItem(
                            icon: Icons
                                .sports_esports_rounded,
                            title:
                                'Top Up Game',
                            badgeColor:
                                const Color(
                              0xFFFFF1F2,
                            ),
                            iconColor:
                                const Color(
                              0xFFE11D48,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Games',
                                displayName:
                                    'Top Up Game',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .gamepad_rounded,
                            title:
                                'Voucher Game',
                            badgeColor:
                                const Color(
                              0xFFFAF5FF,
                            ),
                            iconColor:
                                const Color(
                              0xFF9333EA,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Voucher Game',
                                displayName:
                                    'Voucher Game',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .account_balance_wallet_rounded,
                            title:
                                'E-Wallet',
                            badgeColor:
                                const Color(
                              0xFFF5F3FF,
                            ),
                            iconColor:
                                const Color(
                              0xFF7C3AED,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'E-Money',
                                displayName:
                                    'E-Wallet',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .shopping_bag_rounded,
                            title:
                                'Voucher',
                            badgeColor:
                                const Color(
                              0xFFFFF7ED,
                            ),
                            iconColor:
                                const Color(
                              0xFFEA580C,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Voucher Digital',
                                displayName:
                                    'Voucher Belanja',
                              );
                            },
                          ),

                          // =================================================
                          // 3. DIGITAL
                          // =================================================
                          MenuItem(
                            icon: Icons
                                .play_circle_filled_rounded,
                            title:
                                'Streaming',
                            badgeColor:
                                const Color(
                              0xFFFEF2F2,
                            ),
                            iconColor:
                                const Color(
                              0xFFDC2626,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Streaming',
                                displayName:
                                    'Streaming',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .update_rounded,
                            title:
                                'Masa Aktif',
                            badgeColor:
                                const Color(
                              0xFFECFEFF,
                            ),
                            iconColor:
                                const Color(
                              0xFF0891B2,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Masa Aktif',
                                displayName:
                                    'Masa Aktif',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .qr_code_scanner_rounded,
                            title:
                                'Aktivasi',
                            badgeColor:
                                const Color(
                              0xFFF1F5F9,
                            ),
                            iconColor:
                                const Color(
                              0xFF475569,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Aktivasi Voucher',
                                displayName:
                                    'Aktivasi Voucher',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .sim_card_rounded,
                            title:
                                'Kartu Perdana',
                            badgeColor:
                                const Color(
                              0xFFEFF6FF,
                            ),
                            iconColor:
                                const Color(
                              0xFF2563EB,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Paket Perdana',
                                displayName:
                                    'Kartu Perdana',
                              );
                            },
                          ),

                          // =================================================
                          // 4. TAGIHAN
                          // =================================================
                          MenuItem(
                            icon: Icons
                                .electric_meter_rounded,
                            title:
                                'PLN Pasca',
                            badgeColor:
                                const Color(
                              0xFFFFFBEB,
                            ),
                            iconColor:
                                const Color(
                              0xFFD97706,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Pascabayar',
                                displayName:
                                    'PLN Pasca',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .router_rounded,
                            title:
                                'IndiHome',
                            badgeColor:
                                const Color(
                              0xFFF3F4F6,
                            ),
                            iconColor:
                                const Color(
                              0xFF111827,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'IndiHome',
                                displayName:
                                    'IndiHome',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .water_drop_rounded,
                            title:
                                'PDAM',
                            badgeColor:
                                const Color(
                              0xFFECFEFF,
                            ),
                            iconColor:
                                WarnaDesaPay
                                    .secondary,
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'PDAM',
                                displayName:
                                    'PDAM',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .health_and_safety_rounded,
                            title:
                                'BPJS',
                            badgeColor:
                                const Color(
                              0xFFF0FDF4,
                            ),
                            iconColor:
                                const Color(
                              0xFF16A34A,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'BPJS Kesehatan',
                                displayName:
                                    'BPJS',
                              );
                            },
                          ),

                          // =================================================
                          // 5. CICILAN & PAJAK
                          // =================================================
                          MenuItem(
                            icon: Icons
                                .receipt_long_rounded,
                            title:
                                'Angsuran',
                            badgeColor:
                                const Color(
                              0xFFF1F5F9,
                            ),
                            iconColor:
                                const Color(
                              0xFF475569,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Multifinance',
                                displayName:
                                    'Angsuran',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .contact_phone_rounded,
                            title:
                                'HP Pasca',
                            badgeColor:
                                const Color(
                              0xFFEFF6FF,
                            ),
                            iconColor:
                                const Color(
                              0xFF2563EB,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'HP Pascabayar',
                                displayName:
                                    'HP Pasca',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .tv_rounded,
                            title:
                                'TV',
                            badgeColor:
                                const Color(
                              0xFFFAF5FF,
                            ),
                            iconColor:
                                const Color(
                              0xFF9333EA,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'TV Berlangganan',
                                displayName:
                                    'TV Kabel',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .account_balance_rounded,
                            title:
                                'PBB',
                            badgeColor:
                                const Color(
                              0xFFF0FDF4,
                            ),
                            iconColor:
                                const Color(
                              0xFF059669,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'PBB',
                                displayName:
                                    'Pajak PBB',
                              );
                            },
                          ),

                          // =================================================
                          // 6. TRANSPORTASI / LAINNYA
                          // =================================================
                          MenuItem(
                            icon: Icons
                                .local_fire_department_rounded,
                            title:
                                'Gas',
                            badgeColor:
                                const Color(
                              0xFFFFF7ED,
                            ),
                            iconColor:
                                const Color(
                              0xFFEA580C,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'PGN',
                                displayName:
                                    'Gas PGN',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .directions_car_rounded,
                            title:
                                'E-Samsat',
                            badgeColor:
                                const Color(
                              0xFFF5F3FF,
                            ),
                            iconColor:
                                const Color(
                              0xFF7C3AED,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'E-Samsat',
                                displayName:
                                    'E-Samsat',
                              );
                            },
                          ),

                          MenuItem(
                            icon: Icons
                                .directions_bus_rounded,
                            title:
                                'Tiket',
                            badgeColor:
                                const Color(
                              0xFFFEF2F2,
                            ),
                            iconColor:
                                const Color(
                              0xFFDC2626,
                            ),
                            onTap: () {
                              _bukaLayananGenerik(
                                firestoreKey:
                                    'Tiket Perjalanan',
                                displayName:
                                    'Tiket',
                              );
                            },
                          ),

                          // =================================================
                          // SEMUA
                          // =================================================
                          MenuItem(
                            icon: Icons
                                .grid_view_rounded,
                            title:
                                'Semua',
                            badgeColor:
                                WarnaDesaPay
                                    .lightField,
                            iconColor:
                                WarnaDesaPay
                                    .textSub,
                            onTap: () {
                              Navigator
                                  .push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const SemuaLayananScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // PENGUMUMAN REALTIME
                    // ==================================================
                    Container(
                      margin:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                        border:
                            Border.all(
                          color:
                              WarnaDesaPay
                                  .lightField,
                        ),
                      ),
                      child:
                          Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration:
                                BoxDecoration(
                              color: WarnaDesaPay
                                  .primary
                                  .withOpacity(
                                0.08,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                10,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .campaign_rounded,
                              color:
                                  WarnaDesaPay
                                      .primary,
                              size:
                                  19,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child:
                                StreamBuilder<
                                    QuerySnapshot>(
                              stream: _db
                                  .collection(
                                    'announcements',
                                  )
                                  .orderBy(
                                    'timestamp',
                                    descending:
                                        true,
                                  )
                                  .limit(1)
                                  .snapshots(),
                              builder:
                                  (
                                context,
                                snapshot,
                              ) {
                                String textBerjalan =
                                    'Selamat datang di DesaPay • Transaksi cepat dan aman.';

                                if (snapshot
                                        .hasData &&
                                    snapshot
                                        .data!
                                        .docs
                                        .isNotEmpty) {
                                  final dynamic raw =
                                      snapshot
                                          .data!
                                          .docs
                                          .first
                                          .data();

                                  if (raw
                                      is Map<String,
                                          dynamic>) {
                                    final dynamic pesan =
                                        raw[
                                            'pesan'];

                                    if (pesan
                                            is String &&
                                        pesan
                                            .trim()
                                            .isNotEmpty) {
                                      textBerjalan =
                                          pesan
                                              .trim();
                                    }
                                  }
                                }

                                return Text(
                                  textBerjalan,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        11,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                    color:
                                        WarnaDesaPay
                                            .textMain,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    // ==================================================
                    // PROMO
                    // ==================================================
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                      ),
                      child:
                          Row(
                        children: [
                          const Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Promo & Keuntungan',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                    color:
                                        WarnaDesaPay
                                            .textMain,
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      3,
                                ),
                                Text(
                                  'Penawaran pilihan untuk transaksi harianmu',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        10,
                                    fontWeight:
                                        FontWeight
                                            .w500,
                                    color:
                                        WarnaDesaPay
                                            .textSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 13,
                    ),

                    // ==================================================
                    // PROMO CARDS
                    // ==================================================
                    SizedBox(
                      height: 142,
                      child:
                          ListView(
                        scrollDirection:
                            Axis.horizontal,
                        padding:
                            const EdgeInsets
                                .only(
                          left: 20,
                          right: 8,
                        ),
                        physics:
                            const BouncingScrollPhysics(),
                        children: [
                          _modernPromoCard(
                            width: 250,
                            title:
                                'Pulsa & Data',
                            subtitle:
                                'Transaksi kapan saja tanpa ribet',
                            smallText:
                                'DESAPAY • CEPAT',
                            icon: Icons
                                .phone_android_rounded,
                            startColor:
                                const Color(
                              0xFF2563EB,
                            ),
                            endColor:
                                const Color(
                              0xFF4F46E5,
                            ),
                          ),
                          _modernPromoCard(
                            width: 250,
                            title:
                                'Bayar Tagihan',
                            subtitle:
                                'PLN, internet, air, BPJS & lainnya',
                            smallText:
                                'SEMUA DALAM SATU APP',
                            icon: Icons
                                .receipt_long_rounded,
                            startColor:
                                const Color(
                              0xFF0F766E,
                            ),
                            endColor:
                                const Color(
                              0xFF0891B2,
                            ),
                          ),
                          _modernPromoCard(
                            width: 250,
                            title:
                                'Top Up Digital',
                            subtitle:
                                'Game, e-wallet dan voucher digital',
                            smallText:
                                'PRAKTIS & AMAN',
                            icon: Icons
                                .account_balance_wallet_rounded,
                            startColor:
                                const Color(
                              0xFF7C3AED,
                            ),
                            endColor:
                                const Color(
                              0xFFDB2777,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    // ==================================================
                    // KEUNGGULAN KECIL
                    // ==================================================
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                      ),
                      child:
                          Row(
                        children: [
                          Expanded(
                            child:
                                _miniInfoCard(
                              icon:
                                  Icons.flash_on_rounded,
                              title:
                                  'Cepat',
                              subtitle:
                                  'Proses praktis',
                            ),
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          Expanded(
                            child:
                                _miniInfoCard(
                              icon:
                                  Icons.lock_rounded,
                              title:
                                  'Aman',
                              subtitle:
                                  'Data terlindungi',
                            ),
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          Expanded(
                            child:
                                _miniInfoCard(
                              icon:
                                  Icons.support_agent_rounded,
                              title:
                                  'CS',
                              subtitle:
                                  'Siap membantu',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 35,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER ICON
  // ============================================================
  Widget _headerIconButton(
    IconData icon,
  ) {
    return Container(
      width: 37,
      height: 37,
      decoration:
          BoxDecoration(
        color: Colors.white
            .withOpacity(
          0.12,
        ),
        borderRadius:
            BorderRadius
                .circular(
          12,
        ),
      ),
      child:
          Icon(
        icon,
        color: Colors
            .white,
        size: 19,
      ),
    );
  }

  // ============================================================
  // MODERN PROMO
  // ============================================================
  Widget _modernPromoCard({
    required double width,
    required String title,
    required String subtitle,
    required String smallText,
    required IconData icon,
    required Color startColor,
    required Color endColor,
  }) {
    return CustomBounce(
      onTap: () {},
      child:
          Container(
        width: width,
        margin:
            const EdgeInsets
                .only(
          right: 10,
        ),
        padding:
            const EdgeInsets
                .all(
          17,
        ),
        decoration:
            BoxDecoration(
          gradient:
              LinearGradient(
            colors: [
              startColor,
              endColor,
            ],
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius
                  .circular(
            21,
          ),
          boxShadow: [
            BoxShadow(
              color: startColor
                  .withOpacity(
                0.20,
              ),
              blurRadius:
                  15,
              offset:
                  const Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child:
            Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -12,
              child:
                  Container(
                width: 105,
                height: 105,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color: Colors.white
                      .withOpacity(
                    0.08,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 15,
              top: 15,
              child:
                  Container(
                width: 43,
                height: 43,
                decoration:
                    BoxDecoration(
                  color: Colors
                      .white
                      .withOpacity(
                    0.13,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    Icon(
                  icon,
                  color:
                      Colors.white,
                  size:
                      23,
                ),
              ),
            ),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  smallText,
                  style:
                      const TextStyle(
                    color: Colors
                        .white70,
                    fontSize: 8,
                    fontWeight:
                        FontWeight
                            .w900,
                    letterSpacing:
                        0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color: Colors
                        .white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight
                            .w900,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                SizedBox(
                  width: 175,
                  child:
                      Text(
                    subtitle,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize:
                          10,
                      height:
                          1.3,
                      fontWeight:
                          FontWeight
                              .w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MINI INFO
  // ============================================================
  Widget _miniInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius
                .circular(
          15,
        ),
        border:
            Border.all(
          color:
              WarnaDesaPay
                  .lightField,
        ),
      ),
      child:
          Column(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                WarnaDesaPay
                    .primary,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight
                      .w800,
              color:
                  WarnaDesaPay
                      .textMain,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow:
                TextOverflow
                    .ellipsis,
            style:
                const TextStyle(
              fontSize: 8,
              fontWeight:
                  FontWeight
                      .w500,
              color:
                  WarnaDesaPay
                      .textSub,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BANNER MODEL
// ================================================================
class _BannerData {
  final String image;
  final String badge;
  final String title;
  final String subtitle;

  const _BannerData({
    required this.image,
    required this.badge,
    required this.title,
    required this.subtitle,
  });
}

// ================================================================
// CUSTOM BOUNCE
// ================================================================
class CustomBounce
    extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const CustomBounce({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<CustomBounce>
      createState() =>
          _CustomBounceState();
}

class _CustomBounceState
    extends State<CustomBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController
      _controller;

  late Animation<double>
      _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 130,
      ),
    );

    _scaleAnimation =
        Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve:
            Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTapDown: (_) {
        _controller
            .forward();
      },
      onTapUp: (_) {
        _controller
            .reverse();

        widget.onTap();
      },
      onTapCancel: () {
        _controller
            .reverse();
      },
      child:
          ScaleTransition(
        scale:
            _scaleAnimation,
        child:
            widget.child,
      ),
    );
  }
}
