import 'package:flutter/material.dart';
import '../../../models/product.dart';
import '../../../services/cart_service.dart';
import '../../../widgets/kedai_widgets.dart';
import 'troli_screen.dart';

class ButiranProdukScreen extends StatefulWidget {
  final Product product;
  const ButiranProdukScreen({super.key, required this.product});

  @override
  State<ButiranProdukScreen> createState() => _ButiranProdukScreenState();
}

class _ButiranProdukScreenState extends State<ButiranProdukScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: KedaiColors.background,
      body: Column(
        children: [
          _buildHeader(product),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: _buildDetails(product),
            ),
          ),
          _buildBottomActions(product),
        ],
      ),
    );
  }

  Widget _buildHeader(Product product) {
    return KedaiGradientHeader(
      height: 400,
      child: Column(
        children: [
          Row(
            children: [
              const KedaiBackArrowButton(),
              const Spacer(),
              const Text(
                'Butiran Produk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              KedaiCartIconButton(troliScreen: const TroliScreen()),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: KedaiProductImageCarousel(
              images: product.allImages,
              fallbackColor: product.cardColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDetails(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: KedaiColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: KedaiColors.primaryDarker,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star,
                          size: 14, color: KedaiColors.accent),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating} · ${product.reviewCount} ulasan',
                        style: const TextStyle(
                            fontSize: 12,
                            color: KedaiColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: KedaiColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.size} · ${product.type}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: KedaiColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Harga',
                    style: TextStyle(
                        fontSize: 12,
                        color: KedaiColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  'RM${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: KedaiColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Penerangan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: KedaiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: const TextStyle(
            fontSize: 13.5,
            color: KedaiColors.textSecondary,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _infoChip(
                icon: Icons.eco,
                title: 'Sumbangan',
                subtitle: '${product.wakafPercentage}% ke wakaf',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoChip(
                icon: Icons.local_shipping_outlined,
                title: 'Penghantaran',
                subtitle: product.deliveryTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kuantiti',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: KedaiColors.textPrimary,
              ),
            ),
            KedaiQuantityStepper(
              quantity: _quantity,
              onDecrease: () {
                if (_quantity > 1) setState(() => _quantity--);
              },
              onIncrease: () => setState(() => _quantity++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KedaiColors.primaryLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: KedaiColors.primaryDarker),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 11,
                        color: KedaiColors.textSecondary)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: KedaiColors.textPrimary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Product product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                CartService.instance.addProduct(product, quantity: _quantity);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} ditambah ke troli'),
                    duration: const Duration(milliseconds: 1400),
                    backgroundColor: KedaiColors.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: KedaiColors.primary,
                side: const BorderSide(
                    color: KedaiColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Tambah ke Troli',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                CartService.instance.addProduct(product, quantity: _quantity);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TroliScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KedaiColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Beli Sekarang',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
