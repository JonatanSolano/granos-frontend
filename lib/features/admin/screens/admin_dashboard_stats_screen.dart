import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/admin_service.dart';
import '../widgets/admin_base_layout.dart';

class AdminDashboardStatsScreen extends StatefulWidget {
  const AdminDashboardStatsScreen({super.key});

  @override
  State<AdminDashboardStatsScreen> createState() =>
      _AdminDashboardStatsScreenState();
}

class _AdminDashboardStatsScreenState
    extends State<AdminDashboardStatsScreen> {
  final AdminService adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AdminBaseLayout(
      title: "Estadísticas del Negocio",
      showBackButton: true,
      backRoute: "/admin",
      child: FutureBuilder(
        future: adminService.getDashboard(auth.token ?? ""),
        builder: (context, dashboardSnapshot) {
          if (!dashboardSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final dashboard =
              dashboardSnapshot.data as Map<String, dynamic>;

          final int clientes = dashboard["totalUsuarios"] ?? 0;
          final int pedidos = dashboard["totalPedidos"] ?? 0;
          final double ventas =
              double.tryParse(dashboard["ventasTotales"].toString()) ?? 0;

          final int pedidosPendientes = dashboard["pedidosPendientes"] ?? 0;
          final int pedidosCompletados = dashboard["pedidosCompletados"] ?? 0;
          final int pedidosCancelados = dashboard["pedidosCancelados"] ?? 0;

          final int entregasPendientes = dashboard["entregasPendientes"] ?? 0;
          final int entregasEnCamino = dashboard["entregasEnCamino"] ?? 0;
          final int entregasEntregadas = dashboard["entregasEntregadas"] ?? 0;

          final int productosActivos = dashboard["productosActivos"] ?? 0;
          final int productosInactivos = dashboard["productosInactivos"] ?? 0;
          final int productosBajoStock = dashboard["productosBajoStock"] ?? 0;

          final double ticketPromedio =
              double.tryParse(dashboard["ticketPromedio"].toString()) ?? 0;
          final double pedidoMasAlto =
              double.tryParse(dashboard["pedidoMasAlto"].toString()) ?? 0;
          final double crecimientoMensual =
              double.tryParse(dashboard["crecimientoMensual"].toString()) ?? 0;

          final String topProductoNombre =
              dashboard["topProductoNombre"]?.toString() ?? "Sin datos";
          final String productoMenosVendido =
              dashboard["productoMenosVendido"]?.toString() ?? "Sin datos";

          final List alertas = dashboard["alertas"] ?? [];
          final List topProductos = dashboard["topProductos"] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Resumen General"),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: "Ventas",
                      subtitle: "Ingresos totales",
                      value: "₡${ventas.toStringAsFixed(0)}",
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Pedidos",
                      subtitle: "Total registrados",
                      value: pedidos.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Clientes",
                      subtitle: "Registrados",
                      value: clientes.toString(),
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _sectionTitle("Indicadores Clave del Negocio"),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: "Ticket promedio",
                      subtitle: "Promedio por pedido",
                      value: "₡${ticketPromedio.toStringAsFixed(0)}",
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Pedido más alto",
                      subtitle: "Mayor monto vendido",
                      value: "₡${pedidoMasAlto.toStringAsFixed(0)}",
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
                      title: "Top producto",
                      subtitle: "Más vendido",
                      value: topProductoNombre,
                      color: Colors.lightGreenAccent,
                      isCompactText: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Menor venta",
                      subtitle: "Producto más lento",
                      value: productoMenosVendido,
                      color: Colors.amber,
                      isCompactText: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _metricCard(
                title: "Crecimiento mensual",
                subtitle: "Comparación contra el mes anterior",
                value:
                    "${crecimientoMensual >= 0 ? '+' : ''}${crecimientoMensual.toStringAsFixed(1)}%",
                color: crecimientoMensual >= 0
                    ? Colors.greenAccent
                    : Colors.redAccent,
              ),

              const SizedBox(height: 24),

              _sectionTitle("Estado de Pedidos"),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: "Pendientes",
                      subtitle: "Sin pagar",
                      value: pedidosPendientes.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Pagados",
                      subtitle: "Confirmados",
                      value: pedidosCompletados.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Cancelados",
                      subtitle: "Anulados",
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
                      title: "Entrega pendiente",
                      subtitle: "Listos para envío",
                      value: entregasPendientes.toString(),
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "En camino",
                      subtitle: "En reparto",
                      value: entregasEnCamino.toString(),
                      color: Colors.lightBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Entregados",
                      subtitle: "Finalizados",
                      value: entregasEntregadas.toString(),
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _sectionTitle("Productos"),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: "Activos",
                      subtitle: "Disponibles",
                      value: productosActivos.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Inactivos",
                      subtitle: "Deshabilitados",
                      value: productosInactivos.toString(),
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricCard(
                      title: "Bajo stock",
                      subtitle: "Requieren atención",
                      value: productosBajoStock.toString(),
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (alertas.isNotEmpty) ...[
                _sectionTitle("Alertas del Negocio"),
                const SizedBox(height: 16),
                ...alertas.map((alerta) => _alertCard(alerta.toString())),
                const SizedBox(height: 24),
              ],

              _sectionTitle("Ventas por mes"),
              const SizedBox(height: 20),

              SizedBox(
                height: 320,
                child: FutureBuilder(
                  future: adminService.getSalesChart(auth.token ?? ""),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final data = snapshot.data as List;

                    if (data.isEmpty) {
                      return const Center(
                        child: Text(
                          "No hay datos de ventas para mostrar",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final List<FlSpot> spots = [];
                    final List<String> labels = [];

                    for (int i = 0; i < data.length; i++) {
                      final mes = data[i]["mes"].toString();
                      final ventas =
                          double.tryParse(data[i]["ventas"].toString()) ?? 0;

                      spots.add(FlSpot(i.toDouble(), ventas));
                      labels.add(_formatMonthLabel(mes));
                    }

                    double maxY = 0;
                    for (final spot in spots) {
                      if (spot.y > maxY) maxY = spot.y;
                    }
                    maxY = maxY == 0 ? 10 : maxY * 1.2;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white.withOpacity(0.15),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 46,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _formatYAxis(value),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= labels.length) {
                                    return const SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      labels[index],
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              barWidth: 4,
                              color: Colors.greenAccent,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.greenAccent.withOpacity(0.18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              _sectionTitle("Productos más vendidos"),
              const SizedBox(height: 20),

              if (topProductos.isEmpty)
                const Text(
                  "No hay productos vendidos para mostrar",
                  style: TextStyle(color: Colors.white70),
                )
              else ...[
                SizedBox(
                  height: 280,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 35,
                      sectionsSpace: 2,
                      sections: _buildPieSections(topProductos),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...topProductos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final p = entry.value;

                  final medal = switch (index) {
                    0 => "🥇",
                    1 => "🥈",
                    2 => "🥉",
                    _ => "•"
                  };

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          medal,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p["name"].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          "${p["vendidos"]} vendidos",
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required Color color,
    String? subtitle,
    bool isCompactText = false,
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
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompactText ? 16 : 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orangeAccent,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List topProductos) {
    final colors = [
      Colors.cyan,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.redAccent,
    ];

    return topProductos.asMap().entries.map<PieChartSectionData>((entry) {
      final index = entry.key;
      final p = entry.value;

      return PieChartSectionData(
        value: double.tryParse(p["vendidos"].toString()) ?? 0,
        title: "",
        radius: 90,
        color: colors[index % colors.length],
      );
    }).toList();
  }

  String _formatMonthLabel(String mes) {
    final parts = mes.split('-');
    if (parts.length != 2) return mes;

    final month = int.tryParse(parts[1]) ?? 0;

    const months = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];

    if (month < 1 || month > 12) return mes;
    return months[month];
  }

  String _formatYAxis(double value) {
    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}K";
    }
    return value.toStringAsFixed(0);
  }
}