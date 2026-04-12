import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../models/order_model.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pedido Confirmado"),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "¡Compra realizada con éxito!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          "Pedido #${order.id}",
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Fecha: ${order.date.day}/${order.date.month}/${order.date.year}",
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Estado: ${order.status}",
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),

                        ...order.items.map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.product.nombre),
                            subtitle: Text("Cantidad: ${item.quantity}"),
                            trailing: Text(
                              "₡ ${(item.product.precio * item.quantity).toStringAsFixed(0)}",
                            ),
                          );
                        }).toList(),

                        const Divider(),
                        const SizedBox(height: 10),

                        Text(
                          "Total: ₡ ${order.total.toStringAsFixed(0)}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// VER PEDIDOS
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              context.go('/orders');
                            },
                            child: const Text("Ver mis pedidos"),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// SEGUIR COMPRANDO
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              context.go('/catalogo');
                            },
                            child: const Text("Seguir comprando"),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// VOLVER AL PANEL
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("Volver al Panel"),
                            onPressed: () {
                              if (!auth.isAuthenticated) {
                                context.go('/');
                                return;
                              }

                              if (auth.currentUser?.role == UserRole.admin) {
                                context.go('/admin');
                              } else {
                                context.go('/cliente');
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF2E7D32),
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}