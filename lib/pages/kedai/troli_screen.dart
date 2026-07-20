import 'package:flutter/material.dart';
import '../../../services/cart_service.dart';
import '../../../widgets/kedai_widgets.dart';
import 'pembayaran_screen.dart';

class TroliScreen extends StatelessWidget {
  const TroliScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KedaiColors.background,
      body: AnimatedBuilder(
        animation: CartService.instance,
        builder: (context, _) {
          final cart = CartService.instance;
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: cart.isEmpty
                    ? const _EmptyCartView()
                    : _CartItemList(),
              ),
              if (!cart.isEmpty) _OrderSummary(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return KedaiGradientHeader(
      height: 115,
      child: Row(
        children: [
          const KedaiBackArrowButton(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'WAQAF FELDA',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Troli Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// ── Senarai Item ─────────────────────────────────────────────────────────────

class _CartItemList extends StatelessWidget {
  const _CartItemList();

  @override
  Widget build(BuildContext context) {
    final cart = CartService.instance;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                '${cart.distinctItems} item dalam troli',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KedaiColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => cart.clear(),
                child: const Text('Kosongkan',
                    style: TextStyle(
                        fontSize: 13,
                        color: KedaiColors.textSecondary)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _CartItemTile(item: cart.items[index]),
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KedaiColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: KedaiProductImage(
              images: item.product.allImages,
              fallbackColor: item.product.cardColor,
              borderRadius: 10,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KedaiColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM${item.product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: KedaiColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () =>
                    CartService.instance.remove(item.product.id),
                child: const Icon(Icons.delete_outline,
                    color: KedaiColors.danger, size: 20),
              ),
              const SizedBox(height: 8),
              KedaiQuantityStepper(
                quantity: item.quantity,
                onDecrease: () =>
                    CartService.instance.decrease(item.product.id),
                onIncrease: () =>
                    CartService.instance.increase(item.product.id),
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ringkasan Pesanan ─────────────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  const _OrderSummary();

  @override
  Widget build(BuildContext context) {
    final cart = CartService.instance;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Pesanan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: KedaiColors.textPrimary,
              )),
          const SizedBox(height: 12),
          _summaryRow(
              'Subjumlah', 'RM${cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _summaryRow(
              'Penghantaran', 'RM${cart.shipping.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: KedaiColors.borderLight),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jumlah',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KedaiColors.textPrimary,
                  )),
              Text(
                'RM${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KedaiColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const PembayaranScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KedaiColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Teruskan ke Pembayaran',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13.5, color: KedaiColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: KedaiColors.textPrimary)),
      ],
    );
  }
}

// ── Troli Kosong ──────────────────────────────────────────────────────────────

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 44, color: KedaiColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('Troli anda kosong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KedaiColors.textPrimary,
                )),
            const SizedBox(height: 8),
            const Text(
              'Mula meneroka produk wakaf yang berkat — setiap belian membantu insan lain.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  color: KedaiColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: KedaiColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Layari Kedai',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
