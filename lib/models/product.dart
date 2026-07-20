import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final int reviewCount;
  final String description;
  final String size;
  final String type;
  final String? badge;
  final Color cardColor;
  final int wakafPercentage;
  final String deliveryTime;
  final String? imagePath;
  final List<String> imagePaths; // untuk produk yang ada lebih dari 1 gambar

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.rating = 4.9,
    this.reviewCount = 142,
    required this.description,
    this.size = '250g',
    this.type = 'Bancuh',
    this.badge,
    this.cardColor = const Color(0xFFE8DCC4),
    this.wakafPercentage = 10,
    this.deliveryTime = '3-5 hari',
    this.imagePath,
    this.imagePaths = const [],
  });

  // Semua gambar — guna imagePaths kalau ada, kalau tak guna imagePath
  List<String> get allImages {
    if (imagePaths.isNotEmpty) return imagePaths;
    if (imagePath != null) return [imagePath!];
    return [];
  }
}

class ProductData {
  static final List<Product> products = [

    // ── AL-QURAN ──────────────────────────────────────────────────────────────

    Product(
      id: 'q1',
      name: 'Al-Quran Waqaf Felda',
      category: 'Al-Quran',
      price: 100.00,
      rating: 5.0,
      reviewCount: 0,
      description:
          'Al-Quran keluaran Waqaf Felda. Setiap pembelian menyumbang '
          'kepada tabung wakaf pendidikan anak-anak asnaf.',
      size: 'Standard',
      type: 'Al-Quran',
      badge: 'POPULAR',
      cardColor: Color(0xFFD1FAE5),
      wakafPercentage: 10,
      deliveryTime: '3-5 hari',
      imagePaths: [
        'assets/images/kedai/alquran_1.jpeg',
        'assets/images/kedai/alquran_2.jpeg',
        'assets/images/kedai/alquran_3.jpeg',
      ],
    ),

    // ── SET PERSALINAN AKHIR ──────────────────────────────────────────────────

    Product(
      id: 'sp1',
      name: 'Set Persalinan Akhir',
      category: 'Keperluan',
      price: 100.00,
      rating: 5.0,
      reviewCount: 0,
      description:
          'Set persalinan akhir lengkap untuk keperluan jenazah. '
          'Disediakan mengikut syariat Islam. Setiap pembelian '
          'menyumbang ke tabung wakaf kebajikan.',
      size: '1 Set',
      type: 'Set',
      cardColor: Color(0xFFE8DCC4),
      wakafPercentage: 10,
      deliveryTime: '3-5 hari',
      imagePath: 'assets/images/kedai/set_persalinan_akhir.jpeg',
    ),

    // ── QAFFCAFE ──────────────────────────────────────────────────────────────

    Product(
      id: 'qc1',
      name: 'QaffCafe',
      category: 'Minuman',
      price: 30.00,
      rating: 5.0,
      reviewCount: 0,
      description:
          'Minuman berkualiti dari QaffCafe, produk Waqaf Felda. '
          'Setiap pembelian menyumbang kepada tabung wakaf komuniti.',
      size: '1 Unit',
      type: 'Minuman',
      badge: 'POPULAR',
      cardColor: Color(0xFFF5E6CC),
      wakafPercentage: 10,
      deliveryTime: '3-5 hari',
      imagePath: 'assets/images/kedai/QaffCafe.jpeg',
    ),

    // ── WANGIAN ───────────────────────────────────────────────────────────────

    Product(
      id: 'w1',
      name: 'Perfume 1',
      category: 'Wangian',
      price: 50.00,
      rating: 5.0,
      reviewCount: 0,
      description:
          'Wangian eksklusif Waqaf Felda. Tanpa alkohol, sesuai untuk '
          'penggunaan harian. Sebahagian hasil disalurkan ke tabung wakaf.',
      size: '50ml',
      type: 'Perfume',
      cardColor: Color(0xFFE8E0CC),
      wakafPercentage: 10,
      deliveryTime: '3-5 hari',
      imagePath: 'assets/images/kedai/contoh_perfurme_1.jpg',
    ),
    Product(
      id: 'w2',
      name: 'Perfume 2',
      category: 'Wangian',
      price: 50.00,
      rating: 5.0,
      reviewCount: 0,
      description:
          'Wangian eksklusif Waqaf Felda. Tanpa alkohol, sesuai untuk '
          'penggunaan harian. Sebahagian hasil disalurkan ke tabung wakaf.',
      size: '50ml',
      type: 'Perfume',
      cardColor: Color(0xFFF3E8FF),
      wakafPercentage: 10,
      deliveryTime: '3-5 hari',
      imagePath: 'assets/images/kedai/contoh_perfume_2.jpeg',
    ),
    Product(
      id: 'w3',
      name: 'Perfume 3',
      category: 'Wangian',
      price: 50.00,
      rating: 5.0,
      reviewCount: 0,
      description:
          'Wangian eksklusif Waqaf Felda. Tanpa alkohol, sesuai untuk '
          'penggunaan harian. Sebahagian hasil disalurkan ke tabung wakaf.',
      size: '50ml',
      type: 'Perfume',
      cardColor: Color(0xFFFFE4E6),
      wakafPercentage: 10,
      deliveryTime: '3-5 hari',
      imagePath: 'assets/images/kedai/contoh_perfume_3.jpeg',
    ),
  ];

  static Product? findById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
