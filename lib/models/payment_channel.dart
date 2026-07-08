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

  factory PaymentChannel.fromJson(Map<String, dynamic> json) {
    return PaymentChannel(
      code: json["code"] ?? "",
      name: json["name"] ?? "",
      group: json["group"] ?? "",
      icon: json["icon_url"] ?? "",
      fee: json["total_fee"] ?? 0,
    );
  }
}
