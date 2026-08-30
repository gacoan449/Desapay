// =====================================================================
// FILE: lib/main.dart
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/warna.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'widgets/bottom_nav.dart';
import 'screens/admin/admin_dashboard_screen.dart';


// =====================================================================
// SUPABASE CONFIG
// =====================================================================
//
// GANTI 2 DATA DI BAWAH DENGAN DATA DARI SUPABASE
//
// Supabase Dashboard
// → Project Settings
// → API
//
// URL:
// https://xxxxxxxx.supabase.co
//
// Publishable / anon key:
// eyJhbGciOi...
//
// JANGAN MASUKKAN service_role key KE APK!
// =====================================================================

const String supabaseUrl = 'https://sukqrxsolvukqunrurfw.supabase.co/rest/v1/';

const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN1a3FyeHNvbHZ1a3F1bnJ1cmZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxMDQ2MzMsImV4cCI6MjEwMzY4MDYzM30.Uwl9JEJiwItJw86gZ3EILQYZYkT00cnM-57ElGz6ODY';


// =====================================================================
// MAIN
// =====================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================================================
  // PORTRAIT ONLY
  // =========================================================

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // =========================================================
  // SUPABASE
  // =========================================================

  bool supabaseReady = false;
  String? supabaseError;

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    supabaseReady = true;

    debugPrint(
      '✅ DesaPay Supabase berhasil terhubung.',
    );
  } catch (e, stackTrace) {
    supabaseError = e.toString();

    debugPrint(
      '❌ Supabase initialization gagal: $e',
    );

    debugPrint(
      stackTrace.toString(),
    );
  }

  // =========================================================
  // APP
  // =========================================================

  runApp(
    DesaPayApp(
      supabaseReady: supabaseReady,
      supabaseError: supabaseError,
    ),
  );
}


// =====================================================================
// DESAPAY APP
// =====================================================================

class DesaPayApp extends StatelessWidget {
  final bool supabaseReady;
  final String? supabaseError;

  const DesaPayApp({
    super.key,
    required this.supabaseReady,
    this.supabaseError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DesaPay',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: WarnaDesaPay.primary,
          primary: WarnaDesaPay.primary,
          onPrimary: Colors.white,
          secondary: WarnaDesaPay.secondary,
          surface: Colors.white,
        ),

        scaffoldBackgroundColor:
            WarnaDesaPay.lightBg,

        fontFamily: 'Inter',

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      home: !supabaseReady
          ? SupabaseErrorScreen(
              error:
                  supabaseError ??
                      'Supabase belum berhasil diinisialisasi.',
            )
          : const DesaPayHome(),
    );
  }
}


// =====================================================================
// SUPABASE ERROR SCREEN
// =====================================================================

class SupabaseErrorScreen extends StatelessWidget {
  final String error;

