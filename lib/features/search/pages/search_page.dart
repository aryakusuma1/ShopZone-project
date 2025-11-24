import 'package:flutter/material.dart';
import 'package:shopzone/core/constants/colors.dart';
import 'package:shopzone/core/constants/text_styles.dart';
import 'package:shopzone/routes/app_routes.dart';
import 'package:shopzone/features/home/data/dummy_products.dart'; // Import dummy products
import 'package:shopzone/shared/models/product.dart'; // Import Product model

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];
  List<String> _allProductNames = []; // List to hold all product names

  @override
  void initState() {
    super.initState();
    // Populate all product names from dummy data
    _allProductNames = DummyProducts.getAllProductsWithExtra()
        .map((product) => product.name)
        .toList();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _onSearchChanged(
      _searchController.text,
    ); // Initialize suggestions based on initialQuery
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isNotEmpty) {
        _suggestions = _allProductNames
            .where((name) => name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _suggestions = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextFormField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            onFieldSubmitted: (query) {
              if (query.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.searchResults,
                  arguments: query,
                );
              }
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
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ),
      body: _suggestions.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text('Suggestions', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          title: Text(
                            suggestion,
                            style: AppTextStyles.bodyMedium,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.searchResults,
                              arguments: suggestion,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : Container(), // Empty container if no suggestions
    );
  }
}
