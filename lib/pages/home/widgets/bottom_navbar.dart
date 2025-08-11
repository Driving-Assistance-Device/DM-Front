import 'package:flutter/material.dart';
import '../../../routes.dart' as routes;

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  
  const BottomNavBar({
    super.key,
    required this.selectedIndex, 
  });

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0: 
        Navigator.pushReplacementNamed(
          context, 
          routes.AppRoutes.driving, 
          arguments: {'fromNav': true}, 
        );
        break;
      case 1: 
        Navigator.pushReplacementNamed(
          context,
          routes.AppRoutes.history,
        );
        break;
      case 2:
        Navigator.pushReplacementNamed(
          context,
          routes.AppRoutes.stats,
        );
        break;
      case 3: 
        Navigator.pushReplacementNamed(
          context,
          routes.AppRoutes.profile,
        );
        break;
      default: 
        debugPrint('Invalid nav index: $index');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: (index) => _onItemTapped(context, index), 
      selectedItemColor: const Color.fromARGB(255, 6, 44, 125), 
      unselectedItemColor: Colors.grey, 
      selectedFontSize: 14, 
      unselectedFontSize: 12, 
      backgroundColor: Colors.white, 
      elevation: 8, 
      showSelectedLabels: true, 
      showUnselectedLabels: true, 

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car), 
          label: '운전', 
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history), 
          label: '기록', 
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: '최근기록', 
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person), 
          label: '프로필', 
        ),
      ],
    );
  }
}
