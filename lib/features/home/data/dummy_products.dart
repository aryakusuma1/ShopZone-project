import '../../../shared/models/product.dart';

/// Dummy Data Produk - Untuk development awal
/// Nanti akan diganti dengan data dari Firebase/API
class DummyProducts {
  static List<Product> getAllProducts() {
    return [
      Product(
        id: '1',
        name: 'Hyperdenim',
        price: 1500000,
        imageUrl: 'assets/images/Hyperdenim.jpeg',
        category: 'Sepatu',
        condition: 'baru',
        size: '41',
        color: 'Biru',
        material: 'Denim',
        description:
            'Sepatu dengan desain denim yang unik dan stylish untuk tampilan casual.',
        rating: 4.5,
        verified: true,
        userPhotos: [
          'assets/images/Hyperdenim.jpeg',
          'assets/images/Hyperdenim.jpeg',
          'assets/images/Hyperdenim.jpeg',
        ],
      ),
      Product(
        id: '2',
        name: 'Adidas x Oasis',
        price: 1850000,
        imageUrl: 'assets/images/Adidas x Oasis.png',
        category: 'Sepatu',
        condition: 'baru',
        size: '41',
        color: 'Putih',
        material: 'Leather',
        description:
            'Kolaborasi eksklusif Adidas x Oasis dengan desain limited edition.',
        rating: 4.8,
        verified: true,
        userPhotos: [
          'assets/images/Adidas x Oasis.png',
          'assets/images/Adidas x Oasis.png',
          'assets/images/Adidas x Oasis.png',
        ],
      ),
      Product(
        id: '3',
        name: 'Nike P-6000',
        price: 1650000,
        imageUrl: 'assets/images/NIKE P 6000.png',
        category: 'Sepatu',
        condition: 'bekas',
        size: '41',
        color: 'Silver',
        material: 'Mesh & Leather',
        description:
            'Running shoes dengan teknologi Nike P-6000 untuk kenyamanan maksimal.',
        rating: 4.6,
        verified: true,
        userPhotos: [
          'assets/images/NIKE P 6000.png',
          'assets/images/NIKE P 6000.png',
          'assets/images/NIKE P 6000.png',
        ],
      ),
      Product(
        id: '4',
        name: 'Nike Big Swoosh',
        price: 1750000,
        imageUrl: 'assets/images/NIKE Big Swoosh.png',
        category: 'Sepatu',
        condition: 'baru',
        size: '41',
        color: 'Hitam Putih',
        material: 'Leather & Synthetic',
        description:
            'Iconic Nike dengan logo swoosh besar yang bold dan striking.',
        rating: 4.7,
        verified: true,
        userPhotos: [
          'assets/images/NIKE Big Swoosh.png',
          'assets/images/NIKE Big Swoosh.png',
          'assets/images/NIKE Big Swoosh.png',
        ],
      ),
      Product(
        id: '5',
        name: "Adidas Campus 00's",
        price: 1450000,
        imageUrl: "assets/images/Adidas Campus 00's.png",
        category: 'Sepatu',
        condition: 'bekas',
        size: '41',
        color: 'Hijau',
        material: 'Suede',
        description:
            'Retro vibes dari era 2000-an dengan material suede premium.',
        rating: 4.9,
        verified: true,
        userPhotos: [
          "assets/images/Adidas Campus 00's.png",
          "assets/images/Adidas Campus 00's.png",
          "assets/images/Adidas Campus 00's.png",
        ],
      ),
      Product(
        id: '6',
        name: 'Air Jordan 1 Travis Scott',
        price: 12500000,
        imageUrl: 'assets/images/Air Jordan 1 Travis Scott.png',
        category: 'Sepatu',
        condition: 'bekas',
        size: '41',
        color: 'Brown',
        material: 'Leather & Suede',
        description:
            'Kolaborasi limited edition Travis Scott x Jordan Brand yang sangat langka.',
        rating: 5.0,
        verified: true,
        userPhotos: [
          'assets/images/Air Jordan 1 Travis Scott.png',
          'assets/images/Air Jordan 1 Travis Scott.png',
          'assets/images/Air Jordan 1 Travis Scott.png',
        ],
      ),
    ];
  }

  // Get all products including additional (untuk search, dll)
  static List<Product> getAllProductsWithExtra() {
    return [
      ...getAllProducts(), // 6 produk home
      // Produk tambahan untuk search/fitur lain
      Product(
        id: '7',
        name: 'Nike SB Dunk Low',
        price: 1950000,
        imageUrl: 'assets/images/Nike SB Dunk Low.png',
        category: 'Sepatu',
        condition: 'baru',
        size: '41',
        color: 'Multi',
        material: 'Leather',
        description:
            'Skateboarding shoes dengan padding ekstra untuk kenyamanan dan proteksi.',
        rating: 4.8,
        verified: true,
      ),
      Product(
        id: '8',
        name: 'Puma Palermo',
        price: 1250000,
        imageUrl: 'assets/images/Puma Palermo.png',
        category: 'Sepatu',
        condition: 'baru',
        size: '41',
        color: 'Hijau',
        material: 'Suede',
        description:
            'Classic terrace shoe yang terinspirasi dari budaya sepak bola Eropa.',
        rating: 4.4,
        verified: true,
      ),
      Product(
        id: '9',
        name: 'Puma Speedcat',
        price: 1550000,
        imageUrl: 'assets/images/Puma Speedcat.png',
        category: 'Sepatu',
        condition: 'bekas',
        size: '41',
        color: 'Hitam Merah',
        material: 'Leather & Synthetic',
        description:
            'Racing-inspired shoes dengan desain sporty dan aerodinamis.',
        rating: 4.7,
        verified: true,
      ),
    ];
  }

  // Get products by category
  static List<Product> getProductsByCategory(String category) {
    return getAllProducts().where((p) => p.category == category).toList();
  }

  // Get verified products
  static List<Product> getVerifiedProducts() {
    return getAllProducts().where((p) => p.verified).toList();
  }

  // Sort by price (termurah)
  static List<Product> sortByPriceAsc() {
    final products = getAllProducts();
    products.sort((a, b) => a.price.compareTo(b.price));
    return products;
  }

  // Sort by price (termahal)
  static List<Product> sortByPriceDesc() {
    final products = getAllProducts();
    products.sort((a, b) => b.price.compareTo(a.price));
    return products;
  }

  // Sort by rating (terlaris)
  static List<Product> sortByRating() {
    final products = getAllProducts();
    products.sort((a, b) => b.rating.compareTo(a.rating));
    return products;
  }
}
