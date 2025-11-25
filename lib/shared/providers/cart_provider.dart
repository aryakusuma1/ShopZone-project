import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String _selectedDiscount = '';
  int _discountAmount = 0;
  String _shippingAddress = 'Jl. Tirto Utomo';

  // Getter untuk mendapatkan semua item di keranjang
  List<CartItem> get items => _items;

  // Getter untuk total jumlah item (quantity)
  int get itemCount => _items.fold(0, (total, item) => total + item.quantity);

  // Getter untuk jumlah tipe item yang berbeda (unique items)
  int get uniqueItemCount => _items.length;

  // Getter untuk total harga
  int get totalPrice =>
      _items.fold(0, (total, item) => total + item.totalPrice);

  // Getter untuk selected discount
  String get selectedDiscount => _selectedDiscount;

  // Getter untuk discount amount
  int get discountAmount => _discountAmount;

  // Getter untuk shipping address
  String get shippingAddress => _shippingAddress;

  // Getter untuk final price (setelah diskon)
  int get finalPrice => totalPrice - _discountAmount;

  // Getter untuk available discounts based on total price
  List<Map<String, dynamic>> get availableDiscounts {
    List<Map<String, dynamic>> discounts = [];

    if (totalPrice >= 2000000) {
      discounts.add({
        'id': 'DISC_2M',
        'name': 'Diskon Pembelian 2 Juta',
        'description': 'Diskon 5% untuk pembelian di atas Rp2.000.000',
        'percentage': 5,
        'amount': (totalPrice * 0.05).round(),
      });
    }

    if (totalPrice >= 5000000) {
      discounts.add({
        'id': 'DISC_5M',
        'name': 'Diskon Pembelian 5 Juta',
        'description': 'Diskon 10% untuk pembelian di atas Rp5.000.000',
        'percentage': 10,
        'amount': (totalPrice * 0.10).round(),
      });
    }

    if (totalPrice >= 10000000) {
      discounts.add({
        'id': 'DISC_10M',
        'name': 'Diskon Pembelian 10 Juta',
        'description': 'Diskon 15% untuk pembelian di atas Rp10.000.000',
        'percentage': 15,
        'amount': (totalPrice * 0.15).round(),
      });
    }

    return discounts;
  }

  // Format harga ke Rupiah
  String get formattedTotalPrice {
    return 'Rp${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String get formattedFinalPrice {
    return 'Rp${finalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String get formattedDiscountAmount {
    if (_discountAmount == 0) return '-';
    return 'Rp${_discountAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Tambah item ke keranjang
  void addItem(Product product) {
    // Cek apakah produk sudah ada di keranjang
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Jika sudah ada, tambah quantity
      _items[existingIndex].quantity++;
    } else {
      // Jika belum ada, tambah item baru
      _items.add(CartItem(product: product, quantity: 1));
    }

    // Recalculate discount jika ada
    _recalculateDiscount();

    notifyListeners();
  }

  // Update quantity item
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = newQuantity;

      // Recalculate discount jika ada
      _recalculateDiscount();

      notifyListeners();
    }
  }

  // Increase quantity
  void increaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity++;

      // Recalculate discount jika ada
      _recalculateDiscount();

      notifyListeners();
    }
  }

  // Decrease quantity
  void decreaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;

        // Recalculate discount jika ada
        _recalculateDiscount();

        notifyListeners();
      } else {
        removeItem(productId);
      }
    }
  }

  // Hapus item dari keranjang
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);

    // Recalculate discount jika ada
    _recalculateDiscount();

    notifyListeners();
  }

  // Clear semua item
  void clearCart() {
    _items.clear();
    _selectedDiscount = '';
    _discountAmount = 0;
    notifyListeners();
  }

  // Apply discount by ID
  void applyDiscount(String discountId, int amount) {
    _selectedDiscount = discountId;
    _discountAmount = amount;
    notifyListeners();
  }

  // Remove discount
  void removeDiscount() {
    _selectedDiscount = '';
    _discountAmount = 0;
    notifyListeners();
  }

  // Recalculate discount when cart changes
  void _recalculateDiscount() {
    if (_selectedDiscount.isEmpty) return;

    // Tentukan percentage berdasarkan discount ID yang aktif
    int percentage = 0;
    int minAmount = 0;

    switch (_selectedDiscount) {
      case 'DISC_2M':
        percentage = 5;
        minAmount = 2000000;
        break;
      case 'DISC_5M':
        percentage = 10;
        minAmount = 5000000;
        break;
      case 'DISC_10M':
        percentage = 15;
        minAmount = 10000000;
        break;
    }

    // Jika total price masih memenuhi syarat, hitung ulang discount
    if (totalPrice >= minAmount) {
      _discountAmount = (totalPrice * percentage / 100).round();
    } else {
      // Jika tidak memenuhi syarat lagi, coba downgrade ke tier yang lebih rendah
      if (totalPrice >= 5000000 && _selectedDiscount == 'DISC_10M') {
        // Downgrade ke DISC_5M
        _selectedDiscount = 'DISC_5M';
        _discountAmount = (totalPrice * 0.10).round();
      } else if (totalPrice >= 2000000 &&
          (_selectedDiscount == 'DISC_5M' || _selectedDiscount == 'DISC_10M')) {
        // Downgrade ke DISC_2M
        _selectedDiscount = 'DISC_2M';
        _discountAmount = (totalPrice * 0.05).round();
      } else {
        // Hapus discount jika tidak memenuhi syarat sama sekali
        _selectedDiscount = '';
        _discountAmount = 0;
      }
    }
  }

  // Update shipping address
  void updateAddress(String address) {
    _shippingAddress = address;
    notifyListeners();
  }

  // Cek apakah produk sudah ada di keranjang
  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  // Get quantity produk di keranjang
  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(
        product: Product(
          id: '',
          name: '',
          price: 0,
          imageUrl: '',
          category: '',
          condition: 'baru', // Provide a default condition
        ),
        quantity: 0,
      ),
    );
    return item.quantity;
  }
}
