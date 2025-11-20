import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import 'pages/homepage/homepage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _rippleController;
  late AnimationController _fadeController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<double> _rippleAnimation;
  late Animation<double> _fadeOpacity;

  @override
  void initState() {
    super.initState();

    // Logo animation (shows on teal background)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Text animation (shows only on white background)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Ripple animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
    );

    // Fade out animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animation sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Show logo on teal background
    _logoController.forward();

    // Wait 1.5 seconds on teal background (logo only)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Start ripple effect (transition to white)
    _rippleController.forward();

    // Wait for ripple to reach halfway, then show text
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    // Wait for ripple to complete + show white background with logo and text
    await Future.delayed(const Duration(milliseconds: 1600));

    // Fade out smoothly
    await _fadeController.forward();

    // Navigate to homepage
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const Homepage(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _rippleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxRadius = math.sqrt(
      screenSize.width * screenSize.width +
          screenSize.height * screenSize.height,
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _textController,
          _rippleAnimation,
          _fadeOpacity,
        ]),
        builder: (context, child) {
          final isWhiteBg = _rippleAnimation.value >= 0.5;

          return Opacity(
            opacity: _fadeOpacity.value,
            child: Stack(
              children: [
                // Teal gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F766E),
                        Color(0xFF0D9488),
                        Color(0xFF14B8A6),
                      ],
                    ),
                  ),
                ),

                // Ripple effect (white expanding from center)
                CustomPaint(
                  painter: RipplePainter(
                    animationValue: _rippleAnimation.value,
                    color: Colors.white,
                    maxRadius: maxRadius,
                    center: Offset(screenSize.width / 2, screenSize.height / 2),
                  ),
                  size: screenSize,
                ),

                // Content (logo and text)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: SvgPicture.asset(
                            'assets/icons/logoNg.svg',
                            height: 140,
                            width: 140,
                            color: isWhiteBg ? Color(0xFF0F766E) : Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Text
                      Opacity(
                        opacity: _textOpacity.value,
                        child: Text(
                          'Kejayaan Dalam Keberkatan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isWhiteBg ? Color(0xFF0F766E) : Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double maxRadius;
  final Offset center;

  RipplePainter({
    required this.animationValue,
    required this.color,
    required this.maxRadius,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue <= 0) return;

    final currentRadius = maxRadius * animationValue;
    final paint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = color;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
