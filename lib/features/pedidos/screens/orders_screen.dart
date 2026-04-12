import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/order_provider.dart';
import '../models/order_model.dart';
import 'package:granos_la_tradicion/features/cliente/widgets/client_base_layout.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final allOrders = orderProvider.orders;
    final filteredOrders = _applyFilter(allOrders);

    return Scaffold(
      body: ClientBaseLayout(
        title: "Mis Pedidos",
        showBackButton: true,
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _filterChip('Todos'),
                _filterChip('Pendiente'),
                _filterChip('Completado'),
                _filterChip('Cancelado'),
              ],
            ),
            const SizedBox(height: 20),
            if (filteredOrders.isEmpty)
              _emptyOrders()
            else
              ...filteredOrders.map((order) {
                return _glassOrderCard(
                  context,
                  order,
                  orderProvider,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  List<Order> _applyFilter(List<Order> orders) {
    if (_selectedFilter == 'Todos') return orders;
    return orders.where((o) => o.status == _selectedFilter).toList();
  }

  Widget _emptyOrders() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.white70,
          ),
          SizedBox(height: 20),
          Text(
            "No hay pedidos para mostrar",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassOrderCard(
    BuildContext context,
    Order order,
    OrderProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.go('/order-detail', extra: order);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pedido #${order.shortId}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Fecha: ${order.date.day}/${order.date.month}/${order.date.year}",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                "Total: ₡${order.total.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Estado de pago:",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              _statusBadge(order.status),
              const SizedBox(height: 12),
              const Text(
                "Estado de entrega:",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              _deliveryStatusBadge(order.estadoEntrega),
              if (order.status == 'Pendiente')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        context.go('/payment', extra: order);
                      },
                      child: const Text(
                        "Pagar",
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _confirmCancel(context, provider, order.id);
                      },
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancel(
    BuildContext context,
    OrderProvider provider,
    int orderId,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Cancelar pedido"),
          content: const Text(
            "¿Estás seguro que deseas cancelar este pedido?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                await provider.cancelOrder(orderId);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Sí, cancelar"),
            ),
          ],
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'Pendiente':
        color = Colors.orange;
        break;
      case 'Completado':
        color = Colors.green;
        break;
      case 'Cancelado':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _deliveryStatusBadge(String status) {
    Color color;

    switch (status) {
      case 'Pendiente':
        color = Colors.orange;
        break;
      case 'En camino':
        color = Colors.blue;
        break;
      case 'Entregado':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == label,
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: Colors.white,
      backgroundColor: Colors.white.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _selectedFilter == label ? Colors.black : Colors.white,
      ),
    );
  }
}