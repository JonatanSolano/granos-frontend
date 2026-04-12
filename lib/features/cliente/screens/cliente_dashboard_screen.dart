import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:granos_la_tradicion/core/providers/auth_provider.dart';
import 'package:granos_la_tradicion/features/cliente/widgets/client_base_layout.dart';

class ClienteDashboardScreen extends StatelessWidget {
  const ClienteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      body: ClientBaseLayout(
        title: "Mi Panel",
        showBackButton: false,
        child: Column(
          children: [
            const SizedBox(height: 6),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Bienvenido, ${currentUser?.name ?? 'Cliente'}",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),

            _menuCard(
              context,
              icon: Icons.store,
              title: "Catálogo",
              subtitle: "Explora nuestra selección de granos",
              route: '/catalogo',
            ),

            _menuCard(
              context,
              icon: Icons.receipt_long,
              title: "Mis pedidos",
              subtitle: "Revisa el estado de tus pedidos",
              route: '/orders',
            ),

            _menuCard(
              context,
              icon: Icons.shopping_cart,
              title: "Ir al carrito",
              subtitle: "Gestiona tus productos seleccionados",
              route: '/cart',
            ),

            _menuCard(
              context,
              icon: Icons.person,
              title: "Mi perfil",
              subtitle: "Gestiona tu cuenta y datos personales",
              route: '/profile',
            ),

            _menuCard(
              context,
              icon: Icons.info_outline,
              title: "Acerca de",
              subtitle: "Conoce información general del sistema",
              route: '/about',
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/');
                }
              },
              child: const Text(
                "Cerrar sesión",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(route),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
}