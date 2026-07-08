class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String phone;
  final String foto;
  final int saldo;
  final int poin;
  final String member;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.phone,
    required this.foto,
    required this.saldo,
    required this.poin,
    required this.member,
  });

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

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"] ?? "",
      nama: map["nama"] ?? "",
      email: map["email"] ?? "",
      phone: map["phone"] ?? "",
      foto: map["foto"] ?? "",
      saldo: map["saldo"] ?? 0,
      poin: map["poin"] ?? 0,
      member: map["member"] ?? "Silver",
    );
  }
}
