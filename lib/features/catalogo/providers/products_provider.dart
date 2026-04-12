import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:granos_la_tradicion/core/config/app_config.dart';
import '../models/product_model.dart';

class ProductsProvider extends ChangeNotifier {
  final String baseUrl = "${AppConfig.apiBaseUrl}/api";

  List<Product> _products = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Product> get products =>
      _products.where((p) => p.activo).toList();

  List<Product> get allProducts => _products;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/products/active"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _products =
            data.map((e) => Product.fromJson(e)).toList();
      } else {
        debugPrint("Error loadProducts: ${response.body}");
        _products = [];
      }
    } catch (e) {
      debugPrint("Exception loadProducts: $e");
      _products = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse("$baseUrl/products"),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _products =
            data.map((e) => Product.fromJson(e)).toList();
      } else {
        debugPrint("Error loadAllProducts: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception loadAllProducts: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse("$baseUrl/products"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 201 ||
          response.statusCode == 200) {
        await loadAllProducts();
      } else {
        debugPrint("Error addProduct: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception addProduct: $e");
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.put(
        Uri.parse("$baseUrl/products/${product.id}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 200) {
        await loadAllProducts();
      } else {
        debugPrint("Error updateProduct: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception updateProduct: $e");
    }
  }

  Future<void> toggleActive(int productId) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.patch(
        Uri.parse("$baseUrl/products/$productId/toggle"),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        await loadAllProducts();
      } else {
        debugPrint("Error toggleActive: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception toggleActive: $e");
    }
  }

  Future<void> decreaseStock(int productId, int quantity) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.patch(
        Uri.parse("$baseUrl/products/$productId/decrease"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"quantity": quantity}),
      );

      if (response.statusCode == 200) {
        await loadProducts();
      } else {
        debugPrint("Error decreaseStock: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception decreaseStock: $e");
    }
  }

  Future<void> increaseStock(int productId, int quantity) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.patch(
        Uri.parse("$baseUrl/products/$productId/increase"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"quantity": quantity}),
      );

      if (response.statusCode == 200) {
        await loadProducts();
      } else {
        debugPrint("Error increaseStock: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception increaseStock: $e");
    }
  }
}