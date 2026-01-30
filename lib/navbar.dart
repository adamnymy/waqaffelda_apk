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
        left: 12,
        right: 12,
        bottom: bottomPadding > 0 ? bottomPadding + 10 : 18,
        top: 10,
      ),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 35,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 25,
              offset: const Offset(0, 5),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Menu'),
                _buildNavItem(1, Icons.calendar_month_rounded, 'Program'),
                _buildNavItem(2, Icons.volunteer_activism_rounded, 'Wakaf'),
                _buildNavItem(3, Icons.store_rounded, 'Kedai'),
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
          HapticFeedback.selectionClick();
          widget.onTap(index);

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const WaqafPage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
        splashColor: const Color(0xFF00897B).withOpacity(0.1),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transform: Matrix4.translationValues(
                0,
                isSelected ? -4 : 0,
                0,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                scale: isSelected ? 1.15 : 1.0,
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected 
                      ? const Color(0xFF00897B) // Teal when selected
                      : Colors.grey.shade300, // Grey when not selected
                ),
              ),
            ),
            const SizedBox(height: 1), // ✅ Dikecilkan dari 5 ke 1
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
