import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import 'pages/homepage/homepage.dart';
import 'dart:ui' show ImageFilter;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particlesController;
  late AnimationController _transitionController;
  late AnimationController _fadeController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoBlur;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _particlesAnimation;
  late Animation<double> _transitionAnimation;
  late Animation<double> _fadeOpacity;

  @override
  void initState() {
    super.initState();

    // Logo animation with blur effect
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoBlur = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // Text animation with slide up
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Floating particles animation
    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _particlesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particlesController, curve: Curves.easeInOut),
    );

    // Smooth gradient transition
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _transitionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );

    // Fade out animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    // Start particles immediately for ambient effect
    _particlesController.repeat(reverse: true);

    // Show logo with blur effect on teal background
    _logoController.forward();

    // Wait 1.5 seconds on teal background
    await Future.delayed(const Duration(milliseconds: 1500));

    // Start smooth gradient transition to white
    _transitionController.forward();

    // Show text during transition
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // Wait for transition to complete + show white background
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
    _particlesController.dispose();
    _transitionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _textController,
          _particlesController,
          _transitionController,
          _fadeController,
        ]),
        builder: (context, child) {
          final isTransitioning = _transitionAnimation.value > 0;
          final isWhiteBg = _transitionAnimation.value >= 0.8;

          return Opacity(
            opacity: _fadeOpacity.value,
            child: Stack(
              children: [
                // Animated gradient background
                AnimatedContainer(
                  duration: Duration.zero,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isTransitioning
                              ? [
                                Color.lerp(
                                  colorScheme.primary,
                                  colorScheme.background,
                                  _transitionAnimation.value,
                                )!,
                                Color.lerp(
                                  colorScheme.primary.withOpacity(0.9),
                                  colorScheme.background,
                                  _transitionAnimation.value,
                                )!,
                                Color.lerp(
                                  colorScheme.primary.withOpacity(0.85),
                                  colorScheme.background,
                                  _transitionAnimation.value,
                                )!,
                              ]
                              : [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.9),
                                colorScheme.primary.withOpacity(0.85),
                              ],
                    ),
                  ),
                ),

                // Floating particles effect
                CustomPaint(
                  painter: ParticlesPainter(
                    animationValue: _particlesAnimation.value,
                    color:
                        isWhiteBg
                            ? colorScheme.primary.withOpacity(0.08)
                            : colorScheme.onPrimary.withOpacity(0.1),
                    screenSize: screenSize,
                  ),
                  size: screenSize,
                ),

                // Shimmer overlay during transition
                if (isTransitioning && !isWhiteBg)
                  CustomPaint(
                    painter: ShimmerPainter(
                      animationValue: _transitionAnimation.value,
                      color: Colors.white.withOpacity(0.3),
                      screenSize: screenSize,
                    ),
                    size: screenSize,
                  ),

                // Content (logo and text)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with blur effect
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: _logoBlur.value,
                              sigmaY: _logoBlur.value,
                            ),
                            child: Image.asset(
                              'assets/icons/Logo_QAF.png',
                              height: 100,
                              width: 100,
                              color:
                                  isWhiteBg
                                      ? colorScheme.primary
                                      : colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Waqafer logo below QAF logo
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: _logoBlur.value,
                              sigmaY: _logoBlur.value,
                            ),
                            child: Image.asset(
                              'assets/images/LogoWaqafer.png',
                              height: 40,
                              color:
                                  isWhiteBg
                                      ? colorScheme.primary
                                      : colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Bottom aligned branding with slide up animation
                if (isWhiteBg)
                  Align(
                    alignment: const Alignment(0, 0.7),
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'By:',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 8,
                                color: colorScheme.onBackground.withOpacity(
                                  0.85,
                                ),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Image.asset(
                              'assets/images/waqaf_felda_logo.png',
                              height: 56,
                              width: 168,
                            ),
                          ],
                        ),
                      ),
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

// Custom painter for floating particles
class ParticlesPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final Size screenSize;

  ParticlesPainter({
    required this.animationValue,
    required this.color,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Create floating particles at various positions
    final particles = [
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.3),
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.6),
      Offset(size.width * 0.3, size.height * 0.15),
      Offset(size.width * 0.7, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.2, size.height * 0.5),
    ];

    for (int i = 0; i < particles.length; i++) {
      final offset = particles[i];
      final phase = (animationValue + (i * 0.15)) % 1.0;
      final radius = 3.0 + (math.sin(phase * math.pi * 2) * 2);
      final yOffset = math.sin(phase * math.pi * 2) * 20;

      canvas.drawCircle(Offset(offset.dx, offset.dy + yOffset), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}

// Custom painter for shimmer effect during transition
class ShimmerPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final Size screenSize;

  ShimmerPainter({
    required this.animationValue,
    required this.color,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0), color, color.withOpacity(0)],
            stops:
                [
                  animationValue - 0.3,
                  animationValue,
                  animationValue + 0.3,
                ].map((v) => v.clamp(0.0, 1.0)).toList(),
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
