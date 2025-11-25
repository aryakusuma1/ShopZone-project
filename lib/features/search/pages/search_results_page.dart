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
  final GlobalKey _searchBarKey =
      GlobalKey(); // New GlobalKey for the search bar
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _selectedSortTab = 'Terlaris'; // Terlaris, Termurah, Terdekat
  String? _selectedPriceFilter;
  String? _selectedConditionFilter; // Renamed from _selectedCategoryFilter
  String? _selectedRatingFilter;
  bool _showResults = false; // New state to control visibility of results area

  // State for dropdown visibility
  OverlayEntry? _priceDropdownOverlay;
  OverlayEntry?
  _conditionDropdownOverlay; // Renamed from _categoryDropdownOverlay
  OverlayEntry? _ratingDropdownOverlay;

  final GlobalKey _priceChipKey = GlobalKey();
  final GlobalKey _conditionChipKey =
      GlobalKey(); // Renamed from _categoryChipKey
  final GlobalKey _ratingChipKey = GlobalKey();

  // Options for filters
  final List<String> _priceOptions = ['Harga', 'Termurah', 'Termahal'];
  final List<String> _conditionOptions = [
    'Kondisi',
    'baru',
    'bekas',
  ]; // Changed from _categoryOptions
  final List<String> _ratingOptions = ['Rating', '5', '4', '3', '2', '1'];

  @override
  void initState() {
    super.initState();
    _allProducts = DummyProducts.getAllProductsWithExtra();

    // Populate category options based on dummy products
    // _categoryOptions is now hardcoded as _conditionOptions, no dynamic population

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _showResults = true; // Show results if an initial query is provided
      _filterAndSortProducts(); // Filter immediately
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hideDropdownOverlay(_priceDropdownOverlay);
    _hideDropdownOverlay(_conditionDropdownOverlay); // Updated
    _hideDropdownOverlay(_ratingDropdownOverlay);
    super.dispose();
  }

  void _filterAndSortProducts() {
    List<Product> tempProducts = _allProducts.where((product) {
      final query = _searchController.text.toLowerCase();
      final matchesQuery = product.name.toLowerCase().contains(query);

      // Apply price filter
      bool matchesPriceFilter = true;
      if (_selectedPriceFilter != null) {
        if (_selectedPriceFilter == 'Termurah') {
          // This will be handled by sorting, not direct filtering
        } else if (_selectedPriceFilter == 'Termahal') {
          // This will be handled by sorting, not direct filtering
        }
        // Specific price range filtering logic would go here if needed.
        // For now, these are only for sorting, not initial price range filtering.
      }

      // Apply condition filter
      final matchesConditionFilter =
          _selectedConditionFilter == null ||
          _selectedConditionFilter == 'Kondisi' ||
          product.condition.toLowerCase() ==
              _selectedConditionFilter!.toLowerCase();

      // Apply rating filter
      bool matchesRatingFilter = true;
      if (_selectedRatingFilter != null && _selectedRatingFilter != 'Rating') {
        matchesRatingFilter =
            product.rating >= double.parse(_selectedRatingFilter!);
      }

      return matchesQuery &&
          matchesPriceFilter &&
          matchesConditionFilter && // Updated
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

  void _onSortTabChanged(String tab) {
    setState(() {
      _selectedSortTab = tab;
    });
    // Close any open dropdowns when changing sort tab
    _hideAllDropdowns();
    _filterAndSortProducts(); // Re-perform search with new sorting
  }

  void _hideAllDropdowns() {
    _hideDropdownOverlay(_priceDropdownOverlay);
    _hideDropdownOverlay(_conditionDropdownOverlay); // Updated
    _hideDropdownOverlay(_ratingDropdownOverlay);
    _priceDropdownOverlay = null;
    _conditionDropdownOverlay = null; // Updated
    _ratingDropdownOverlay = null;
  }

  void _showDropdownOverlay(
    GlobalKey chipKey,
    List<String> options,
    String? selectedValue,
    ValueChanged<String> onSelected,
    OverlayEntry? currentOverlay,
    Function(OverlayEntry?) updateOverlay,
  ) {
    if (currentOverlay != null) {
      _hideDropdownOverlay(currentOverlay);
      updateOverlay(null);
      return;
    }

    // Close any other open dropdowns and nullify their state immediately
    if (chipKey != _priceChipKey && _priceDropdownOverlay != null) {
      _hideDropdownOverlay(_priceDropdownOverlay);
      _priceDropdownOverlay = null;
    }
    if (chipKey != _conditionChipKey && _conditionDropdownOverlay != null) {
      // Updated
      _hideDropdownOverlay(_conditionDropdownOverlay); // Updated
      _conditionDropdownOverlay = null; // Updated
    }
    if (chipKey != _ratingChipKey && _ratingDropdownOverlay != null) {
      _hideDropdownOverlay(_ratingDropdownOverlay);
      _ratingDropdownOverlay = null;
    }

    // Get the position and size of the tapped chip for alignment
    final RenderBox? chipRenderBox =
        chipKey.currentContext?.findRenderObject() as RenderBox?;
    if (chipRenderBox == null) return;

    final chipOffset = chipRenderBox.localToGlobal(Offset.zero);
    final chipSize = chipRenderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    final double topPosition = chipOffset.dy + chipSize.height + 4; // 4px padding
    double leftPosition = chipOffset.dx;
    const double dropdownWidth = 180.0; // A reasonable fixed width

    // Adjust left position to prevent overflow from the right edge
    if (leftPosition + dropdownWidth > screenWidth) {
      leftPosition = screenWidth - dropdownWidth - 16; // 16px padding from edge
    }
    
    // Ensure it doesn't go off-screen on the left (though less likely with this setup)
    if (leftPosition < 16) {
      leftPosition = 16;
    }

    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: topPosition,
          left: leftPosition,
          width: dropdownWidth,
          child: Material(
            color: Colors.transparent,
            child: _buildDropdownContent(
              options: options,
              selectedValue: selectedValue,
              onSelected: (option) {
                onSelected(option);
                _hideAllDropdowns();
              },
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
    updateOverlay(overlayEntry);
  }

  void _hideDropdownOverlay(OverlayEntry? overlayEntry) {
    overlayEntry?.remove();
  }

  Widget _buildDropdownContent({
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align dropdown content to start
          children: options.map((option) {
            return InkWell(
              onTap: () => onSelected(option),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      // Wrap text with Expanded to prevent overflow
                      child: Text(
                        option,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: selectedValue == option
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selectedValue == option
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (option == '5' ||
                        option == '4' ||
                        option == '3' ||
                        option == '2' ||
                        option == '1')
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Icon(Icons.star, color: Colors.amber, size: 16),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSortTab(String title) {
    final bool isSelected = _selectedSortTab == title;
    return GestureDetector(
      onTap: () => _onSortTabChanged(title),
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
        title: Expanded(
          // Wrap the Container with Expanded to give it maximum width
          child: Container(
            key:
                _searchBarKey, // Assign the GlobalKey to the search bar container
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
              textAlignVertical:
                  TextAlignVertical.center, // Added for vertical alignment
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, // Adjusted to 8 for more horizontal space
                  vertical: 0,
                ), // Adjusted padding
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        // Use Stack to overlay dropdowns
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips
              if (_showResults) // Show filters only if results are shown
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Wrap(
                    alignment:
                        WrapAlignment.start, // Explicitly left-align chips
                    spacing: 8.0, // Space between chips
                    runSpacing: 8.0, // Space between lines of chips
                    children: [
                      // Price Filter Chip
                      GestureDetector(
                        key: _priceChipKey,
                        onTap: () {
                          _showDropdownOverlay(
                            _priceChipKey,
                            _priceOptions,
                            _selectedPriceFilter,
                            (option) {
                              setState(() {
                                _selectedPriceFilter = option;
                              });
                              _filterAndSortProducts();
                            },
                            _priceDropdownOverlay,
                            (overlay) => _priceDropdownOverlay = overlay,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _priceDropdownOverlay != null
                                ? AppColors.primary
                                : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _priceDropdownOverlay != null
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedPriceFilter ?? 'Harga',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _priceDropdownOverlay != null
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: _priceDropdownOverlay != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _priceDropdownOverlay != null
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 16,
                                color: _priceDropdownOverlay != null
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Condition Filter Chip (formerly Category Filter)
                      GestureDetector(
                        key: _conditionChipKey, // Updated
                        onTap: () {
                          _showDropdownOverlay(
                            _conditionChipKey, // Updated
                            _conditionOptions, // Updated
                            _selectedConditionFilter, // Updated
                            (option) {
                              setState(() {
                                _selectedConditionFilter = option; // Updated
                              });
                              _filterAndSortProducts();
                            },
                            _conditionDropdownOverlay, // Updated
                            (overlay) =>
                                _conditionDropdownOverlay = overlay, // Updated
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _conditionDropdownOverlay !=
                                    null // Updated
                                ? AppColors.primary
                                : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  _conditionDropdownOverlay !=
                                      null // Updated
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedConditionFilter ??
                                    'Kondisi', // Updated text
                                style: AppTextStyles.bodySmall.copyWith(
                                  color:
                                      _conditionDropdownOverlay !=
                                          null // Updated
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight:
                                      _conditionDropdownOverlay !=
                                          null // Updated
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _conditionDropdownOverlay !=
                                        null // Updated
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 16,
                                color:
                                    _conditionDropdownOverlay !=
                                        null // Updated
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Rating Filter Chip
                      GestureDetector(
                        key: _ratingChipKey,
                        onTap: () {
                          _showDropdownOverlay(
                            _ratingChipKey,
                            _ratingOptions,
                            _selectedRatingFilter,
                            (option) {
                              setState(() {
                                _selectedRatingFilter = option;
                              });
                              _filterAndSortProducts();
                            },
                            _ratingDropdownOverlay,
                            (overlay) => _ratingDropdownOverlay = overlay,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _ratingDropdownOverlay != null
                                ? AppColors.primary
                                : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _ratingDropdownOverlay != null
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedRatingFilter ?? 'Rating',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _ratingDropdownOverlay != null
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: _ratingDropdownOverlay != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _ratingDropdownOverlay != null
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 16,
                                color: _ratingDropdownOverlay != null
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ], // Close children list for Wrap
                  ),
                ),
              // Category Tabs (Terlaris, Termurah, Terdekat)
              if (_showResults)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
        ],
      ),
    );
  }
}
