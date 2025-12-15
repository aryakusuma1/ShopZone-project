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
import '../features/order/pages/complaint_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/profile/pages/account_page.dart';
import '../features/profile/pages/refund_page.dart';
import '../features/profile/pages/refund_detail_page.dart';
import '../features/address/pages/select_address_page.dart';
import '../features/address/pages/add_edit_address_page.dart';
import '../features/profile/pages/about_page.dart';
import '../features/profile/pages/help_page.dart';
import '../features/admin/pages/admin_dashboard_page.dart';
import '../features/admin/pages/admin_products_page.dart';
import '../features/admin/pages/admin_add_edit_product_page.dart';
import '../features/admin/pages/admin_manage_refund_page.dart';
import '../features/admin/pages/admin_migrate_products_page.dart';
import '../shared/models/product.dart';
import '../shared/models/order.dart';
import '../shared/models/refund.dart';

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
          builder: (_) => const SearchResultsPage(),
          settings: settings, // Pass settings directly so SearchResultsPage can access arguments
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

      case AppRoutes.complaint:
        final order = settings.arguments as Order;
        return MaterialPageRoute(
          builder: (_) => ComplaintPage(order: order),
        );

      case AppRoutes.refund:
        return MaterialPageRoute(builder: (_) => const RefundPage());

      case AppRoutes.refundDetail:
        final refund = settings.arguments as Refund;
        return MaterialPageRoute(
          builder: (_) => RefundDetailPage(refund: refund),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case AppRoutes.account:
        return MaterialPageRoute(builder: (_) => const AccountPage());

      case AppRoutes.selectAddress:
        return MaterialPageRoute(builder: (_) => const SelectAddressPage());

      case AppRoutes.addEditAddress:
        final args = settings.arguments as Map<String, dynamic>?;
        final isMainAddress = args?['isMainAddress'] as bool? ?? false;
        final existingAddress = args?['existingAddress'];
        return MaterialPageRoute(
          builder: (_) => AddEditAddressPage(
            isMainAddress: isMainAddress,
            existingAddress: existingAddress,
          ),
        );

      case AppRoutes.help:
        return MaterialPageRoute(builder: (_) => const HelpPage());

      case AppRoutes.about:
        return MaterialPageRoute(builder: (_) => const AboutPage());

      // Admin routes
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardPage());

      case AppRoutes.adminProducts:
        return MaterialPageRoute(builder: (_) => const AdminProductsPage());

      case AppRoutes.adminAddEditProduct:
        return MaterialPageRoute(
          builder: (_) => const AdminAddEditProductPage(),
          settings: settings,
        );
      
      case AppRoutes.adminRefunds:
        return MaterialPageRoute(builder: (_) => const AdminManageRefundPage());

      case AppRoutes.adminMigrateProducts:
        return MaterialPageRoute(builder: (_) => const AdminMigrateProductsPage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
