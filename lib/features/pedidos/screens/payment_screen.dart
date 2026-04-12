import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:granos_la_tradicion/core/config/app_config.dart';
import 'package:granos_la_tradicion/core/providers/auth_provider.dart';
import 'package:granos_la_tradicion/features/cliente/widgets/client_base_layout.dart';
import 'package:granos_la_tradicion/features/pedidos/models/order_model.dart';
import 'package:granos_la_tradicion/features/pedidos/providers/order_provider.dart';
import 'package:granos_la_tradicion/features/pedidos/providers/payment_provider.dart';
import 'package:granos_la_tradicion/features/pedidos/widgets/paypal_checkout_stub.dart'
    if (dart.library.html) 'package:granos_la_tradicion/features/pedidos/widgets/paypal_checkout_web.dart';

class PaymentScreen extends StatefulWidget {
  final Order order;

  const PaymentScreen({
    super.key,
    required this.order,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numeroTarjetaController;
  late final TextEditingController _nombreTitularController;
  late final TextEditingController _fechaExpiracionController;
  late final TextEditingController _cvvController;
  late final TextEditingController _telefonoSinpeController;

  bool _loadingTipoCambio = false;
  String? _tipoCambioError;
  double? _compra;
  double? _venta;
  String? _fechaTipoCambio;
  String? _fuenteTipoCambio;

  String _metodoPagoSeleccionado = "tarjeta";

  String? _paypalError;
  String? _paypalSuccess;

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool get _esTarjeta => _metodoPagoSeleccionado == "tarjeta";
  bool get _esSinpe => _metodoPagoSeleccionado == "sinpe";
  bool get _esPayPal => _metodoPagoSeleccionado == "paypal";

  bool get _paypalDisponibleEnEstaPlataforma => kIsWeb;

  @override
  void initState() {
    super.initState();

    _numeroTarjetaController = TextEditingController();
    _nombreTitularController = TextEditingController();
    _fechaExpiracionController = TextEditingController(text: "12/28");
    _cvvController = TextEditingController();
    _telefonoSinpeController = TextEditingController();

    Future.microtask(() {
      final paymentProvider = context.read<PaymentProvider>();
      paymentProvider.clearState();
      paymentProvider.loadPaymentTestData();
    });

    _cargarTipoCambio();
  }

  @override
  void dispose() {
    _numeroTarjetaController.dispose();
    _nombreTitularController.dispose();
    _fechaExpiracionController.dispose();
    _cvvController.dispose();
    _telefonoSinpeController.dispose();
    super.dispose();
  }

  Future<void> _cargarTipoCambio() async {
    setState(() {
      _loadingTipoCambio = true;
      _tipoCambioError = null;
    });

    try {
      final response = await http.get(
        Uri.parse("${AppConfig.apiBaseUrl}/api/bccr/tipo-cambio"),
        headers: const {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200) {
        throw Exception("No se pudo obtener el tipo de cambio");
      }

      final Map<String, dynamic> json = jsonDecode(response.body);
      final data = json["data"] as Map<String, dynamic>?;

      if (data == null) {
        throw Exception("Respuesta inválida del servidor");
      }

      setState(() {
        _compra = _toDouble(data["compra"]);
        _venta = _toDouble(data["venta"]);
        _fechaTipoCambio = data["fecha"]?.toString();
        _fuenteTipoCambio = data["fuente"]?.toString();
      });
    } catch (_) {
      setState(() {
        _tipoCambioError = "No se pudo cargar el tipo de cambio del BCCR.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingTipoCambio = false;
        });
      }
    }
  }

  void _usarTarjetaPrueba(Map<String, dynamic> tarjeta) {
    _numeroTarjetaController.text =
        (tarjeta["numeroTarjeta"] ?? "").toString();
    _nombreTitularController.text =
        (tarjeta["nombreTitular"] ?? "").toString();
    _fechaExpiracionController.text =
        (tarjeta["fechaExpiracion"] ?? "").toString();
    _cvvController.text = (tarjeta["cvv"] ?? "").toString();
  }

  void _usarSinpePrueba(Map<String, dynamic> cuenta) {
    _telefonoSinpeController.text = (cuenta["telefono"] ?? "").toString();
  }

  Future<void> _procesarPago() async {
    final paymentProvider = context.read<PaymentProvider>();
    final orderProvider = context.read<OrderProvider>();

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final ok = await paymentProvider.processPayment(
      orderId: widget.order.id,
      metodoPago: _metodoPagoSeleccionado,
      numeroTarjeta: _esTarjeta
          ? _numeroTarjetaController.text.trim()
          : _telefonoSinpeController.text.trim(),
      nombreTitular:
          _esTarjeta ? _nombreTitularController.text.trim() : "SINPE Móvil",
      fechaExpiracion: _esTarjeta ? _fechaExpiracionController.text.trim() : "",
      cvv: _esTarjeta ? _cvvController.text.trim() : "",
      monto: widget.order.total,
    );

    if (!mounted) return;

    if (ok) {
      await orderProvider.loadOrders();

      final updatedOrder = Order(
        id: widget.order.id,
        userEmail: widget.order.userEmail,
        items: widget.order.items,
        total: widget.order.total,
        date: widget.order.date,
        status: "Completado",
        estadoEntrega: "Pendiente",
      );

      context.go('/order-success', extra: updatedOrder);
    }
  }

  Future<void> _validarTarjeta() async {
    final paymentProvider = context.read<PaymentProvider>();

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    await paymentProvider.validateCard(
      numeroTarjeta: _numeroTarjetaController.text.trim(),
      nombreTitular: _nombreTitularController.text.trim(),
      fechaExpiracion: _fechaExpiracionController.text.trim(),
      cvv: _cvvController.text.trim(),
    );
  }

  void _cambiarMetodoPago(String value) {
    if (value == "paypal" && !_paypalDisponibleEnEstaPlataforma) {
      setState(() {
        _paypalError =
            "PayPal Sandbox está disponible únicamente en la versión web del sistema.";
        _paypalSuccess = null;
      });
      return;
    }

    setState(() {
      _metodoPagoSeleccionado = value;
      _paypalError = null;
      _paypalSuccess = null;
    });

    context.read<PaymentProvider>().clearState();
  }

  Future<void> _onPayPalSuccess() async {
    final orderProvider = context.read<OrderProvider>();

    await orderProvider.loadOrders();

    if (!mounted) return;

    setState(() {
      _paypalError = null;
      _paypalSuccess = "Pago PayPal aprobado";
    });

    final updatedOrder = Order(
      id: widget.order.id,
      userEmail: widget.order.userEmail,
      items: widget.order.items,
      total: widget.order.total,
      date: widget.order.date,
      status: "Completado",
      estadoEntrega: "Pendiente",
    );

    context.go('/order-success', extra: updatedOrder);
  }

  void _onPayPalError(String message) {
    if (!mounted) return;
    setState(() {
      _paypalSuccess = null;
      _paypalError = message;
    });
  }

  void _onPayPalCancel(String message) {
    if (!mounted) return;
    setState(() {
      _paypalSuccess = null;
      _paypalError = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: ClientBaseLayout(
        title: "Pagar Pedido",
        backRoute: '/orders',
        showBackButton: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _orderSummaryCard(),
            const SizedBox(height: 20),
            _tipoCambioCard(),
            const SizedBox(height: 20),
            _paymentMethodCard(),
            const SizedBox(height: 20),
            _paymentFormCard(),
            const SizedBox(height: 20),
            _demoDataCard(paymentProvider),
            const SizedBox(height: 20),
            if (_paypalError != null)
              _messageCard(
                text: _paypalError!,
                color: Colors.redAccent,
              ),
            if (_paypalSuccess != null)
              _messageCard(
                text: _paypalSuccess!,
                color: Colors.greenAccent,
              ),
            if (paymentProvider.testDataError != null &&
                !_esPayPal &&
                paymentProvider.tarjetasPrueba.isEmpty &&
                paymentProvider.sinpePrueba.isEmpty)
              _messageCard(
                text: paymentProvider.testDataError!,
                color: Colors.orangeAccent,
              ),
            if (paymentProvider.errorMessage != null)
              _messageCard(
                text: paymentProvider.errorMessage!,
                color: Colors.redAccent,
              ),
            if (paymentProvider.successMessage != null)
              _messageCard(
                text: paymentProvider.successMessage!,
                color: Colors.greenAccent,
              ),
            const SizedBox(height: 20),
            if (_esTarjeta)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          paymentProvider.isLoading ? null : _validarTarjeta,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.credit_card),
                      label: const Text("Validar tarjeta"),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          paymentProvider.isLoading ? null : _procesarPago,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF5E4BB6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: paymentProvider.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_open),
                      label: Text(
                        paymentProvider.isLoading
                            ? "Procesando..."
                            : "Pagar ahora",
                      ),
                    ),
                  ),
                ],
              )
            else if (_esSinpe)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: paymentProvider.isLoading ? null : _procesarPago,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF5E4BB6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: paymentProvider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.phone_android),
                  label: Text(
                    paymentProvider.isLoading
                        ? "Procesando SINPE..."
                        : "Pagar con SINPE",
                  ),
                ),
              )
            else
              PayPalCheckoutSection(
                order: widget.order,
                token: authProvider.token ?? "",
                venta: _venta,
                onSuccess: _onPayPalSuccess,
                onError: _onPayPalError,
                onCancel: _onPayPalCancel,
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _orderSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pedido #${widget.order.shortId}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Estado actual: ${widget.order.status}",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            "Fecha: ${widget.order.date.day}/${widget.order.date.month}/${widget.order.date.year}",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            "Total a pagar: ₡${widget.order.total.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (_venta != null) ...[
            const SizedBox(height: 10),
            Text(
              "Equivalente en USD: \$${(widget.order.total / _venta!).toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tipoCambioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.currency_exchange,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Tipo de cambio del BCCR",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadingTipoCambio ? null : _cargarTipoCambio,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: "Actualizar tipo de cambio",
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingTipoCambio)
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Consultando tipo de cambio...",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            )
          else if (_tipoCambioError != null)
            Text(
              _tipoCambioError!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Compra: ₡${_compra?.toStringAsFixed(2) ?? '--'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Venta: ₡${_venta?.toStringAsFixed(2) ?? '--'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_fechaTipoCambio != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Fecha: $_fechaTipoCambio",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
                if (_fuenteTipoCambio != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Fuente: $_fuenteTipoCambio",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _paymentMethodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Método de pago",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          RadioListTile<String>(
            value: "tarjeta",
            groupValue: _metodoPagoSeleccionado,
            activeColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              "Tarjeta",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Débito o crédito del banco simulado",
              style: TextStyle(color: Colors.white70),
            ),
            onChanged: (value) {
              if (value == null) return;
              _cambiarMetodoPago(value);
            },
          ),
          RadioListTile<String>(
            value: "sinpe",
            groupValue: _metodoPagoSeleccionado,
            activeColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              "SINPE Móvil",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Pago simulado por número telefónico",
              style: TextStyle(color: Colors.white70),
            ),
            onChanged: (value) {
              if (value == null) return;
              _cambiarMetodoPago(value);
            },
          ),
          RadioListTile<String>(
            value: "paypal",
            groupValue: _metodoPagoSeleccionado,
            activeColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            title: Text(
              _paypalDisponibleEnEstaPlataforma
                  ? "PayPal Sandbox"
                  : "PayPal Sandbox (solo web)",
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _paypalDisponibleEnEstaPlataforma
                  ? "Pago simulado con integración PayPal"
                  : "Disponible únicamente en navegador",
              style: const TextStyle(color: Colors.white70),
            ),
            onChanged: (value) {
              if (value == null) return;
              _cambiarMetodoPago(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _paymentFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
      ),
      child: Form(
        key: _formKey,
        child: _esTarjeta
            ? _tarjetaForm()
            : _esSinpe
                ? _sinpeForm()
                : _payPalInfo(),
      ),
    );
  }

  Widget _tarjetaForm() {
    return Column(
      children: [
        _textField(
          controller: _numeroTarjetaController,
          label: "Número de tarjeta",
          hint: "4000000000000001",
          keyboardType: TextInputType.number,
          validator: (value) {
            if (!_esTarjeta) return null;
            final v = value?.trim() ?? '';
            if (v.isEmpty) return "Ingrese el número de tarjeta";
            if (!RegExp(r'^\d{16}$').hasMatch(v)) {
              return "Número de tarjeta inválido";
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        _textField(
          controller: _nombreTitularController,
          label: "Nombre del titular",
          hint: "Nombre completo",
          validator: (value) {
            if (!_esTarjeta) return null;
            final v = value?.trim() ?? '';
            if (v.isEmpty) return "Ingrese el nombre del titular";
            return null;
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: _fechaExpiracionController,
                label: "Fecha expiración",
                hint: "12/28",
                validator: (value) {
                  if (!_esTarjeta) return null;
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return "Ingrese la fecha";
                  if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) {
                    return "Formato MM/AA";
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _textField(
                controller: _cvvController,
                label: "CVV",
                hint: "001",
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: (value) {
                  if (!_esTarjeta) return null;
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return "Ingrese CVV";
                  if (!RegExp(r'^\d{3,4}$').hasMatch(v)) {
                    return "CVV inválido";
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sinpeForm() {
    final paymentProvider = context.watch<PaymentProvider>();

    return Column(
      children: [
        _textField(
          controller: _telefonoSinpeController,
          label: "Número SINPE Móvil",
          hint: "88880001",
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (!_esSinpe) return null;
            final v = value?.trim() ?? '';
            if (v.isEmpty) return "Ingrese el número SINPE";
            if (!RegExp(r'^\d{8}$').hasMatch(v)) {
              return "El número SINPE debe tener 8 dígitos";
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cuentas SINPE disponibles",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (paymentProvider.loadingTestData)
                const Text(
                  "Cargando cuentas SINPE desde la base de datos...",
                  style: TextStyle(color: Colors.white70),
                )
              else if (paymentProvider.sinpePrueba.isEmpty)
                const Text(
                  "No hay cuentas SINPE de prueba disponibles.",
                  style: TextStyle(color: Colors.white70),
                )
              else
                ...paymentProvider.sinpePrueba.map((cuenta) {
                  final nombre =
                      (cuenta["nombreTitular"] ?? "Sin nombre").toString();
                  final telefono = (cuenta["telefono"] ?? "").toString();
                  final activo = cuenta["activo"] == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _usarSinpePrueba(cuenta),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          "$nombre → $telefono ${activo ? '(Activa)' : '(Inactiva)'}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _payPalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PayPal Sandbox",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _venta != null
              ? "Total estimado en USD: \$${(widget.order.total / _venta!).toStringAsFixed(2)}"
              : "Total estimado en USD: calculando...",
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(
          _paypalDisponibleEnEstaPlataforma
              ? "Usa una cuenta sandbox de comprador para completar la prueba."
              : "En Android puedes continuar con Tarjeta o SINPE. PayPal queda disponible en la versión web.",
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _demoDataCard(PaymentProvider paymentProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Datos de prueba",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          if (_esTarjeta) ...[
            const Text(
              "Tarjetas disponibles desde la base de datos:",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (paymentProvider.loadingTestData)
              const Text(
                "Cargando tarjetas desde la base de datos...",
                style: TextStyle(color: Colors.white70),
              )
            else if (paymentProvider.tarjetasPrueba.isEmpty)
              const Text(
                "No hay tarjetas de prueba disponibles.",
                style: TextStyle(color: Colors.white70),
              )
            else
              ...paymentProvider.tarjetasPrueba.map((tarjeta) {
                final numero = (tarjeta["numeroTarjeta"] ?? "").toString();
                final nombre =
                    (tarjeta["nombreTitular"] ?? "Sin nombre").toString();
                final cvv = (tarjeta["cvv"] ?? "").toString();
                final fecha = (tarjeta["fechaExpiracion"] ?? "").toString();
                final tipo = (tarjeta["tipoTarjeta"] ?? "").toString();
                final estado = (tarjeta["estado"] ?? "").toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _usarTarjetaPrueba(tarjeta),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        "$numero • $nombre • CVV $cvv • $fecha • $tipo • $estado",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 8),
            const Text(
              "Toca una tarjeta para autocompletar el formulario.",
              style: TextStyle(color: Colors.white54),
            ),
          ] else if (_esSinpe) ...[
            const Text(
              "Las cuentas SINPE visibles se cargan desde banco_simulado.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              "Toca una cuenta para autocompletar el número.",
              style: TextStyle(color: Colors.white54),
            ),
          ] else ...[
            Text(
              _paypalDisponibleEnEstaPlataforma
                  ? "PayPal usa cuentas sandbox del panel de desarrollador."
                  : "PayPal se mantiene para pruebas web. En Android usa Tarjeta o SINPE.",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              "Debes tener configurado PAYPAL_CLIENT_ID y PAYPAL_CLIENT_SECRET en el backend.",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(14),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _messageCard({
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}