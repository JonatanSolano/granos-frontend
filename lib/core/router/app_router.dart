import 'package:go_router/go_router.dart';

import 'package:granos_la_tradicion/core/models/user_model.dart';
import 'package:granos_la_tradicion/core/providers/auth_provider.dart';

import 'package:granos_la_tradicion/features/home/home_screen.dart';
import 'package:granos_la_tradicion/features/auth/widgets/login_screen.dart';
import 'package:granos_la_tradicion/features/auth/widgets/register_screen.dart';
import 'package:granos_la_tradicion/features/auth/widgets/mfa_screen.dart';

import 'package:granos_la_tradicion/features/auth/screens/change_password_screen.dart';
import 'package:granos_la_tradicion/features/auth/screens/recover_username_screen.dart';
import 'package:granos_la_tradicion/features/auth/screens/forgot_password_screen.dart';
import 'package:granos_la_tradicion/features/auth/screens/reset_password_screen.dart';

import 'package:granos_la_tradicion/features/admin/admin_dashboard_screen.dart';
import 'package:granos_la_tradicion/features/admin/screens/admin_products_screen.dart';
import 'package:granos_la_tradicion/features/admin/screens/admin_orders_screen.dart';
import 'package:granos_la_tradicion/features/admin/screens/admin_dashboard_stats_screen.dart';
import 'package:granos_la_tradicion/features/admin/screens/admin_users_screen.dart';
import 'package:granos_la_tradicion/features/admin/screens/admin_activity_screen.dart';

import 'package:granos_la_tradicion/features/cliente/screens/cliente_dashboard_screen.dart';
import 'package:granos_la_tradicion/features/cliente/screens/profile_screen.dart';

import 'package:granos_la_tradicion/features/catalogo/screens/catalogo_screen.dart';
import 'package:granos_la_tradicion/features/carrito/screens/cart_screen.dart';

import 'package:granos_la_tradicion/features/pedidos/screens/orders_screen.dart';
import 'package:granos_la_tradicion/features/pedidos/screens/order_detail_screen.dart';
import 'package:granos_la_tradicion/features/pedidos/screens/order_success_screen.dart';
import 'package:granos_la_tradicion/features/pedidos/screens/payment_screen.dart';
import 'package:granos_la_tradicion/features/pedidos/models/order_model.dart';

import 'package:granos_la_tradicion/features/about/screens/about_screen.dart';

GoRouter appRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/',
    redirect: (context, state) {
      final bool isLoggedIn = authProvider.isAuthenticated;
      final UserRole? role = authProvider.currentUser?.role;
      final String path = state.uri.path;

      const protectedRoutes = <String>[
        '/admin',
        '/admin-products',
        '/admin-orders',
        '/admin/stats',
        '/admin-users',
        '/admin-activity',
        '/cliente',
        '/cart',
        '/orders',
        '/profile',
        '/order-success',
        '/order-detail',
        '/payment',
      ];

      const adminRoutes = <String>[
        '/admin',
        '/admin-products',
        '/admin-orders',
        '/admin/stats',
        '/admin-users',
        '/admin-activity',
      ];

      if (!isLoggedIn && protectedRoutes.contains(path)) {
        return '/login';
      }

      if (authProvider.requiresMFA) {
        if (path != '/mfa') {
          return '/mfa';
        }
      } else {
        if (path == '/mfa' && isLoggedIn) {
          if (role == UserRole.admin) return '/admin';
          if (role == UserRole.cliente) return '/cliente';
        }
      }

      if (isLoggedIn) {
        if (path == '/' || path == '/login' || path == '/register') {
          if (role == UserRole.admin) return '/admin';
          if (role == UserRole.cliente) return '/cliente';
        }

        if (adminRoutes.contains(path) && role != UserRole.admin) {
          return '/cliente';
        }

        if (path == '/cliente' && role != UserRole.cliente) {
          return '/admin';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/catalogo',
        builder: (context, state) => const CatalogoScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/order-detail',
        builder: (context, state) {
          if (state.extra == null) {
            return const ClienteDashboardScreen();
          }

          final order = state.extra as Order;
          return OrderDetailScreen(order: order);
        },
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          if (state.extra == null) {
            return const ClienteDashboardScreen();
          }

          final order = state.extra as Order;
          return PaymentScreen(order: order);
        },
      ),
      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          if (state.extra == null) {
            return const ClienteDashboardScreen();
          }

          final order = state.extra as Order;
          return OrderSuccessScreen(order: order);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/mfa',
        builder: (context, state) => const MFAScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/recover-username',
        builder: (context, state) => const RecoverUsernameScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin-products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin-orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/stats',
        builder: (context, state) => const AdminDashboardStatsScreen(),
      ),
      GoRoute(
        path: '/admin-users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin-activity',
        builder: (context, state) {
          final token = authProvider.token ?? "";
          return AdminActivityScreen(token: token);
        },
      ),
      GoRoute(
        path: '/cliente',
        builder: (context, state) => const ClienteDashboardScreen(),
      ),
    ],
  );
}