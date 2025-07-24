import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MyBottomNavBar extends StatelessWidget {
  void Function(int)? onTabChange;
  MyBottomNavBar({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return GNav(
        onTabChange: (value) => onTabChange!(value),
        mainAxisAlignment: MainAxisAlignment.center,
          activeColor: Colors.white,
        gap: 5,  // Reduce the gap further to fit your needs, default is 8
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        tabs: const [
        GButton(icon: Icons.pending),
        GButton(icon: Icons.pending),
        GButton(icon: Icons.pending),
        GButton(icon: Icons.pending),
            GButton(icon: Icons.pending),
          ]
    );
  }
}
