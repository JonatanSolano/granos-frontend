import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:granos_la_tradicion/core/config/app_config.dart';

class AdminService {
  final String baseUrl = "${AppConfig.apiBaseUrl}/api";

  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        if (decoded["message"] != null) {
          return decoded["message"].toString();
        }

        if (decoded["error"] != null) {
          return decoded["error"].toString();
        }
      }
    } catch (_) {}

    return "Error ${response.statusCode}";
  }

  Future<Map<String, dynamic>> getDashboard(String token) async {
    if (token.isEmpty) {
      throw Exception("Token inválido");
    }

    final response = await http
        .get(
          Uri.parse("$baseUrl/admin/dashboard"),
          headers: {
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<List<dynamic>> getSalesChart(String token) async {
    if (token.isEmpty) {
      throw Exception("Token inválido");
    }

    final response = await http
        .get(
          Uri.parse("$baseUrl/admin/sales-chart"),
          headers: {
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<List<dynamic>> getLowStock(String token) async {
    if (token.isEmpty) {
      throw Exception("Token inválido");
    }

    final response = await http
        .get(
          Uri.parse("$baseUrl/admin/low-stock"),
          headers: {
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<List<dynamic>> getUsers(String token) async {
    if (token.isEmpty) {
      throw Exception("Token inválido");
    }

    final response = await http
        .get(
          Uri.parse("$baseUrl/users"),
          headers: {
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      return [];
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<void> blockUser(String token, int id, String status) async {
    final response = await http
        .put(
          Uri.parse("$baseUrl/users/$id/status"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "status": status,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<void> deleteUser(String token, int id) async {
    final response = await http
        .delete(
          Uri.parse("$baseUrl/users/$id"),
          headers: {
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<void> updateUser({
    required String token,
    required int id,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String status,
    required int ubicacionId,
  }) async {
    final response = await http
        .put(
          Uri.parse("$baseUrl/users/$id"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "name": name,
            "email": email,
            "phone": phone,
            "address": address,
            "status": status,
            "ubicacionId": ubicacionId,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }
}