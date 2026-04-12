import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment_response_model.dart';

class PaymentService {
  PaymentService();

  // Cambia esta URL si pruebas desde emulador Android físico o dispositivo real.
  // Web / desktop local:
  final String baseUrl = "http://127.0.0.1:4000/api";

  Future<PaymentResponseModel> processPayment({
    required int orderId,
    required String metodoPago,
    required String numeroTarjeta,
    required String nombreTitular,
    required String fechaExpiracion,
    required String cvv,
    required double monto,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        return PaymentResponseModel(
          ok: false,
          mensaje: "No hay sesión activa",
          error: "Token no encontrado",
        );
      }

      final uri = Uri.parse("$baseUrl/payments/process");

      final body = {
        "orderId": orderId,
        "metodoPago": metodoPago,
        "numeroTarjeta": numeroTarjeta.trim(),
        "nombreTitular": nombreTitular.trim(),
        "fechaExpiracion": fechaExpiracion.trim(),
        "cvv": cvv.trim(),
        "monto": monto,
      };

      final response = await http
          .post(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> data = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PaymentResponseModel.fromJson(data);
      }

      return PaymentResponseModel(
        ok: false,
        mensaje: _extractMessage(data, fallback: "No se pudo procesar el pago"),
        detail: data['detail']?.toString(),
        error: data['error']?.toString(),
        paymentId: _toInt(data['paymentId']),
        orderId: _toInt(data['orderId']),
        paymentStatus: data['paymentStatus']?.toString(),
        monto: _toDouble(data['monto']),
        estadoPedidoActualizado: data['estadoPedidoActualizado']?.toString(),
        banco: data['banco'] is Map<String, dynamic>
            ? BankPaymentInfo.fromJson(data['banco'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      return PaymentResponseModel(
        ok: false,
        mensaje: "Error de conexión con el servidor",
        error: e.toString(),
      );
    }
  }

  Future<PaymentResponseModel> validateCard({
    required String numeroTarjeta,
    required String nombreTitular,
    required String fechaExpiracion,
    required String cvv,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/bank/validate-card");

      final body = {
        "numeroTarjeta": numeroTarjeta.trim(),
        "nombreTitular": nombreTitular.trim(),
        "fechaExpiracion": fechaExpiracion.trim(),
        "cvv": cvv.trim(),
      };

      final response = await http
          .post(
            uri,
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PaymentResponseModel(
          ok: data['ok'] == true,
          mensaje: _extractMessage(data, fallback: "Tarjeta válida"),
          banco: data['tarjeta'] is Map<String, dynamic>
              ? BankPaymentInfo(
                  ok: true,
                  mensaje: _extractMessage(data, fallback: "Tarjeta válida"),
                  tipoTarjeta: data['tarjeta']['tipoTarjeta']?.toString(),
                )
              : null,
        );
      }

      return PaymentResponseModel(
        ok: false,
        mensaje: _extractMessage(data, fallback: "No se pudo validar la tarjeta"),
        error: data['error']?.toString(),
        detail: data['detail']?.toString(),
      );
    } catch (e) {
      return PaymentResponseModel(
        ok: false,
        mensaje: "Error de conexión al validar la tarjeta",
        error: e.toString(),
      );
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

  String _extractMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    return data['mensaje']?.toString() ??
        data['message']?.toString() ??
        data['error']?.toString() ??
        fallback;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}