  const SupabaseErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          WarnaDesaPay.lightBg,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 72,
                  color: Colors.red,
                ),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  'DesaPay gagal memulai',
                  textAlign:
                      TextAlign.center,

                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                const Text(
                  'Supabase tidak berhasil diinisialisasi.',
                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(
                  height: 20,
                ),

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  child: SelectableText(
                    error,

                    style:
                        const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// =====================================================================
// DESAPAY HOME / AUTH GATE
// =====================================================================
//
// ALUR SEMENTARA:
//
// Supabase Auth
//      ↓
// User ditemukan?
//      ↓
// users/{id}
//      ↓
// role
//      ↓
// admin → AdminDashboard
// user  → BottomNav
//
// =====================================================================

class DesaPayHome extends StatefulWidget {
  const DesaPayHome({
    super.key,
  });

  @override
  State<DesaPayHome> createState() =>
      _DesaPayHomeState();
}


class _DesaPayHomeState
    extends State<DesaPayHome> {

  String? _loadedUid;

  Future<_AccountDestination>?
      _destinationFuture;


  // =========================================================
  // AUTH STREAM
  // =========================================================

  Stream<AuthState> get _authStream =>
      Supabase.instance.client.auth
          .onAuthStateChange;


  // =========================================================
  // LOAD ACCOUNT
  // =========================================================

  Future<_AccountDestination>
      _loadAccountDestination(
    String uid,
  ) async {

    try {

      final response =
          await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', uid)
              .maybeSingle();


      // -------------------------------------------------------
      // USER TIDAK ADA
      // -------------------------------------------------------

      if (response == null) {

        return _AccountDestination.error(
          'Data akun tidak ditemukan di database DesaPay.\n\n'
          'User ID: $uid',
        );
      }


      // -------------------------------------------------------
      // ROLE
      // -------------------------------------------------------

      final String role =
          (response['role'] ?? '')
              .toString()
              .trim()
              .toLowerCase();


      debugPrint(
        '🔐 DesaPay role check: '
        'uid=$uid role=$role',
      );


      // -------------------------------------------------------
      // ADMIN
      // -------------------------------------------------------

      if (role == 'admin') {

        return const
            _AccountDestination.admin();
      }


      // -------------------------------------------------------
      // USER
      // -------------------------------------------------------

      if (role == 'user') {

        return const
            _AccountDestination.user();
      }


      // -------------------------------------------------------
      // ROLE TIDAK VALID
      // -------------------------------------------------------

      return _AccountDestination.error(
        'Role akun tidak valid.\n\n'
        'User ID: $uid\n'
        'Role: ${role.isEmpty ? '(kosong)' : role}',
      );

    } on PostgrestException catch (e) {

      debugPrint(
        '❌ Supabase account check gagal: '
        '${e.code} - ${e.message}',
      );

      return _AccountDestination.error(
        'Gagal memverifikasi akun DesaPay.\n\n'
        'Kode: ${e.code}\n'
        '${e.message}',
      );

    } catch (e, stackTrace) {

      debugPrint(
        '❌ Account routing error: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      return const
          _AccountDestination.error(
        'Terjadi kesalahan saat memverifikasi akun.',
      );
    }
  }


  // =========================================================
  // RESET DESTINATION CACHE
  // =========================================================

  void _resetDestination() {

    if (!mounted) {
      return;
    }

    setState(() {

      _loadedUid = null;

      _destinationFuture = null;
    });
  }


  // =========================================================
  // PREPARE DESTINATION
  // =========================================================

  void _prepareDestination(
    User user,
  ) {

    if (_loadedUid == user.id &&
        _destinationFuture != null) {

      return;
    }

    _loadedUid = user.id;

    _destinationFuture =
        _loadAccountDestination(
      user.id,
    );
  }


  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return StreamBuilder<AuthState>(
      stream: _authStream,

      builder: (
        context,
        snapshot,
      ) {

        // =====================================================
        // AUTH MASIH MEMUAT
        // =====================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return const SplashScreen();
        }


        // =====================================================
        // AMBIL USER SUPABASE
        // =====================================================

        final User? user =
            Supabase.instance.client
                .auth
                .currentUser;


        // =====================================================
        // BELUM LOGIN
        // =====================================================

        if (user == null) {

          _loadedUid = null;

          _destinationFuture = null;

          return const LoginScreen();
        }


        // =====================================================
        // LOGIN ADA
        // =====================================================

        _prepareDestination(user);

        final Future<_AccountDestination>?
            future =
            _destinationFuture;


        if (future == null) {

          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }


        // =====================================================
        // CEK ROLE
        // =====================================================

        return FutureBuilder<
            _AccountDestination>(
          future: future,

          builder: (
            context,
            accountSnapshot,
          ) {

            // -------------------------------------------------
            // LOADING
            // -------------------------------------------------

            if (accountSnapshot
                    .connectionState ==
                ConnectionState.waiting) {

              return const Scaffold(
                backgroundColor:
                    WarnaDesaPay.lightBg,

                body: Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        WarnaDesaPay.primary,
                  ),
                ),
              );
            }


            // -------------------------------------------------
            // ERROR
            // -------------------------------------------------

            if (accountSnapshot.hasError) {

              return _AccountErrorScreen(
                message:
                    'Gagal memverifikasi akun:\n\n'
                    '${accountSnapshot.error}',

                onRetry:
                    _resetDestination,
              );
            }


            final _AccountDestination?
                destination =
                accountSnapshot.data;


            if (destination == null) {

              return _AccountErrorScreen(
                message:
                    'Sistem tidak menerima hasil '
                    'verifikasi akun.',

                onRetry:
                    _resetDestination,
              );
            }


            // -------------------------------------------------
            // ADMIN
            // -------------------------------------------------

            if (destination.isAdmin) {

              debugPrint(
                '✅ Routing → AdminDashboardScreen',
              );

              return const
                  AdminDashboardScreen();
            }


            // -------------------------------------------------
            // USER
            // -------------------------------------------------

            if (destination.isUser) {

              debugPrint(
                '✅ Routing → BottomNav',
              );

              return const BottomNav();
            }


            // -------------------------------------------------
            // ERROR
            // -------------------------------------------------

            return _AccountErrorScreen(
              message:
                  destination.errorMessage ??
                      'Akun tidak dapat diverifikasi.',

              onRetry:
                  _resetDestination,
            );
          },
        );
      },
    );
  }
}


