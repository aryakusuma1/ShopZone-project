/// Product Model - Untuk semua produk di ShopZone
class Product {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final String category;
  final String condition; // Add new condition field
  final String? size;
  final String? color;
  final String? material;
  final String description;
  final double rating;
  final bool verified;
  final List<String>? userPhotos; // Foto asli dari pengguna
  final int stock; // Stock produk (untuk admin)
  final int sold; // Jumlah produk terjual (untuk sorting Terlaris)
  final DateTime? createdAt; // Tanggal produk dibuat
  final String name_lowercase; // For case-insensitive search

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.condition, // Make condition required
    this.size,
    this.color,
    this.material,
    this.description = '',
    this.rating = 0.0,
    this.verified = false,
    this.userPhotos,
    this.stock = 0,
    this.sold = 0,
    this.createdAt,
  }) : name_lowercase = name.toLowerCase();

  // Format harga ke Rupiah
  String get formattedPrice {
    return 'Rp${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Convert dari JSON (untuk Firebase/API nanti)
  factory Product.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return Product(
      id: json['id'] ?? '',
      name: name,
      price: json['price'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      condition: json['condition'] ?? 'baru', // Default to 'baru'
      size: json['size'],
      color: json['color'],
      material: json['material'],
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      verified: json['verified'] ?? false,
      userPhotos: json['userPhotos'] != null
          ? List<String>.from(json['userPhotos'])
          : null,
      stock: json['stock'] ?? 0,
      sold: json['sold'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  // Convert ke JSON (untuk Firebase/API nanti)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'condition': condition, // Add condition to toJson
      'size': size,
      'color': color,
      'material': material,
      'description': description,
      'rating': rating,
      'verified': verified,
      'userPhotos': userPhotos,
      'stock': stock,
      'sold': sold,
      'createdAt': createdAt?.toIso8601String(),
      'name_lowercase': name_lowercase,
    };
  }
}
