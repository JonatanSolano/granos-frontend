import 'package:flutter/material.dart';
import 'package:granos_la_tradicion/features/pedidos/models/order_model.dart';

class PayPalCheckoutSection extends StatelessWidget {
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
            venta != null
                ? "Total estimado en USD: \$${(order.total / venta!).toStringAsFixed(2)}"
                : "Total estimado en USD: calculando...",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          const Text(
            "PayPal Sandbox está disponible únicamente en la versión web del sistema.",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}