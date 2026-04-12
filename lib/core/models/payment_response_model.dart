class BankPaymentInfo {
  final bool ok;
  final String mensaje;
  final String? referenciaBanco;
  final String? tipoTarjeta;
  final double? saldoRestante;
  final double? limiteDisponible;

  BankPaymentInfo({
    required this.ok,
    required this.mensaje,
    this.referenciaBanco,
    this.tipoTarjeta,
    this.saldoRestante,
    this.limiteDisponible,
  });

  factory BankPaymentInfo.fromJson(Map<String, dynamic> json) {
    return BankPaymentInfo(
      ok: json['ok'] == true,
      mensaje: (json['mensaje'] ?? '').toString(),
      referenciaBanco: json['referenciaBanco']?.toString(),
      tipoTarjeta: json['tipoTarjeta']?.toString(),
      saldoRestante: _toDouble(json['saldoRestante']),
      limiteDisponible: _toDouble(json['limiteDisponible']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'mensaje': mensaje,
      'referenciaBanco': referenciaBanco,
      'tipoTarjeta': tipoTarjeta,
      'saldoRestante': saldoRestante,
      'limiteDisponible': limiteDisponible,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class PaymentResponseModel {
  final bool ok;
  final String mensaje;
  final int? paymentId;
  final int? orderId;
  final String? paymentStatus;
  final double? monto;
  final String? estadoPedidoActualizado;
  final BankPaymentInfo? banco;
  final String? detail;
  final String? error;

  PaymentResponseModel({
    required this.ok,
    required this.mensaje,
    this.paymentId,
    this.orderId,
    this.paymentStatus,
    this.monto,
    this.estadoPedidoActualizado,
    this.banco,
    this.detail,
    this.error,
  });

  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      ok: json['ok'] == true,
      mensaje: (json['mensaje'] ?? json['message'] ?? '').toString(),
      paymentId: _toInt(json['paymentId']),
      orderId: _toInt(json['orderId']),
      paymentStatus: json['paymentStatus']?.toString(),
      monto: _toDouble(json['monto']),
      estadoPedidoActualizado: json['estadoPedidoActualizado']?.toString(),
      banco: json['banco'] is Map<String, dynamic>
          ? BankPaymentInfo.fromJson(json['banco'] as Map<String, dynamic>)
          : null,
      detail: json['detail']?.toString(),
      error: json['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'mensaje': mensaje,
      'paymentId': paymentId,
      'orderId': orderId,
      'paymentStatus': paymentStatus,
      'monto': monto,
      'estadoPedidoActualizado': estadoPedidoActualizado,
      'banco': banco?.toJson(),
      'detail': detail,
      'error': error,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}