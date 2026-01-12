import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/waqaf/waqafpage.dart';

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

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  void initState() {
    super.initState();
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 16,
        top: 8,
      ),
      child: Container(
        height: 63,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.08),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Menu'),
                _buildNavItem(1, Icons.calendar_month_rounded, 'Program'),
                _buildNavItem(2, Icons.volunteer_activism_rounded, 'Waqaf'),
                _buildNavItem(3, Icons.mail_rounded, 'Inbox'),
                _buildNavItem(4, Icons.person_rounded, 'Akaun'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          widget.onTap(index);

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const WaqafPage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
        splashColor: const Color(0xFF00897B).withOpacity(0.1),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: isSelected ? 46 : 38,
              height: isSelected ? 46 : 38,
              decoration: BoxDecoration(
                // ✅ FULL TEAL GRADIENT CIRCLE (no white center)
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF26A69A), // Light Teal
                          Color(0xFF00796B), // Dark Teal
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                shape: BoxShape.circle,
                // ✅ SUBTLE TEAL SHADOW
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00897B).withOpacity(0.25),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                // ✅ WHITE ICON on teal gradient background
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected 
                      ? Colors.white // ✅ WHITE icon when selected
                      : Colors.grey.shade300, // Grey when not selected
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF00897B)
                    : Colors.grey.shade400,
                fontSize: 8.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}