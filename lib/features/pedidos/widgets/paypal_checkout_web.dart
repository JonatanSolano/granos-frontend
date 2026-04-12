import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:granos_la_tradicion/core/config/app_config.dart';
import 'package:granos_la_tradicion/features/pedidos/models/order_model.dart';

class PayPalCheckoutSection extends StatefulWidget {
  final Order order;
  final String token;
  final double? venta;
  final Future<void> Function() onSuccess;
  final void Function(String message) onError;
  final void Function(String message) onCancel;

  const PayPalCheckoutSection({
    super.key,
    required this.order,
    required this.token,
    required this.venta,
    required this.onSuccess,
    required this.onError,
    required this.onCancel,
  });

  @override
  State<PayPalCheckoutSection> createState() => _PayPalCheckoutSectionState();
}

class _PayPalCheckoutSectionState extends State<PayPalCheckoutSection> {
  late final String _paypalViewType;
  late final String _paypalContainerId;

  StreamSubscription<html.MessageEvent>? _paypalMessageSubscription;
  bool _paypalButtonsRendered = false;
  bool _paypalLoading = false;

  @override
  void initState() {
    super.initState();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _paypalContainerId =
        "paypal-button-container-${widget.order.id}-$timestamp";
    _paypalViewType = "paypal-view-${widget.order.id}-$timestamp";

    _registerPaypalViewFactory();
    _listenPayPalMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _renderPayPalButtons();
        }
      });
    });
  }

  void _registerPaypalViewFactory() {
    final container = html.DivElement()
      ..id = _paypalContainerId
      ..style.width = "100%"
      ..style.minHeight = "120px"
      ..style.backgroundColor = "transparent";

    ui_web.platformViewRegistry.registerViewFactory(
      _paypalViewType,
      (int viewId) => container,
    );
  }

  void _listenPayPalMessages() {
    _paypalMessageSubscription = html.window.onMessage.listen((event) async {
      dynamic rawData = event.data;

      try {
        rawData = js_util.dartify(rawData);
      } catch (_) {}

      if (rawData is! Map) return;
      if (rawData["source"] != "paypal_flutter") return;

      final type = rawData["type"]?.toString();
      final message = rawData["message"]?.toString();

      if (!mounted) return;

      if (type == "ready") {
        setState(() {
          _paypalLoading = false;
        });
        return;
      }

      if (type == "processing") {
        setState(() {
          _paypalLoading = true;
        });
        return;
      }

      if (type == "success") {
        setState(() {
          _paypalLoading = false;
        });
        await widget.onSuccess();
      } else if (type == "cancel") {
        setState(() {
          _paypalLoading = false;
        });
        widget.onCancel(message ?? "Pago PayPal cancelado por el usuario.");
      } else if (type == "error") {
        setState(() {
          _paypalLoading = false;
        });
        widget.onError(message ?? "Error al procesar PayPal.");
      }
    });
  }

  void _renderPayPalButtons() {
    if (_paypalButtonsRendered) return;

    if (widget.token.isEmpty) {
      widget.onError("Sesión no válida para PayPal.");
      return;
    }

    final renderFunction =
        js_util.getProperty(html.window, "renderFlutterPayPalButtons");

    if (renderFunction == null) {
      widget.onError("No se cargó la función PayPal del index.html.");
      return;
    }

    final container = html.document.getElementById(_paypalContainerId);
    if (container != null) {
      container.children.clear();
      container.innerHtml = "";
    }

    setState(() {
      _paypalLoading = true;
    });

    js_util.callMethod(html.window, "renderFlutterPayPalButtons", [
      js_util.jsify({
        "containerId": _paypalContainerId,
        "createOrderUrl": "${AppConfig.apiBaseUrl}/api/paypal/create-order",
        "captureOrderUrl": "${AppConfig.apiBaseUrl}/api/paypal/capture-order",
        "token": widget.token,
        "orderId": widget.order.id,
      })
    ]);

    setState(() {
      _paypalButtonsRendered = true;
    });
  }

  @override
  void dispose() {
    _paypalMessageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      child: Column(
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
            widget.venta != null
                ? "Total estimado en USD: \$${(widget.order.total / widget.venta!).toStringAsFixed(2)}"
                : "Total estimado en USD: calculando...",
            style: const TextStyle(color: Colors.white70),
          ),
          if (_paypalLoading) ...[
            const SizedBox(height: 12),
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
                  "Procesando PayPal...",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 120,
            child: HtmlElementView(
              viewType: _paypalViewType,
            ),
          ),
        ],
      ),
    );
  }
}