// =====================================================================
// FILE: lib/main.dart
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'config/warna.dart';
import 'firebase_options.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'widgets/bottom_nav.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/belanjaku/courier_home_screen.dart';


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
  // FIREBASE
  // =========================================================

  FirebaseApp? firebaseApp;
  String? firebaseError;

  try {
    firebaseApp = await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions.currentPlatform,
    );

    // =======================================================
    // CLOUD FUNCTIONS
    // =======================================================
    //
    // Instance tersedia setelah Firebase berhasil
    // diinisialisasi.
    //
    // Function dipanggil oleh service ketika diperlukan.
    //
    // =======================================================

    FirebaseFunctions.instance;

    debugPrint(
      '✅ DesaPay Firebase berhasil terhubung: '
      '${firebaseApp.name}',
    );

    debugPrint(
      '✅ Firebase Cloud Functions siap digunakan.',
    );
  } catch (e, stackTrace) {
    firebaseError = e.toString();

    debugPrint(
      '❌ Firebase initialization gagal: $e',
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
      firebaseReady:
          firebaseApp != null,
      firebaseError:
          firebaseError,
    ),
  );
}


// =====================================================================
// DESAPAY APP
// =====================================================================

class DesaPayApp extends StatelessWidget {
  final bool firebaseReady;
  final String? firebaseError;

  const DesaPayApp({
    super.key,
    required this.firebaseReady,
    this.firebaseError,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'DesaPay',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              WarnaDesaPay.primary,

          primary:
              WarnaDesaPay.primary,

          onPrimary:
              Colors.white,

          secondary:
              WarnaDesaPay.secondary,

          surface:
              Colors.white,
        ),

        scaffoldBackgroundColor:
            WarnaDesaPay.lightBg,

        fontFamily: 'Inter',

        appBarTheme:
            const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      home: !firebaseReady
          ? FirebaseErrorScreen(
              error:
                  firebaseError ??
                      'Unknown Firebase error',
            )
          : const DesaPayHome(),
    );
  }
}


// =====================================================================
// FIREBASE ERROR SCREEN
// =====================================================================

class FirebaseErrorScreen
    extends StatelessWidget {
  final String error;

  const FirebaseErrorScreen({
    super.key,
    required this.error,
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
          child:
              SingleChildScrollView(
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
                  'Firebase tidak berhasil diinisialisasi.',

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

                  child:
                      SelectableText(
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
// ALUR:
//
// Firebase Auth
//      ↓
// User ditemukan?
//      ↓
// users/{UID}
//      ↓
// role
//      ↓
// admin → AdminDashboard
// courier → BelanjakuCourierHomeScreen
// user  → BottomNav
//
// Role kosong / invalid / dokumen tidak ada:
// → jangan diam-diam masuk ke BottomNav.
//
// =====================================================================

class DesaPayHome
    extends StatefulWidget {
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

  Stream<User?> get _authStream =>
      FirebaseAuth.instance
          .authStateChanges();


  // =========================================================
  // LOAD ACCOUNT
  // =========================================================

  Future<_AccountDestination>
      _loadAccountDestination(
    String uid,
  ) async {
    try {
      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await FirebaseFirestore
              .instance
              .collection('users')
              .doc(uid)
              .get();

      // -------------------------------------------------------
      // USER TIDAK ADA
      // -------------------------------------------------------

      if (!snapshot.exists) {
        return _AccountDestination.error(
          'Data akun tidak ditemukan di database DesaPay.\n\n'
          'UID: $uid',
        );
      }

      final Map<String, dynamic>
          data =
          snapshot.data() ??
              <String, dynamic>{};

      // -------------------------------------------------------
      // ROLE
      // -------------------------------------------------------

      final String role =
          (data['role'] ?? '')
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

      if (role == 'courier') {
        return const _AccountDestination.courier();
      }

      if (role == 'user') {
        return const
            _AccountDestination.user();
      }

      // -------------------------------------------------------
      // ROLE INVALID
      // -------------------------------------------------------

      return _AccountDestination.error(
        'Role akun tidak valid.\n\n'
        'UID: $uid\n'
        'Role: ${role.isEmpty ? '(kosong)' : role}',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firestore account check gagal: '
        '${e.code} - ${e.message}',
      );

      return _AccountDestination.error(
        'Gagal memverifikasi akun DesaPay.\n\n'
        'Kode: ${e.code}\n'
        '${e.message ?? 'Tidak ada pesan tambahan.'}',
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
  // RESET DESTINATION
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
    if (_loadedUid == user.uid &&
        _destinationFuture != null) {
      return;
    }

    _loadedUid = user.uid;

    _destinationFuture =
        _loadAccountDestination(
      user.uid,
    );
  }


  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<User?>(
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
        // BELUM LOGIN
        // =====================================================

        final User? user =
            snapshot.data;

        if (user == null) {
          _loadedUid = null;
          _destinationFuture = null;

          return const LoginScreen();
        }

        // =====================================================
        // LOGIN ADA
        // =====================================================

        _prepareDestination(user);

        final Future<
                _AccountDestination>?
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
            // FUTURE ERROR
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

            if (destination.isCourier) {
              return const BelanjakuCourierHomeScreen();
            }

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
  final bool isCourier;
  final String? errorMessage;

  const _AccountDestination({
    this.isAdmin = false,
    this.isUser = false,
    this.isCourier = false,
    this.errorMessage,
  });

  const _AccountDestination.admin()
      : isAdmin = true,
        isUser = false,
        isCourier = false,
        errorMessage = null;

  const _AccountDestination.user()
      : isAdmin = false,
        isUser = true,
        isCourier = false,
        errorMessage = null;

  const _AccountDestination.courier()
      : isAdmin = false,
        isUser = false,
        isCourier = true,
        errorMessage = null;

  const _AccountDestination.error(
    String message,
  )   : isAdmin = false,
        isUser = false,
        isCourier = false,
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
          child:
              SingleChildScrollView(
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
                      await FirebaseAuth
                          .instance
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
