import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../features/home/pages/home_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/search/pages/search_page.dart';
import '../features/search/pages/search_results_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
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

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
