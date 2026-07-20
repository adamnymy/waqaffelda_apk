import 'package:flutter/material.dart';
import '../../../navbar.dart';
import '../homepage/homepage.dart';
import '../program/program_page.dart';
import '../waqaf/waqafpage.dart';
import '../akaun/akaunpage.dart';
import '../../../models/product.dart';
import '../../../services/cart_service.dart';
import '../../../widgets/kedai_widgets.dart';
import 'butiran_produk_screen.dart';
import 'troli_screen.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({Key? key}) : super(key: key);

  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  int _currentIndex = 3;
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    return ProductData.products.where((p) {
      final matchesCategory =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const Homepage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ));
        break;
      case 1:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ProgramPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ));
        break;
      case 2:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WaqafPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ));
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AkaunPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KedaiColors.background,
      extendBody: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryRow(),
                  const SizedBox(height: 16),
                  _buildWakafBanner(),
                  const SizedBox(height: 16),
                  _buildProductGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KedaiColors.gradStart, KedaiColors.gradEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WAQAF FELDA',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kedai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  // Cart icon dengan badge
                  AnimatedBuilder(
                    animation: CartService.instance,
                    builder: (context, _) {
                      final count = CartService.instance.totalItems;
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TroliScreen()),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: KedaiColors.accent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 20, minHeight: 20),
                                  child: Text(
                                    '$count',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Cari produk wakaf...',
                    hintStyle: TextStyle(
                        color: KedaiColors.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search,
                        color: KedaiColors.textMuted, size: 22),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    final categories = ['Semua', 'Al-Quran', 'Keperluan', 'Minuman', 'Wangian'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedCategory == cat
                        ? KedaiColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCategory == cat
                          ? KedaiColors.primary
                          : KedaiColors.border,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: _selectedCategory == cat
                          ? Colors.white
                          : KedaiColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_filteredProducts.length} produk',
          style: const TextStyle(
              fontSize: 13, color: KedaiColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildWakafBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KedaiColors.primaryLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: KedaiColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco,
                color: KedaiColors.primaryDarker, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setiap belian menyumbang ke wakaf',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: KedaiColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '10% hasil disalurkan ke tabung pendidikan',
                  style: TextStyle(
                      fontSize: 12, color: KedaiColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off,
                  size: 48,
                  color: KedaiColors.textMuted.withOpacity(0.6)),
              const SizedBox(height: 12),
              const Text('Tiada produk dijumpai',
                  style: TextStyle(color: KedaiColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) =>
          _ProductCard(product: products[index]),
    );
  }
}

// ── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ButiranProdukScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KedaiColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: KedaiProductImage(
                        images: product.allImages,
                        fallbackColor: product.cardColor,
                      ),
                    ),
                    if (product.badge != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: KedaiColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category,
                      style: const TextStyle(
                          fontSize: 12,
                          color: KedaiColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: KedaiColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: KedaiColors.primary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          CartService.instance.addProduct(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${product.name} ditambah ke troli'),
                              duration:
                                  const Duration(milliseconds: 1200),
                              backgroundColor: KedaiColors.primaryDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: KedaiColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