// =====================================================================
// ACCOUNT DESTINATION
// =====================================================================

class _AccountDestination {

  final bool isAdmin;

  final bool isUser;

  final String? errorMessage;


  const _AccountDestination({
    this.isAdmin = false,
    this.isUser = false,
    this.errorMessage,
  });


  const _AccountDestination.admin()
      : isAdmin = true,
        isUser = false,
        errorMessage = null;


  const _AccountDestination.user()
      : isAdmin = false,
        isUser = true,
        errorMessage = null;


  const _AccountDestination.error(
    String message,
  )
      : isAdmin = false,
        isUser = false,
        errorMessage = message;
}


// =====================================================================
// ACCOUNT ERROR SCREEN
// =====================================================================

class _AccountErrorScreen
    extends StatelessWidget {

  final String message;

  final VoidCallback onRetry;


  const _AccountErrorScreen({
    required this.message,
    required this.onRetry,
  });


  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(
      backgroundColor:
          WarnaDesaPay.lightBg,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                Container(
                  width: 70,
                  height: 70,

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.orange
                            .withOpacity(
                      0.12,
                    ),

                    shape:
                        BoxShape.circle,
                  ),

                  child:
                      const Icon(
                    Icons
                        .manage_accounts_rounded,

                    size: 38,

                    color:
                        Colors.orange,
                  ),
                ),


                const SizedBox(
                  height: 18,
                ),


                const Text(
                  'Akun Belum Dapat Diverifikasi',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),


                const SizedBox(
                  height: 12,
                ),


                SelectableText(
                  message,

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color:
                        Colors.black54,
                  ),
                ),


                const SizedBox(
                  height: 24,
                ),


                // =================================================
                // RETRY
                // =================================================

                ElevatedButton.icon(
                  onPressed:
                      onRetry,

                  icon:
                      const Icon(
                    Icons.refresh,
                  ),

                  label:
                      const Text(
                    'Coba Lagi',
                  ),
                ),


                const SizedBox(
                  height: 10,
                ),


                // =================================================
                // LOGOUT
                // =================================================

                OutlinedButton.icon(
                  onPressed:
                      () async {

                    try {

                      await Supabase
                          .instance
                          .client
                          .auth
                          .signOut();

                    } catch (e) {

                      debugPrint(
                        'Logout error: $e',
                      );
                    }
                  },

                  icon:
                      const Icon(
                    Icons.logout,
                  ),

                  label:
                      const Text(
                    'Keluar',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
