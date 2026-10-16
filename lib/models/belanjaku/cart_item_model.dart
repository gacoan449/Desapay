import 'product_model.dart';
class BelanjakuCartItem {
  const BelanjakuCartItem({required this.product, required this.quantity});
  final BelanjakuProduct product;
  final int quantity;
  int get lineTotal => product.price * quantity;
  BelanjakuCartItem copyWith({int? quantity}) => BelanjakuCartItem(product: product, quantity: quantity ?? this.quantity);
}
