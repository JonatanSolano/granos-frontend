import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:granos_la_tradicion/core/config/app_config.dart';
import 'package:granos_la_tradicion/core/models/payment_response_model.dart';
import 'package:granos_la_tradicion/core/services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  final String baseUrl = "${AppConfig.apiBaseUrl}/api";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  PaymentResponseModel? _paymentResponse;
  PaymentResponseModel? get paymentResponse => _paymentResponse;

  bool _cardValidated = false;
  bool get cardValidated => _cardValidated;

  bool _loadingTestData = false;
  bool get loadingTestData => _loadingTestData;

  String? _testDataError;
  String? get testDataError => _testDataError;

  List<Map<String, dynamic>> _tarjetasPrueba = [];
  List<Map<String, dynamic>> get tarjetasPrueba => _tarjetasPrueba;

  List<Map<String, dynamic>> _sinpePrueba = [];
  List<Map<String, dynamic>> get sinpePrueba => _sinpePrueba;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == "true" || v == "1" || v == "activa" || v == "activo";
    }
    return false;
  }

  Map<String, dynamic> _normalizeTarjeta(Map<String, dynamic> row) {
    return {
      ...row,
      "activo": _toBool(row["activo"]),
    };
  }

  Map<String, dynamic> _normalizeSinpe(Map<String, dynamic> row) {
    return {
      ...row,
      "activo": _toBool(row["activo"]),
    };
  }

  void clearState() {
    _isLoading = false;
    _errorMessage = null;
    _successMessage = null;
    _paymentResponse = null;
    _cardValidated = false;
    notifyListeners();
  }

  Future<void> loadPaymentTestData() async {
    try {
      _loadingTestData = true;
      _testDataError = null;
      notifyListeners();

      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _tarjetasPrueba = [];
        _sinpePrueba = [];
        _testDataError = "No hay sesión activa para cargar datos de prueba.";
        notifyListeners();
        return;
      }

      final tarjetasResponse = await http.get(
        Uri.parse("$baseUrl/bank/test-cards"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final sinpeResponse = await http.get(
        Uri.parse("$baseUrl/bank/test-sinpe"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final tarjetasDecoded = _safeDecode(tarjetasResponse.body);
      final sinpeDecoded = _safeDecode(sinpeResponse.body);

      if (tarjetasResponse.statusCode == 200 &&
          tarjetasDecoded["ok"] == true &&
          tarjetasDecoded["tarjetas"] is List) {
        _tarjetasPrueba = (tarjetasDecoded["tarjetas"] as List)
            .map((e) => _normalizeTarjeta(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        _tarjetasPrueba = [];
      }

      if (sinpeResponse.statusCode == 200 &&
          sinpeDecoded["ok"] == true &&
          sinpeDecoded["cuentas"] is List) {
        _sinpePrueba = (sinpeDecoded["cuentas"] as List)
            .map((e) => _normalizeSinpe(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        _sinpePrueba = [];
      }

      if (_tarjetasPrueba.isEmpty && _sinpePrueba.isEmpty) {
        final tarjetasError = tarjetasDecoded["mensaje"] ??
            tarjetasDecoded["message"] ??
            tarjetasDecoded["error"];

        final sinpeError = sinpeDecoded["mensaje"] ??
            sinpeDecoded["message"] ??
            sinpeDecoded["error"];

        _testDataError = tarjetasError?.toString() ??
            sinpeError?.toString() ??
            "No se pudieron cargar los datos de prueba.";
      } else {
        _testDataError = null;
      }
    } catch (e) {
      _tarjetasPrueba = [];
      _sinpePrueba = [];
      _testDataError = "Error obteniendo datos de prueba de pago.";
    } finally {
      _loadingTestData = false;
      notifyListeners();
    }
  }

  Future<bool> validateCard({
    required String numeroTarjeta,
    required String nombreTitular,
    required String fechaExpiracion,
    required String cvv,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      final response = await _paymentService.validateCard(
        numeroTarjeta: numeroTarjeta,
        nombreTitular: nombreTitular,
        fechaExpiracion: fechaExpiracion,
        cvv: cvv,
      );

      _paymentResponse = response;
      _cardValidated = response.ok;

      if (response.ok) {
        _successMessage = response.mensaje;
      } else {
        _errorMessage = response.error ?? response.detail ?? response.mensaje;
      }

      return response.ok;
    } catch (e) {
      _errorMessage = "Error al validar la tarjeta: $e";
      _cardValidated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> processPayment({
    required int orderId,
    required String metodoPago,
    required String numeroTarjeta,
    required String nombreTitular,
    required String fechaExpiracion,
    required String cvv,
    required double monto,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      final response = await _paymentService.processPayment(
        orderId: orderId,
        metodoPago: metodoPago,
        numeroTarjeta: numeroTarjeta,
        nombreTitular: nombreTitular,
        fechaExpiracion: fechaExpiracion,
        cvv: cvv,
        monto: monto,
      );

      _paymentResponse = response;

      if (response.ok) {
        _successMessage = response.mensaje;
        return true;
      } else {
        _errorMessage = response.error ?? response.detail ?? response.mensaje;
        return false;
      }
    } catch (e) {
      _errorMessage = "Error al procesar el pago: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'message': decoded.toString()};
    } catch (_) {
      return <String, dynamic>{'message': body};
    }
  }
}