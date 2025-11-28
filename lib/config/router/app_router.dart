// lib/config/router/app_router.dart - Actualizado
import 'package:go_router/go_router.dart';
import 'package:push_app_new/presentation/screens/details_screen.dart';
import 'package:push_app_new/presentation/screens/home_screen.dart';
import 'package:push_app_new/presentation/screens/products_screen.dart';
import 'package:push_app_new/presentation/screens/product_form_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/push-details/:messageId',
      builder: (context, state) => DetailsScreen(
        pushMessageId: state.pathParameters['messageId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductsScreen(),
    ),
    GoRoute(
      path: '/products/add',
      builder: (context, state) => const ProductFormScreen(),
    ),
    GoRoute(
      path: '/products/edit/:productId',
      builder: (context, state) => ProductFormScreen(
        productId: state.pathParameters['productId'],
      ),
    ),
  ],
);