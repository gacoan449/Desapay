class PaymentChannel {
  final String code;
  final String name;
  final String group;
  final String icon;
  final int fee;

  PaymentChannel({
    required this.code,
    required this.name,
    required this.group,
    required this.icon,
    required this.fee,
  });

  // ===================================================
  // 1. FACTORY FROM JSON (SAFE TYPE-CASTING COMPLIANT)
  // ===================================================
  factory PaymentChannel.fromJson(Map<String, dynamic> json) {
    return PaymentChannel(
      code: (json["code"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      group: (json["group"] ?? "").toString(),
      icon: (json["icon_url"] ?? "").toString(),
      // DIKOREKSI: Mengamankan tipe data int dari potensi crash double/string dari API Tripay
      fee: int.tryParse(json["total_fee"].toString()) ?? 0,
    );
  }

  // ===================================================
  // 2. TO JSON (UNTUK LOCAL CACHING OFFLINE)
  // ===================================================
  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "name": name,
      "group": group,
      "icon_url": icon,
      "total_fee": fee,
    };
  }

  // ===================================================
  // 3. COPY WITH HELPER (STATE-MANAGEMENT FRIENDLY)
  // ===================================================
  PaymentChannel copyWith({
    String? code,
    String? name,
    String? group,
    String? icon,
    int? fee,
  }) {
    return PaymentChannel(
      code: code ?? this.code,
      name: name ?? this.name,
      group: group ?? this.group,
      icon: icon ?? this.icon,
      fee: fee ?? this.fee,
    );
  }

  // ===================================================
  // 4. TO STRING OVERRIDE (FOR LUXURY DEBUGGING)
  // ===================================================
  @override
  String toString() {
    return 'PaymentChannel(code: $code, name: $name, group: $group, fee: $fee)';
  }
}
