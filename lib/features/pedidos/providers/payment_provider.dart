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

      final response = await http.get(
        Uri.parse("$baseUrl/payments/test-data"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          decoded is Map<String, dynamic> &&
          decoded["ok"] == true &&
          decoded["data"] is Map<String, dynamic>) {
        final data = decoded["data"] as Map<String, dynamic>;

        final tarjetas = data["tarjetas"];
        final sinpe = data["sinpe"];

        _tarjetasPrueba = tarjetas is List
            ? tarjetas
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : [];

        _sinpePrueba = sinpe is List
            ? sinpe
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : [];

        _testDataError = null;
      } else {
        _tarjetasPrueba = [];
        _sinpePrueba = [];
        _testDataError = decoded is Map<String, dynamic>
            ? (decoded["mensaje"] ??
                decoded["message"] ??
                decoded["error"] ??
                "No se pudieron cargar los datos de prueba.")
            : "No se pudieron cargar los datos de prueba.";
      }
    } catch (e) {
      _tarjetasPrueba = [];
      _sinpePrueba = [];
      _testDataError = "Error cargando datos de prueba: $e";
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
}