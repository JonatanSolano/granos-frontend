import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:granos_la_tradicion/core/providers/auth_provider.dart';
import 'package:granos_la_tradicion/core/services/admin_service.dart';
import 'package:granos_la_tradicion/features/pedidos/providers/order_provider.dart';
import 'package:granos_la_tradicion/features/admin/widgets/admin_base_layout.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final pendingOrders = orderProvider.pendingCount;

    final adminService = AdminService();

    return AdminBaseLayout(
      title: "Panel Administrador",
      showBackButton: false,
      child: FutureBuilder(
        future: adminService.getDashboard(auth.token ?? ""),
        builder: (context, snapshot) {
          int totalUsuarios = 0;
          int totalPedidos = 0;
          double ventasTotales = 0;
          int pedidosCompletados = 0;
          int pedidosCancelados = 0;
          int entregasPendientes = 0;
          int entregasEnCamino = 0;
          int entregasEntregadas = 0;
          int productosActivos = 0;
          int productosInactivos = 0;
          int productosBajoStock = 0;

          if (snapshot.hasData) {
            final data = snapshot.data as Map<String, dynamic>;

            totalUsuarios = data["totalUsuarios"] ?? 0;
            totalPedidos = data["totalPedidos"] ?? 0;
            ventasTotales =
                double.tryParse(data["ventasTotales"].toString()) ?? 0;

            pedidosCompletados = data["pedidosCompletados"] ?? 0;
            pedidosCancelados = data["pedidosCancelados"] ?? 0;
            entregasPendientes = data["entregasPendientes"] ?? 0;
            entregasEnCamino = data["entregasEnCamino"] ?? 0;
            entregasEntregadas = data["entregasEntregadas"] ?? 0;
            productosActivos = data["productosActivos"] ?? 0;
            productosInactivos = data["productosInactivos"] ?? 0;
            productosBajoStock = data["productosBajoStock"] ?? 0;
          }

          return Column(
            children: [
              Text(
                "Bienvenido ${auth.currentUser?.name ?? 'Administrador'}",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: "Pendientes",
                      subtitle: "Pedidos sin pagar",
                      value: pendingOrders.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Clientes",
                      subtitle: "Clientes registrados",
                      value: totalUsuarios.toString(),
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: "Pedidos",
                      subtitle: "Total de pedidos",
                      value: totalPedidos.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Ventas",
                      subtitle: "Ingresos totales",
                      value: "₡${ventasTotales.toStringAsFixed(0)}",
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: "Pagados",
                      subtitle: "Pedidos confirmados",
                      value: pedidosCompletados.toString(),
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Cancelados",
                      subtitle: "Pedidos anulados",
                      value: pedidosCancelados.toString(),
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: "En camino",
                      subtitle: "Pedidos en envío",
                      value: entregasEnCamino.toString(),
                      color: Colors.lightBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Entregados",
                      subtitle: "Pedidos finalizados",
                      value: entregasEntregadas.toString(),
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: "Activos",
                      subtitle: "Productos disponibles",
                      value: productosActivos.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Bajo stock",
                      subtitle: "Poco inventario",
                      value: productosBajoStock.toString(),
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: "Entrega pendiente",
                      subtitle: "Listos para enviar",
                      value: entregasPendientes.toString(),
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Inactivos",
                      subtitle: "Productos deshabilitados",
                      value: productosInactivos.toString(),
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _glassButton(
                icon: Icons.bar_chart,
                text: "Ver Estadísticas",
                onTap: () => context.go('/admin/stats'),
              ),

              _glassButton(
                icon: Icons.people,
                text: "Gestionar Clientes",
                onTap: () => context.go('/admin-users'),
              ),

              _glassButton(
                icon: Icons.inventory,
                text: "Gestionar Productos",
                onTap: () => context.go('/admin-products'),
              ),

              _glassButton(
                icon: Icons.receipt_long,
                text: "Gestionar Pedidos",
                onTap: () => context.go('/admin-orders'),
              ),

              _glassButton(
                icon: Icons.security,
                text: "Actividad del Sistema",
                onTap: () => context.go('/admin-activity'),
              ),

              const SizedBox(height: 10),

              _glassButton(
                icon: Icons.logout,
                text: "Cerrar sesión",
                onTap: () async {
                  await auth.logout();
                  context.go('/');
                },
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.brown.shade700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}