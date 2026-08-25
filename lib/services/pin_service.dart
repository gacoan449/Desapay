import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// ============================================================
/// PIN SERVICE DESAPAY
/// ============================================================
///
/// Fungsi:
/// - Membuat PIN transaksi 6 digit
/// - Mengubah PIN transaksi
/// - Memverifikasi PIN
/// - Mengecek apakah PIN sudah dibuat
///
/// PIN TIDAK disimpan sebagai teks biasa.
/// Yang disimpan di Firestore adalah hash SHA-256.
/// ============================================================

class PinService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  User? get _currentUser => _auth.currentUser;

  // ============================================================
  // HASH PIN
  // ============================================================
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ============================================================
  // VALIDASI FORMAT PIN
  // ============================================================
  bool _isValidPin(String pin) {
    return RegExp(r'^\d{6}$').hasMatch(pin);
  }

  // ============================================================
  // CEK USER
  // ============================================================
  String? _getUid() {
    return _currentUser?.uid;
  }

  // ============================================================
  // CEK APAKAH USER SUDAH MEMILIKI PIN
  // ============================================================
  Future<bool> hasPin() async {
    final uid = _getUid();

    if (uid == null) {
      return false;
    }

    final snapshot = await _users.doc(uid).get();

    if (!snapshot.exists) {
      return false;
    }

    final data = snapshot.data();

    final pinHash = data?['pinHash'];

    return pinHash != null &&
        pinHash.toString().isNotEmpty;
  }

  // ============================================================
  // BUAT PIN BARU
  // ============================================================
  Future<String?> createPin({
    required String pin,
    required String confirmation,
  }) async {
    final uid = _getUid();

    if (uid == null) {
      return "Sesi akun tidak ditemukan. Silakan login kembali.";
    }

    if (!_isValidPin(pin)) {
      return "PIN harus terdiri dari 6 digit angka.";
    }

    if (pin != confirmation) {
      return "Konfirmasi PIN tidak cocok.";
    }

    // Tidak mengizinkan PIN yang terlalu mudah ditebak.
    if (_isWeakPin(pin)) {
      return "PIN terlalu mudah ditebak. Gunakan kombinasi angka yang lebih aman.";
    }

    final alreadyExists = await hasPin();

    if (alreadyExists) {
      return "PIN transaksi sudah tersedia. Gunakan menu ubah PIN.";
    }

    final pinHash = _hashPin(pin);

    await _users.doc(uid).set(
      {
        'pinHash': pinHash,
        'pinCreatedAt': FieldValue.serverTimestamp(),
        'pinUpdatedAt': FieldValue.serverTimestamp(),
        'pinFailedAttempts': 0,
        'pinLockedUntil': null,
      },
      SetOptions(merge: true),
    );

    return null;
  }

  // ============================================================
  // UBAH PIN
  // ============================================================
  Future<String?> changePin({
    required String oldPin,
    required String newPin,
    required String confirmation,
  }) async {
    final uid = _getUid();

    if (uid == null) {
      return "Sesi akun tidak ditemukan. Silakan login kembali.";
    }

    if (!_isValidPin(oldPin)) {
      return "PIN lama harus terdiri dari 6 digit angka.";
    }

    if (!_isValidPin(newPin)) {
      return "PIN baru harus terdiri dari 6 digit angka.";
    }

    if (newPin != confirmation) {
      return "Konfirmasi PIN baru tidak cocok.";
    }

    if (oldPin == newPin) {
      return "PIN baru harus berbeda dari PIN lama.";
    }

    if (_isWeakPin(newPin)) {
      return "PIN terlalu mudah ditebak. Gunakan kombinasi angka yang lebih aman.";
    }

    // ==========================================================
    // AMBIL DATA PIN
    // ==========================================================
    final snapshot = await _users.doc(uid).get();

    if (!snapshot.exists) {
      return "Data akun tidak ditemukan.";
    }

    final data = snapshot.data();

    final storedHash = data?['pinHash']?.toString();

    if (storedHash == null || storedHash.isEmpty) {
      return "Anda belum memiliki PIN transaksi.";
    }

    // ==========================================================
    // CEK STATUS LOCK
    // ==========================================================
    final lockedUntil = data?['pinLockedUntil'];

    if (lockedUntil is Timestamp) {
      if (lockedUntil.toDate().isAfter(DateTime.now())) {
        final remaining =
            lockedUntil.toDate().difference(DateTime.now());

        final minutes = remaining.inMinutes + 1;

        return "PIN terkunci sementara. Coba lagi dalam $minutes menit.";
      }
    }

    // ==========================================================
    // VERIFIKASI PIN LAMA
    // ==========================================================
    final oldPinHash = _hashPin(oldPin);

    if (oldPinHash != storedHash) {
      await _recordFailedAttempt(uid, data);
      return "PIN lama salah.";
    }

    // ==========================================================
    // PIN BENAR → RESET PERCOBAAN
    // ==========================================================
    final newPinHash = _hashPin(newPin);

    await _users.doc(uid).set(
      {
        'pinHash': newPinHash,
        'pinUpdatedAt': FieldValue.serverTimestamp(),
        'pinFailedAttempts': 0,
        'pinLockedUntil': null,
      },
      SetOptions(merge: true),
    );

    return null;
  }

  // ============================================================
  // VERIFIKASI PIN TRANSAKSI
  // ============================================================
  Future<bool> verifyPin(String pin) async {
    final uid = _getUid();

    if (uid == null || !_isValidPin(pin)) {
      return false;
    }

    final snapshot = await _users.doc(uid).get();

    if (!snapshot.exists) {
      return false;
    }

    final data = snapshot.data();

    final storedHash = data?['pinHash']?.toString();

    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }

    // ==========================================================
    // CEK LOCK
    // ==========================================================
    final lockedUntil = data?['pinLockedUntil'];

    if (lockedUntil is Timestamp) {
      if (lockedUntil.toDate().isAfter(DateTime.now())) {
        return false;
      }
    }

    final inputHash = _hashPin(pin);

    if (inputHash == storedHash) {
      await _users.doc(uid).set(
        {
          'pinFailedAttempts': 0,
          'pinLockedUntil': null,
        },
        SetOptions(merge: true),
      );

      return true;
    }

    await _recordFailedAttempt(uid, data);

    return false;
  }

  // ============================================================
  // CATAT PERCOBAAN PIN SALAH
  // ============================================================
  Future<void> _recordFailedAttempt(
    String uid,
    Map<String, dynamic>? data,
  ) async {
    int attempts = 0;

    final currentAttempts = data?['pinFailedAttempts'];

    if (currentAttempts is int) {
      attempts = currentAttempts;
    } else if (currentAttempts is num) {
      attempts = currentAttempts.toInt();
    }

    attempts++;

    // Setelah 5 kali salah → kunci 15 menit.
    if (attempts >= 5) {
      await _users.doc(uid).set(
        {
          'pinFailedAttempts': 0,
          'pinLockedUntil': Timestamp.fromDate(
            DateTime.now().add(
              const Duration(minutes: 15),
            ),
          ),
        },
        SetOptions(merge: true),
      );

      return;
    }

    await _users.doc(uid).set(
      {
        'pinFailedAttempts': attempts,
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // PIN TERLALU MUDAH
  // ============================================================
  bool _isWeakPin(String pin) {
    // 000000, 111111, 222222, dst.
    if (RegExp(r'^(\d)\1{5}$').hasMatch(pin)) {
      return true;
    }

    // 123456
    if (pin == '123456') {
      return true;
    }

    // 654321
    if (pin == '654321') {
      return true;
    }

    return false;
  }
}
