import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../features/splash/pages/splash_page.dart';
import '../features/home/pages/home_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/search/pages/search_page.dart';
import '../features/search/pages/search_results_page.dart';
import '../features/product/pages/product_detail_page.dart';
import '../features/cart/pages/cart_page.dart';
import '../features/order/pages/orders_page.dart';
import '../features/order/pages/order_detail_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../shared/models/product.dart';
import '../shared/models/order.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchPage());

      case AppRoutes.searchResults:
        final args = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => SearchResultsPage(initialQuery: args),
        );

      case AppRoutes.productDetail:
        final product = settings.arguments as Product;
        return MaterialPageRoute(
          builder: (_) => ProductDetailPage(product: product),
        );

      case AppRoutes.cart:
        return MaterialPageRoute(builder: (_) => const CartPage());

      case AppRoutes.orders:
        return MaterialPageRoute(builder: (_) => const OrdersPage());

      case AppRoutes.orderDetail:
        final order = settings.arguments as Order;
        return MaterialPageRoute(
          builder: (_) => OrderDetailPage(order: order),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
