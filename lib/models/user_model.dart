import 'dart:convert';

class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String phone;
  final String foto;
  final int balance;
  final int poin;
  final String member;

  const UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.phone,
    required this.foto,
    required this.balance,
    required this.poin,
    required this.member,
  });

  // ============================================================
  // COMPATIBILITY
  // ============================================================

  // Dipertahankan agar kode lama yang menggunakan .saldo
  // tidak langsung rusak.
  int get saldo => balance;


  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'phone': phone,
      'foto': foto,
      'balance': balance,
      'poin': poin,
      'member': member,
    };
  }


  // ============================================================
  // TO JSON
  // ============================================================

  String toJson() => json.encode(toMap());


  // ============================================================
  // FROM MAP
  // ============================================================

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final dynamic rawBalance =
        map['balance'] ?? map['saldo'] ?? 0;

    final dynamic rawPoin =
        map['poin'] ?? 0;

    return UserModel(
      uid: (map['uid'] ?? '').toString(),
      nama: (map['nama'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      foto: (map['fotoProfil'] ?? map['foto'] ?? '').toString(),

      balance: rawBalance is num
          ? rawBalance.toInt()
          : int.tryParse(rawBalance.toString()) ?? 0,

      poin: rawPoin is num
          ? rawPoin.toInt()
          : int.tryParse(rawPoin.toString()) ?? 0,

      member: (map['member'] ?? 'Silver').toString(),
    );
  }


  // ============================================================
  // FROM JSON
  // ============================================================

  factory UserModel.fromJson(String source) {
    return UserModel.fromMap(
      json.decode(source) as Map<String, dynamic>,
    );
  }


  // ============================================================
  // COPY WITH
  // ============================================================

  UserModel copyWith({
    String? uid,
    String? nama,
    String? email,
    String? phone,
    String? foto,
    int? balance,
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
      balance: balance ?? saldo ?? this.balance,
      poin: poin ?? this.poin,
      member: member ?? this.member,
    );
  }


  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'UserModel('
        'uid: $uid, '
        'nama: $nama, '
        'balance: $balance, '
        'member: $member'
        ')';
  }
}
