import 'package:flutter/material.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../data/dummy_products.dart';
import '../../../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State untuk tab yang aktif
  String selectedTab = 'Terlaris';
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      switch (selectedTab) {
        case 'Terlaris':
          products = DummyProducts.sortByRating();
          break;
        case 'Termurah':
          products = DummyProducts.sortByPriceAsc();
          break;
        case 'Terlaku':
          products = DummyProducts.getAllProducts();
          break;
        default:
          products = DummyProducts.getAllProducts();
      }
    });
  }

  void _onTabChanged(String tab) {
    setState(() {
      selectedTab = tab;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('ShopZone', style: AppTextStyles.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () {
              // TODO: Navigate to cart page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart page - Coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              // TODO: Navigate to profile page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile page - Coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to login and remove all previous routes
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                // Navigate to the SearchPage (suggestions page)
                Navigator.pushNamed(context, AppRoutes.search);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      'Cari di Belanja',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Promo Banner (Placeholder - 20% Diskon seperti di Figma)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '20% Diskon',
                    style: AppTextStyles.heading1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Untuk semua produk',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Belanja Sekarang',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category Tabs (Terlaris, Termurah, Terlaku)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildTab('Terlaris'),
                const SizedBox(width: 16),
                _buildTab('Termurah'),
                const SizedBox(width: 16),
                _buildTab('Terlaku'),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      // TODO: Navigate to product detail page
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Product detail: ${product.name}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Katalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: (index) {
          // TODO: Handle bottom nav tap
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tab $index clicked - Coming soon!')),
          );
        },
      ),
    );
  }

  Widget _buildTab(String title) {
    final bool isSelected = selectedTab == title;

    return GestureDetector(
      onTap: () => _onTabChanged(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent, // Background tetap transparan
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
