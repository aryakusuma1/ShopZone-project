import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopzone/core/constants/colors.dart';
import 'package:shopzone/core/constants/text_styles.dart';
import 'package:shopzone/shared/models/product.dart';
import 'package:shopzone/shared/widgets/product_card.dart';
import 'package:shopzone/routes/app_routes.dart';

class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({super.key});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSortTab = 'Terlaris';
  String? _selectedCondition;
  String? _selectedRating;
  List<Product> _displayedProducts = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = ModalRoute.of(context)!.settings.arguments as String?;
    if (query != null && query.isNotEmpty && _searchController.text.isEmpty) {
      _searchController.text = query;
    }
  }

  Widget _buildSortTab(String title) {
    final bool isSelected = _selectedSortTab == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSortTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            hint: Text(
              hint,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            value: value,
            items: items,
            onChanged: onChanged,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
            dropdownColor: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? priceDropdownValue;
    if (_selectedSortTab == 'Termurah' || _selectedSortTab == 'Termahal') {
      priceDropdownValue = _selectedSortTab;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
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
            readOnly: true,
            onTap: () => Navigator.pushReplacementNamed(
              context,
              AppRoutes.search,
              arguments: _searchController.text,
            ),
            decoration: InputDecoration(
              hintText: 'Cari di Belanja',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildFilterDropdown(
                      hint: 'Harga',
                      value: priceDropdownValue,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("Harga"),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'Termurah',
                          child: Text('Termurah'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'Termahal',
                          child: Text('Termahal'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSortTab = value ?? 'Terlaris';
                        });
                      },
                    ),
                    _buildFilterDropdown(
                      hint: 'Kategori',
                      value: _selectedCondition,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("Kategori"),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'Baru',
                          child: Text('Baru'),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'Bekas',
                          child: Text('Bekas'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedCondition = value),
                    ),
                    _buildFilterDropdown(
                      hint: 'Rating',
                      value: _selectedRating,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("Rating"),
                        ),
                        ...['5', '4', '3', '2', '1'].map((rating) {
                          return DropdownMenuItem(
                            value: rating,
                            child: Row(
                              children: [
                                Text(rating),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedRating = value),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildSortTab('Terlaris'),
                    const SizedBox(width: 8),
                    _buildSortTab('Termurah'),
                    const SizedBox(width: 8),
                    _buildSortTab('Terverifikasi'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildProductQuery().snapshots(),
              builder: (context, snapshot) {
                // Show loading indicator at the top while preserving old data
                final isLoading = snapshot.connectionState == ConnectionState.waiting;

                if (snapshot.hasData) {
                  // New data is available, update the displayed products
                  final products = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    return Product.fromJson(data);
                  }).toList();

                  // Apply client-side search filtering
                  final searchQuery = _searchController.text.toLowerCase();
                  if (searchQuery.isNotEmpty) {
                    _displayedProducts = products.where((product) {
                      return product.name.toLowerCase().contains(searchQuery);
                    }).toList();
                  } else {
                    _displayedProducts = products;
                  }
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi Error: ${snapshot.error}'),
                  );
                }

                return Column(
                  children: [
                    // Non-intrusive loading indicator
                    if (isLoading) const LinearProgressIndicator(minHeight: 2),
                    Expanded(
                      child: _displayedProducts.isEmpty
                          ? Center(
                              child: isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Tidak ada produk yang cocok.'),
                            )
                          : Container(
                              color: AppColors.background,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.65,
                                ),
                                itemCount: _displayedProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _displayedProducts[index];
                                  return ProductCard(
                                    product: product,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.productDetail,
                                      arguments: product,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Query _buildProductQuery() {
    Query query = FirebaseFirestore.instance.collection('products');

    // Sorting logic based on the selected tab
    switch (_selectedSortTab) {
      case 'Terlaris':
        query = query.orderBy('sold', descending: true);
        break;
      case 'Termurah':
        query = query.orderBy('price', descending: false);
        break;
      case 'Termahal':
        query = query.orderBy('price', descending: true);
        break;
      case 'Terverifikasi':
        query = query.where('verified', isEqualTo: true);
        break;
      default:
        query = query.orderBy('sold', descending: true); // Default to Terlaris
    }

    // Condition filter
    if (_selectedCondition != null) {
      query = query.where('condition', isEqualTo: _selectedCondition);
    }

    // Rating filter - Note: Firestore doesn't support inequality on multiple fields well.
    // This part might need client-side filtering if combined with other range filters.
    if (_selectedRating != null) {
      final minRating = double.tryParse(_selectedRating!);
      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }
    }

    return query;
  }
}
