import 'dart:convert';

class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String phone;
  final String foto;
  final int saldo;
  final int poin;
  final String member;

  const UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.phone,
    required this.foto,
    required this.saldo,
    required this.poin,
    required this.member,
  });

  // ===================================================
  // 1. SERIALISASI DATA (TO MAP / TO JSON)
  // ===================================================
  /// Mengonversi objek [UserModel] menjadi format Map/JSON untuk penyimpanan Firestore
  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "nama": nama,
      "email": email,
      "phone": phone,
      "foto": foto,
      "saldo": saldo,
      "poin": poin,
      "member": member,
    };
  }

  /// Mengonversi objek [UserModel] langsung menjadi format JSON String
  String toJson() => json.encode(toMap());

  // ===================================================
  // 2. DESERIALISASI DATA (FROM MAP / FROM JSON)
  // ===================================================
  /// Membuat objek [UserModel] secara aman dari dokumen Map/JSON Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: (map["uid"] ?? "").toString(),
      nama: (map["nama"] ?? "").toString(),
      email: (map["email"] ?? "").toString(),
      phone: (map["phone"] ?? "").toString(),
      foto: (map["foto"] ?? "").toString(),
      // DIKOREKSI: Mengamankan tipe data int dari potensi crash desimal/double/num dari database
      saldo: int.tryParse(map["saldo"].toString()) ?? 0,
      poin: int.tryParse(map["poin"].toString()) ?? 0,
      member: (map["member"] ?? "Silver").toString(),
    );
  }

  /// Membuat objek [UserModel] dari JSON String
  factory UserModel.fromJson(String source) => 
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // ===================================================
  // 3. COPY WITH HELPER (STATE-MANAGEMENT FRIENDLY)
  // ===================================================
  /// Memudahkan modifikasi parameter profil user secara independen tanpa merusak data asli
  UserModel copyWith({
    String? uid,
    String? nama,
    String? email,
    String? phone,
    String? foto,
    int? saldo,
    int? poin,
    String? member,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      foto: foto ?? this.foto,
      saldo: saldo ?? this.saldo,
      poin: poin ?? this.poin,
      member: member ?? this.member,
    );
  }

  // ===================================================
  // 4. TO STRING OVERRIDE (FOR LUXURY DEBUGGING)
  // ===================================================
  @override
  String toString() {
    return 'UserModel(uid: $uid, nama: $nama, saldo: $saldo, member: $member)';
  }
}
