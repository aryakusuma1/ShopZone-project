import 'package:flutter/material.dart';
import 'package:shopzone/core/constants/colors.dart';
import 'package:shopzone/core/constants/text_styles.dart';
import 'package:shopzone/features/home/data/dummy_products.dart';
import 'package:shopzone/shared/models/product.dart';
import 'package:shopzone/shared/widgets/product_card.dart';
import 'package:shopzone/routes/app_routes.dart'; // Import app_routes

class SearchResultsPage extends StatefulWidget {
  final String? initialQuery;
  const SearchResultsPage({super.key, this.initialQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _selectedSortTab = 'Terlaris'; // Terlaris, Termurah, Terdekat
  String? _selectedPriceFilter;
  String? _selectedCategoryFilter;
  String? _selectedRatingFilter;
  bool _showResults = false; // New state to control visibility of results area

  @override
  void initState() {
    super.initState();
    _allProducts = DummyProducts.getAllProductsWithExtra();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _showResults = true; // Show results if an initial query is provided
      _filterAndSortProducts(); // Filter immediately
    }
    // No need for _searchController.addListener(_onQueryChanged) as it's read-only
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAndSortProducts() {
    List<Product> tempProducts = _allProducts.where((product) {
      final query = _searchController.text.toLowerCase();
      final matchesQuery = product.name.toLowerCase().contains(query);

      // Apply price filter
      bool matchesPriceFilter = true;
      if (_selectedPriceFilter != null) {
        if (_selectedPriceFilter == '< Rp500rb') {
          matchesPriceFilter = product.price < 500000;
        } else if (_selectedPriceFilter == 'Rp500rb - Rp1jt') {
          matchesPriceFilter =
              product.price >= 500000 && product.price <= 1000000;
        } else if (_selectedPriceFilter == '> Rp1jt') {
          matchesPriceFilter = product.price > 1000000;
        }
      }

      // Apply category filter
      final matchesCategoryFilter =
          _selectedCategoryFilter == null ||
          product.category.toLowerCase() ==
              _selectedCategoryFilter!.toLowerCase();

      // Apply rating filter
      bool matchesRatingFilter = true;
      if (_selectedRatingFilter != null) {
        if (_selectedRatingFilter == '4+') {
          matchesRatingFilter = product.rating >= 4;
        } else if (_selectedRatingFilter == '3+') {
          matchesRatingFilter = product.rating >= 3;
        } else if (_selectedRatingFilter == '2+') {
          matchesRatingFilter = product.rating >= 2;
        }
      }

      return matchesQuery &&
          matchesPriceFilter &&
          matchesCategoryFilter &&
          matchesRatingFilter;
    }).toList();

    // Apply sorting
    switch (_selectedSortTab) {
      case 'Terlaris':
        tempProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Termurah':
        tempProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Terdekat':
        // No geographical data, so just maintain current order or default to relevance
        break;
    }

    setState(() {
      _filteredProducts = tempProducts;
    });
  }

  // _onQueryChanged is no longer needed since the search bar is read-only
  // void _onQueryChanged() {
  //   _filterAndSortProducts();
  // }

  void _onSortTabChanged(String tab) {
    setState(() {
      _selectedSortTab = tab;
    });
    _filterAndSortProducts(); // Re-perform search with new sorting
  }

  void _showPriceFilter(BuildContext context) {
    final List<String> priceOptions = [
      'Semua Harga',
      '< Rp500rb',
      'Rp500rb - Rp1jt',
      '> Rp1jt',
    ];
    _showFilterBottomSheet(
      context: context,
      title: 'Harga',
      options: priceOptions,
      selectedOption: _selectedPriceFilter ?? 'Semua Harga',
      onSelected: (option) {
        setState(() {
          _selectedPriceFilter = option == 'Semua Harga' ? null : option;
        });
        _filterAndSortProducts(); // Re-perform search with new filter
      },
    );
  }

  void _showCategoryFilter(BuildContext context) {
    final List<String> categories = [
      'Semua Kategori',
      ..._allProducts.map((p) => p.category).toSet().toList(),
    ];
    _showFilterBottomSheet(
      context: context,
      title: 'Kategori',
      options: categories,
      selectedOption: _selectedCategoryFilter ?? 'Semua Kategori',
      onSelected: (option) {
        setState(() {
          _selectedCategoryFilter = option == 'Semua Kategori' ? null : option;
        });
        _filterAndSortProducts(); // Re-perform search with new filter
      },
    );
  }

  void _showRatingFilter(BuildContext context) {
    final List<String> ratingOptions = ['Semua Rating', '4+', '3+', '2+'];
    _showFilterBottomSheet(
      context: context,
      title: 'Rating',
      options: ratingOptions,
      selectedOption: _selectedRatingFilter ?? 'Semua Rating',
      onSelected: (option) {
        setState(() {
          _selectedRatingFilter = option == 'Semua Rating' ? null : option;
        });
        _filterAndSortProducts(); // Re-perform search with new filter
      },
    );
  }

  void _showFilterBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String selectedOption,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              ...options.map(
                (option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedOption,
                  onChanged: (value) {
                    if (value != null) {
                      onSelected(value);
                      Navigator.pop(context);
                    }
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onPressed,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTab(String title) {
    final bool isSelected = _selectedSortTab == title;

    return GestureDetector(
      onTap: () => _onSortTabChanged(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Navigate back to SearchPage and pass the current query
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.search,
              arguments: _searchController.text,
            );
          },
        ),
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextFormField(
            controller: _searchController,
            readOnly: true, // Make it read-only
            onTap: () {
              // Navigate back to SearchPage when the search bar is tapped
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.search,
                arguments: _searchController.text,
              );
            },
            decoration: InputDecoration(
              hintText: 'Cari di Belanja',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        // No filtering needed here as it's read-only
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips and Sorting Tabs visible only if results are shown
          if (_showResults) ...[
            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: _selectedPriceFilter ?? 'Harga',
                    onPressed: () => _showPriceFilter(context),
                    isSelected: _selectedPriceFilter != null,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _selectedCategoryFilter ?? 'Kategori',
                    onPressed: () => _showCategoryFilter(context),
                    isSelected: _selectedCategoryFilter != null,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _selectedRatingFilter ?? 'Rating',
                    onPressed: () => _showRatingFilter(context),
                    isSelected: _selectedRatingFilter != null,
                  ),
                ],
              ),
            ),
            // Category Tabs (Terlaris, Termurah, Terdekat)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  _buildSortTab('Terlaris'),
                  const SizedBox(width: 16),
                  _buildSortTab('Termurah'),
                  const SizedBox(width: 16),
                  _buildSortTab('Terdekat'),
                ],
              ),
            ),
          ],
          Expanded(
            child: _showResults
                ? (_filteredProducts.isEmpty
                      ? const Center(child: Text('No products found.'))
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.65,
                                ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return ProductCard(
                                product: product,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.productDetail,
                                    arguments: product,
                                  );
                                },
                              );
                            },
                          ),
                        ))
                : const Center(
                    child: Text('Enter a search term to see results.'),
                  ),
          ),
        ],
      ),
    );
  }
}
