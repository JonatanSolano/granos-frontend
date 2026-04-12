import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../../catalogo/models/product_model.dart';

class CartProvider extends ChangeNotifier {

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  double get total =>
      _items.fold(
        0,
        (sum, item) =>
            sum + (item.product.precio * item.quantity),
      );

  CartProvider() {
    _loadCart();
  }

  /// 🔵 AGREGAR PRODUCTO (CON CONTROL DE STOCK)
  bool addProduct(Product product) {

    final index = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index >= 0) {

      /// 🔒 Verificar stock antes de aumentar
      if (_items[index].quantity >= product.stock) {
        return false;
      }

      _items[index].quantity++;

    } else {

      /// 🔒 Si stock es 0 no permitir agregar
      if (product.stock <= 0) {
        return false;
      }

      _items.add(CartItem(product: product));
    }

    _normalizeStock(product.id);

    _saveCart();
    notifyListeners();
    return true;
  }

  /// 🔼 AUMENTAR CANTIDAD
  bool increaseQuantity(int productId) {

    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (index >= 0) {

      final product = _items[index].product;

      /// 🔒 Validar stock
      if (_items[index].quantity >= product.stock) {
        return false;
      }

      _items[index].quantity++;

      _saveCart();
      notifyListeners();
      return true;
    }

    return false;
  }

  /// 🔽 DISMINUIR CANTIDAD
  void decreaseQuantity(int productId) {

    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (index >= 0) {

      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }

      _saveCart();
      notifyListeners();
    }
  }

  /// ❌ ELIMINAR PRODUCTO
  void removeProduct(int productId) {

    _items.removeWhere(
      (item) => item.product.id == productId,
    );

    _saveCart();
    notifyListeners();
  }

  /// 🧹 LIMPIAR CARRITO
  void clear() {

    if (_items.isEmpty) return;

    _items.clear();

    _saveCart();
    notifyListeners();
  }

  /// 🔒 Normaliza cantidades si el stock cambió
  void _normalizeStock(int productId) {

    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (index >= 0) {

      final product = _items[index].product;

      if (_items[index].quantity > product.stock) {
        _items[index].quantity = product.stock;
      }

      if (product.stock == 0) {
        _items.removeAt(index);
      }
    }
  }

  /// 💾 GUARDAR EN SHARED PREFERENCES
  Future<void> _saveCart() async {

    final prefs = await SharedPreferences.getInstance();

    final cartJson =
        _items.map((item) => item.toJson()).toList();

    await prefs.setString('cart', jsonEncode(cartJson));
  }

  /// 🔄 CARGAR DESDE SHARED PREFERENCES
  Future<void> _loadCart() async {

    try {

      final prefs = await SharedPreferences.getInstance();

      final cartString = prefs.getString('cart');

      if (cartString != null) {

        final List decoded = jsonDecode(cartString);

        _items.clear();

        _items.addAll(
          decoded
              .map((item) => CartItem.fromJson(item))
              .toList(),
        );

        notifyListeners();
      }

    } catch (e) {

      debugPrint("Cart load error: $e");

      _items.clear();
    }
  }
}