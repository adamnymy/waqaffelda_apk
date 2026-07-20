import 'package:flutter/material.dart';
import 'package:Waqafer/services/cart_service.dart';

// Warna khusus untuk modul Kedai
class KedaiColors {
  static const Color primary       = Color(0xFF11998E);
  static const Color primaryDark   = Color(0xFF0D7A72);
  static const Color primaryDarker = Color(0xFF065F46);
  static const Color primaryLight  = Color(0xFFD1FAE5);
  static const Color gradStart     = Color(0xFF11998E);
  static const Color gradEnd       = Color(0xFF38EF7D);
  static const Color background    = Color(0xFFF5F7FA);
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted     = Color(0xFF9CA3AF);
  static const Color border        = Color(0xFFE5E7EB);
  static const Color borderLight   = Color(0xFFF3F4F6);
  static const Color accent        = Color(0xFFF59E0B);
  static const Color accentLight   = Color(0xFFFEF3C7);
  static const Color danger        = Color(0xFFEF4444);
}

/// Header hijau kecerunan yang digunakan di sub-skrin Kedai (Troli, Pembayaran, Butiran).
class KedaiGradientHeader extends StatelessWidget {
  final Widget child;
  final double height;

  const KedaiGradientHeader({
    super.key,
    required this.child,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
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
          child: child,
        ),
      ),
    );
  }
}

/// Butang back anak panah (kiri atas) untuk sub-skrin Kedai.
class KedaiBackArrowButton extends StatelessWidget {
  const KedaiBackArrowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
      ),
    );
  }
}

/// Ikon troli dengan badge bilangan item — navigate ke TroliScreen apabila ditap.
class KedaiCartIconButton extends StatelessWidget {
  final Widget troliScreen;

  const KedaiCartIconButton({super.key, required this.troliScreen});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CartService.instance,
      builder: (context, _) {
        final count = CartService.instance.totalItems;
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => troliScreen),
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
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
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
    );
  }
}

/// Placeholder berjalur untuk gambar produk.
class KedaiProductPlaceholder extends StatelessWidget {
  final Color color;
  final double borderRadius;
  final String label;

  const KedaiProductPlaceholder({
    super.key,
    required this.color,
    this.borderRadius = 16,
    this.label = 'PRODUK',
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          Container(color: color),
          CustomPaint(
            size: Size.infinite,
            painter: _StripePainter(color: Colors.white.withOpacity(0.35)),
          ),
          Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.black.withOpacity(0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color color;
  _StripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    const spacing = 16.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Gambar produk — paparkan image asset, fallback ke placeholder kalau tiada.
class KedaiProductImage extends StatelessWidget {
  final List<String> images;
  final Color fallbackColor;
  final double borderRadius;

  const KedaiProductImage({
    super.key,
    required this.images,
    required this.fallbackColor,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return KedaiProductPlaceholder(
        color: fallbackColor,
        borderRadius: borderRadius,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        images.first,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => KedaiProductPlaceholder(
          color: fallbackColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Carousel gambar produk untuk skrin butiran (sokongan pelbagai gambar).
class KedaiProductImageCarousel extends StatefulWidget {
  final List<String> images;
  final Color fallbackColor;

  const KedaiProductImageCarousel({
    super.key,
    required this.images,
    required this.fallbackColor,
  });

  @override
  State<KedaiProductImageCarousel> createState() =>
      _KedaiProductImageCarouselState();
}

class _KedaiProductImageCarouselState
    extends State<KedaiProductImageCarousel> {
  int _current = 0;
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return KedaiProductPlaceholder(
        color: widget.fallbackColor,
        borderRadius: 24,
        label: 'GAMBAR PRODUK',
      );
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                widget.images[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => KedaiProductPlaceholder(
                  color: widget.fallbackColor,
                  borderRadius: 24,
                ),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Stepper kuantiti untuk skrin butiran dan troli.
class KedaiQuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final double size;

  const KedaiQuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KedaiColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrease,
            child: SizedBox(
              width: size,
              height: size,
              child: const Icon(Icons.remove,
                  size: 18, color: KedaiColors.textSecondary),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: KedaiColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onIncrease,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: KedaiColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
