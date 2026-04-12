import 'package:flutter/material.dart';
import 'package:granos_la_tradicion/features/cliente/widgets/client_base_layout.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ClientBaseLayout(
        title: "Acerca de",
        showBackButton: true,
        backRoute: '/cliente',
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                _buildLogoCard(),
                const SizedBox(height: 20),
                _buildDescriptionCard(),
                const SizedBox(height: 20),
                _buildModulesCard(),
                const SizedBox(height: 20),
                _buildDeveloperCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          Container(
           width: 240,
           height: 240,
             padding: const EdgeInsets.all(8),
             decoration: const BoxDecoration(
            color: Colors.white,
           shape: BoxShape.circle,
      ),
      child: Center(
          child: Image.asset(
             "assets/images/logo.png",
                 width: 235,
                 height: 235,
                   fit: BoxFit.contain,
                     errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront,
                     size: 110,
                    color: Colors.brown,
                  ),
               ),
            ),
        ),
          const SizedBox(height: 22),
          const Text(
            "Acerca de Granos La Tradición",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Sistema de comercio electrónico para la venta y administración de productos de granos.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _glassCard(
      title: "Descripción del sistema",
      icon: Icons.description_outlined,
      child: const Text(
        "En Granos La Tradición llevamos a tu mesa la esencia de lo natural, combinando calidad, confianza y tradición en cada producto. "
        "Nuestro compromiso es ofrecerte una experiencia sencilla, segura y cercana, donde cada grano cuenta una historia de trabajo, dedicación y excelencia.",
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildModulesCard() {
    return _glassCard(
      title: "Módulos principales",
      icon: Icons.dashboard_outlined,
      child: const Column(
        children: [
          _ModuleItem(text: "Autenticación y seguridad"),
          _ModuleItem(text: "Catálogo de productos"),
          _ModuleItem(text: "Carrito de compras"),
          _ModuleItem(text: "Gestión de pedidos"),
          _ModuleItem(text: "Procesamiento de pagos"),
          _ModuleItem(text: "Perfil de usuario"),
          _ModuleItem(text: "Panel administrativo"),
          _ModuleItem(text: "Estadísticas del negocio"),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard() {
    return _glassCard(
      title: "Información del desarrollador",
      icon: Icons.person_outline,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: "Desarrollador",
            value: "Jonatan Alfredo Solano Moya",
          ),
          SizedBox(height: 12),
          _InfoRow(
            label: "Universidad",
            value: "Colegio Universitario de Cartago",
          ),
          SizedBox(height: 12),
          _InfoRow(
            label: "Versión",
            value: "1.0",
          ),
        ],
      ),
    );
  }

  Widget _glassCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ModuleItem extends StatelessWidget {
  final String text;

  const _ModuleItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white,
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}