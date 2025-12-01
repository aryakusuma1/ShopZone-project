import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopzone/core/constants/colors.dart';
import 'package:shopzone/core/constants/text_styles.dart';
import 'package:shopzone/routes/app_routes.dart';
import 'package:shopzone/shared/models/product.dart';
import 'package:shopzone/shared/widgets/product_card.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _suggestions = [];
  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _onSearchChanged(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isNotEmpty) {
        _suggestions = _allProducts
            .where((product) =>
                product.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _suggestions = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title: Container( // Changed from Expanded to Container
          child: Container(
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: TextFormField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              onFieldSubmitted: (query) {
                if (query.isNotEmpty) {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.searchResults,
                    arguments: query,
                  );
                }
              },
              decoration: InputDecoration(
                isDense: true,
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
                contentPadding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          _allProducts = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Include document ID in the data
            return Product.fromJson(data);
          }).toList();

          return _suggestions.isNotEmpty
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
                            final product = _suggestions[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                              title: Text(
                                product.name,
                                style: AppTextStyles.bodyMedium,
                              ),
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.searchResults,
                                  arguments: product.name,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : Container();
        },
      ),
    );
  }
}
