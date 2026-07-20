import 'package:flutter/foundation.dart';
import 'package:Waqafer/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}

/// Simple in-memory cart service using ChangeNotifier.
/// Used as a singleton via [CartService.instance].
class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get totalItems =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  int get distinctItems => _items.length;

  bool get isEmpty => _items.isEmpty;

  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  double get shipping => isEmpty ? 0.0 : 6.00;

  double get total => subtotal + shipping;

  void addProduct(Product product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += quantity;
    } else {
      _items[product.id] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  void increase(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity += 1;
      notifyListeners();
    }
  }

  void decrease(String productId) {
    if (_items.containsKey(productId)) {
      final item = _items[productId]!;
      if (item.quantity > 1) {
        item.quantity -= 1;
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
