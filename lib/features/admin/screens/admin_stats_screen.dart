import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/admin_service.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {

  final AdminService adminService = AdminService();

  @override
  Widget build(BuildContext context) {

    final auth = context.watch<AuthProvider>();

    return Scaffold(

      appBar: AppBar(
        title: const Text("Estadísticas del negocio"),
      ),

      body: FutureBuilder(

        future: adminService.getDashboard(auth.token ?? ""),

        builder: (context, dashboardSnapshot) {

          if (!dashboardSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dashboard = dashboardSnapshot.data as Map<String, dynamic>;

          int clientes = dashboard["totalUsuarios"];
          int pedidos = dashboard["totalPedidos"];
          double ventas = double.parse(dashboard["ventasTotales"].toString());
          List topProductos = dashboard["topProductos"];

          return SingleChildScrollView(

            padding: const EdgeInsets.all(20),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                /// MÉTRICAS

                Row(
                  children: [

                    _metricCard(
                      "Ventas",
                      "₡${ventas.toStringAsFixed(0)}",
                      Colors.green
                    ),

                    const SizedBox(width:10),

                    _metricCard(
                      "Pedidos",
                      pedidos.toString(),
                      Colors.orange
                    ),

                    const SizedBox(width:10),

                    _metricCard(
                      "Clientes",
                      clientes.toString(),
                      Colors.blue
                    ),

                  ],
                ),

                const SizedBox(height:30),

                /// GRÁFICO DE VENTAS

                const Text(
                  "Ventas por mes",
                  style: TextStyle(fontSize:18,fontWeight:FontWeight.bold),
                ),

                const SizedBox(height:20),

                SizedBox(

                  height:300,

                  child: FutureBuilder(

                    future: adminService.getSalesChart(auth.token ?? ""),

                    builder: (context,snapshot){

                      if(!snapshot.hasData){
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final data = snapshot.data as List;

                      List<FlSpot> spots = [];

                      for(int i=0;i<data.length;i++){

                        spots.add(
                          FlSpot(
                            i.toDouble(),
                            double.parse(data[i]["ventas"].toString())
                          )
                        );

                      }

                      return LineChart(

                        LineChartData(

                          gridData: FlGridData(show:true),

                          borderData: FlBorderData(show:true),

                          lineBarsData: [

                            LineChartBarData(

                              spots: spots,

                              isCurved: true,

                              barWidth:4,

                              color: Colors.green,

                              belowBarData: BarAreaData(show:true),

                            )

                          ],

                        )

                      );

                    },

                  ),

                ),

                const SizedBox(height:40),

                /// PIE CHART PRODUCTOS

                const Text(
                  "Productos más vendidos",
                  style: TextStyle(fontSize:18,fontWeight:FontWeight.bold),
                ),

                const SizedBox(height:20),

                SizedBox(

                  height:250,

                  child: PieChart(

                    PieChartData(

                      sections: topProductos.map<PieChartSectionData>((p){

                        return PieChartSectionData(

                          value: double.parse(p["vendidos"].toString()),

                          title: p["name"],

                          radius:90,

                        );

                      }).toList(),

                    ),

                  ),

                ),

                const SizedBox(height:30),

                /// LISTA PRODUCTOS

                Column(

                  children: topProductos.map<Widget>((p){

                    return ListTile(

                      leading: const Icon(Icons.inventory),

                      title: Text(p["name"]),

                      trailing: Text("${p["vendidos"]} vendidos"),

                    );

                  }).toList(),

                ),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard(String title,String value,Color color){

    return Expanded(

      child: Container(

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.circular(12),

          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius:5
            )
          ]

        ),

        child: Column(

          children: [

            Text(title),

            const SizedBox(height:10),

            Text(
              value,
              style: TextStyle(
                fontSize:22,
                fontWeight:FontWeight.bold,
                color:color
              ),
            )

          ],
        ),
      ),
    );
  }
}