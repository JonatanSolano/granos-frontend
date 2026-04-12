import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:granos_la_tradicion/core/config/app_config.dart';
import '../models/tse_ciudadano_model.dart';

class TseLookupResult {
  final bool success;
  final String message;
  final TseCiudadanoModel? ciudadano;

  const TseLookupResult({
    required this.success,
    required this.message,
    required this.ciudadano,
  });
}

class TseService {
  String get baseUrl => AppConfig.apiBaseUrl;

  String limpiarCedula(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '').trim();
  }

  Future<TseLookupResult> consultarCedula(String cedula) async {
    final cedulaLimpia = limpiarCedula(cedula);

    if (cedulaLimpia.isEmpty) {
      return const TseLookupResult(
        success: false,
        message: "La cédula es obligatoria.",
        ciudadano: null,
      );
    }

    if (cedulaLimpia.length < 6) {
      return const TseLookupResult(
        success: false,
        message: "La cédula ingresada no es válida.",
        ciudadano: null,
      );
    }

    try {
      final uri = Uri.parse(
        "$baseUrl/api/integrations/tse/cedula/$cedulaLimpia",
      );

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
      );

      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = null;
      }

      if (response.statusCode == 200 && body != null) {
        final data = body["data"] as Map<String, dynamic>?;

        return TseLookupResult(
          success: true,
          message: body["message"]?.toString() ?? "Ciudadano encontrado.",
          ciudadano:
              data != null ? TseCiudadanoModel.fromJson(data) : null,
        );
      }

      if (response.statusCode == 404) {
        return TseLookupResult(
          success: false,
          message: body?["message"]?.toString() ??
              "Ciudadano no encontrado en TSE simulado.",
          ciudadano: null,
        );
      }

      return TseLookupResult(
        success: false,
        message: body?["message"]?.toString() ??
            "No fue posible consultar la cédula en el TSE simulado.",
        ciudadano: null,
      );
    } catch (_) {
      return const TseLookupResult(
        success: false,
        message: "Error de conexión consultando el TSE simulado.",
        ciudadano: null,
      );
    }
  }
}