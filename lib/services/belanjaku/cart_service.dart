import '../../models/belanjaku/cart_item_model.dart';
import '../../models/belanjaku/product_model.dart';
class BelanjakuCartService {
  BelanjakuCartService._();
  static final instance = BelanjakuCartService._();
  final Map<String, BelanjakuCartItem> _items = {};
  List<BelanjakuCartItem> get items => List.unmodifiable(_items.values);
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  int get total => _items.values.fold(0, (sum, item) => sum + item.lineTotal);
  void add(BelanjakuProduct p) { if (!p.isAvailable) throw StateError('Produk belum tersedia'); final old = _items[p.id]; _items[p.id] = BelanjakuCartItem(product: p, quantity: (old?.quantity ?? 0) + 1); }
  void setQuantity(String id, int quantity) { if (quantity <= 0) { _items.remove(id); return; } final old = _items[id]; if (old != null) _items[id] = old.copyWith(quantity: quantity); }
  void clear() => _items.clear();
}
