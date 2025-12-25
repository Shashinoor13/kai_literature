import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

/// Scaffold with bottom navigation bar
/// See CLAUDE.md: Navigation Structure > Bottom Navigation Bar
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: HeroIcon(HeroIcons.home, style: HeroIconStyle.outline),
            activeIcon: HeroIcon(HeroIcons.home, style: HeroIconStyle.solid),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: HeroIcon(
              HeroIcons.chatBubbleLeft,
              style: HeroIconStyle.outline,
            ),
            activeIcon: HeroIcon(
              HeroIcons.chatBubbleLeft,
              style: HeroIconStyle.solid,
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: HeroIcon(HeroIcons.plusCircle, style: HeroIconStyle.outline),
            activeIcon: HeroIcon(
              HeroIcons.plusCircle,
              style: HeroIconStyle.solid,
            ),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: HeroIcon(HeroIcons.bell, style: HeroIconStyle.outline),
            activeIcon: HeroIcon(HeroIcons.bell, style: HeroIconStyle.solid),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: HeroIcon(HeroIcons.user, style: HeroIconStyle.outline),
            activeIcon: HeroIcon(HeroIcons.user, style: HeroIconStyle.solid),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
