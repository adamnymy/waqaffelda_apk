import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final ScrollController? scrollController;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.scrollController,
  }) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;

    // Scale animation for icon bounce
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50.0,
      ),
    ]).animate(_scaleC~ontroller);
  }

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _scaleController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Menu'),
              _buildNavItem(1, Icons.calendar_today_rounded, 'Program'),
              _buildNavItem(2, Icons.volunteer_activism_rounded, 'Waqaf'),
              _buildNavItem(3, Icons.mail_rounded, 'Inbox'),
              _buildNavItem(4, Icons.person_rounded, 'Akaun'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;
    final shouldAnimate =
        index == widget.currentIndex && _previousIndex != index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onTap(index),
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFFF36F21).withOpacity(0.1),
          highlightColor: const Color(0xFFF36F21).withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container with Animation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Active Background Circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      width: isSelected ? 46 : 0,
                      height: isSelected ? 46 : 0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors:
                              isSelected
                                  ? [
                                    const Color(0xFFF36F21),
                                    const Color(0xFFFF8C42),
                                  ]
                                  : [Colors.transparent, Colors.transparent],
                        ),
                        shape: BoxShape.circle,
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF36F21,
                                    ).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : [],
                      ),
                    ),
                    // Icon with Scale Animation
                    AnimatedBuilder(
                      animation: _scaleController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: shouldAnimate ? _scaleAnimation.value : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              icon,
                              size: isSelected ? 24 : 22,
                              color:
                                  isSelected ? Colors.white : Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Label with Fade and Scale
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  style: TextStyle(
                    fontSize: isSelected ? 10 : 9.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? const Color(0xFFF36F21) : Colors.grey[600],
                    height: 1.1,
                    letterSpacing: isSelected ? 0.2 : 0,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isSelected ? 1.0 : 0.7,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Active Indicator Dot
                const SizedBox(height: 1),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  width: isSelected ? 4 : 0,
                  height: isSelected ? 4 : 0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF36F21),
                        const Color(0xFFFF8C42),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
