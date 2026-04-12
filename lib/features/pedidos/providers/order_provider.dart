import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:granos_la_tradicion/core/config/app_config.dart';
import 'package:granos_la_tradicion/features/carrito/providers/cart_provider.dart';
import 'package:granos_la_tradicion/features/pedidos/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final String baseUrl = "${AppConfig.apiBaseUrl}/api";

  final List<Order> _orders = [];
  List<Order> get orders => _orders;

  bool _loading = false;
  bool get loading => _loading;

  int get pendingCount =>
      _orders.where((o) => o.status == 'Pendiente').length;

  OrderProvider() {
    loadOrders();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Order? getOrderById(int orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshOrders() async {
    await loadOrders();
  }

  List<Order> _parseOrdersFromResponse(dynamic decoded) {
    if (decoded is List) {
      return decoded.map((e) => Order.fromJson(e)).toList();
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic possibleOrders =
          decoded['data'] ?? decoded['orders'] ?? decoded['pedido'] ?? decoded['result'];

      if (possibleOrders is List) {
        return possibleOrders.map((e) => Order.fromJson(e)).toList();
      }
    }

    return [];
  }

  Future<void> loadOrders() async {
    if (_loading) return;

    try {
      _loading = true;
      notifyListeners();

      final token = await _getToken();

      if (token == null) {
        _orders.clear();
        _loading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse("$baseUrl/orders"),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        _orders
          ..clear()
          ..addAll(_parseOrdersFromResponse(decoded));
      } else {
        debugPrint("Error loadOrders: ${response.body}");
        _orders.clear();
      }
    } catch (e) {
      debugPrint("Exception loadOrders: $e");
      _orders.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllOrders() async {
    if (_loading) return;

    try {
      _loading = true;
      notifyListeners();

      final token = await _getToken();

      if (token == null) {
        _orders.clear();
        _loading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse("$baseUrl/orders/admin/all"),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        _orders
          ..clear()
          ..addAll(_parseOrdersFromResponse(decoded));
      } else {
        debugPrint("Error loadAllOrders: ${response.body}");
        _orders.clear();
      }
    } catch (e) {
      debugPrint("Exception loadAllOrders: $e");
      _orders.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createOrder(
    CartProvider cart,
  ) async {
    if (cart.items.isEmpty) return;

    try {
      final token = await _getToken();
      if (token == null) return;

      final body = {
        "total": cart.total,
        "items": cart.items.map((item) => {
              "productId": item.product.id,
              "quantity": item.quantity,
              "price": item.product.precio,
            }).toList()
      };

      final response = await http.post(
        Uri.parse("$baseUrl/orders"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        cart.clear();
        await loadOrders();
      } else {
        debugPrint("Error createOrder: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception createOrder: $e");
    }
  }

  Future<void> updateOrderStatus(
    int orderId,
    String newStatus,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.put(
        Uri.parse("$baseUrl/orders/$orderId/status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"status": newStatus}),
      );

      if (response.statusCode == 200) {
        await loadAllOrders();
      } else {
        debugPrint("Error updateOrderStatus: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception updateOrderStatus: $e");
    }
  }

  Future<void> updateOrderDeliveryStatus(
    int orderId,
    String nuevoEstadoEntrega,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.put(
        Uri.parse("$baseUrl/orders/$orderId/delivery-status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"estado_entrega": nuevoEstadoEntrega}),
      );

      if (response.statusCode == 200) {
        await loadAllOrders();
      } else {
        debugPrint("Error updateOrderDeliveryStatus: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception updateOrderDeliveryStatus: $e");
    }
  }

  Future<void> cancelOrder(int orderId) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.put(
        Uri.parse("$baseUrl/orders/$orderId/status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"status": "Cancelado"}),
      );

      if (response.statusCode == 200) {
        await loadOrders();
      } else {
        debugPrint("Error cancelOrder: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception cancelOrder: $e");
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse("$baseUrl/orders/$orderId"),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        await loadAllOrders();
      } else {
        debugPrint("Error deleteOrder: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception deleteOrder: $e");
    }
  }
}