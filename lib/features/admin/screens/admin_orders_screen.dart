import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:granos_la_tradicion/features/pedidos/providers/order_provider.dart';
import 'package:granos_la_tradicion/features/pedidos/models/order_model.dart';
import 'package:granos_la_tradicion/features/admin/widgets/admin_base_layout.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() =>
      _AdminOrdersScreenState();
}

class _AdminOrdersScreenState
    extends State<AdminOrdersScreen> {
  bool loading = true;

  String filtroPago = "Todos";
  String filtroEntrega = "Todos";

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await context.read<OrderProvider>().loadAllOrders();

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final orders = orderProvider.orders.where((order) {
      final cumplePago =
          filtroPago == "Todos" || order.status == filtroPago;

      final cumpleEntrega =
          filtroEntrega == "Todos" || order.estadoEntrega == filtroEntrega;

      return cumplePago && cumpleEntrega;
    }).toList();

    return AdminBaseLayout(
      title: "Gestión de Pedidos",
      showBackButton: true,
      child: loading
          ? const Padding(
              padding: EdgeInsets.only(top: 40),
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilters(),
                const SizedBox(height: 20),
                if (orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      "No hay pedidos registrados con esos filtros",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    children: orders.map((order) {
                      return _glassOrderCard(
                        context,
                        order,
                        orderProvider,
                      );
                    }).toList(),
                  ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Filtrar por estado de pago",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _filterButtonPago("Todos"),
            _filterButtonPago("Pendiente"),
            _filterButtonPago("Completado"),
            _filterButtonPago("Cancelado"),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          "Filtrar por estado de entrega",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _filterButtonEntrega("Todos"),
            _filterButtonEntrega("Pendiente"),
            _filterButtonEntrega("En camino"),
            _filterButtonEntrega("Entregado"),
          ],
        ),
      ],
    );
  }

  Widget _filterButtonPago(String value) {
    final bool selected = filtroPago == value;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.green : Colors.grey.shade300,
        foregroundColor: selected ? Colors.white : const Color(0xFF6A4BBE),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      onPressed: () {
        setState(() {
          filtroPago = value;
        });
      },
      child: Text(value),
    );
  }

  Widget _filterButtonEntrega(String value) {
    final bool selected = filtroEntrega == value;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.orange : Colors.grey.shade300,
        foregroundColor: selected ? Colors.white : const Color(0xFF6A4BBE),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      onPressed: () {
        setState(() {
          filtroEntrega = value;
        });
      },
      child: Text(value),
    );
  }

  Widget _glassOrderCard(
    BuildContext context,
    Order order,
    OrderProvider provider,
  ) {
    final String email =
        order.userEmail.isNotEmpty
            ? order.userEmail
            : "correo no disponible";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "Pedido #${order.shortId}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Cliente: $email",
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Fecha: ${order.date.day}/${order.date.month}/${order.date.year}",
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Total: ₡${order.total.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Estado de pago:",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                DropdownButton<String>(
                  dropdownColor: Colors.grey[900],
                  value: order.status,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'Pendiente',
                      child: Text("Pendiente"),
                    ),
                    DropdownMenuItem(
                      value: 'Completado',
                      child: Text("Completado"),
                    ),
                    DropdownMenuItem(
                      value: 'Cancelado',
                      child: Text("Cancelado"),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;

                    setState(() {
                      loading = true;
                    });

                    await provider.updateOrderStatus(
                      order.id,
                      value,
                    );

                    await provider.loadAllOrders();

                    if (mounted) {
                      setState(() {
                        loading = false;
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Estado de entrega:",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                DropdownButton<String>(
                  dropdownColor: Colors.grey[900],
                  value: order.estadoEntrega,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'Pendiente',
                      child: Text("Pendiente"),
                    ),
                    DropdownMenuItem(
                      value: 'En camino',
                      child: Text("En camino"),
                    ),
                    DropdownMenuItem(
                      value: 'Entregado',
                      child: Text("Entregado"),
                    ),
                  ],
                  onChanged: order.status != "Completado"
                      ? null
                      : (value) async {
                          if (value == null) return;

                          setState(() {
                            loading = true;
                          });

                          await provider.updateOrderDeliveryStatus(
                            order.id,
                            value,
                          );

                          await provider.loadAllOrders();

                          if (mounted) {
                            setState(() {
                              loading = false;
                            });
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}