import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:granos_la_tradicion/core/config/app_config.dart';
import '../models/ubicacion_model.dart';

class UbicacionService {
  final String baseUrl = "${AppConfig.apiBaseUrl}/api";

  List<UbicacionModel> _parseList(String body) {
    final decoded = jsonDecode(body);

    if (decoded is List) {
      return decoded
          .map((e) => UbicacionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

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

  Future<List<UbicacionModel>> getPaises() async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ubicaciones/paises"),
          headers: {"Content-Type": "application/json"},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return _parseList(response.body);
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<List<UbicacionModel>> getHijos(int idPadre) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ubicaciones/hijos/$idPadre"),
          headers: {"Content-Type": "application/json"},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return _parseList(response.body);
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<List<UbicacionModel>> getRuta(int idUbicacion) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/ubicaciones/ruta/$idUbicacion"),
          headers: {"Content-Type": "application/json"},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List path = decoded["path"] ?? [];

      return path
          .map((e) => UbicacionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_extractErrorMessage(response));
  }
}