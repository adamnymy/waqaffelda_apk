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
    const goldColor = Color(0xFFC49B28);
    const goldLight = Color(0xFFFDF3D7);

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
        splashColor: goldColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? goldLight : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? goldColor : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? goldColor : Colors.grey.shade400,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
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
