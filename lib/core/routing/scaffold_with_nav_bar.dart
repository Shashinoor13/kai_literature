import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

/// Notification for refreshing the feed (sent on double-tap home)
class FeedRefreshNotification extends Notification {}

/// Scaffold with bottom navigation bar
/// See CLAUDE.md: Navigation Structure > Bottom Navigation Bar
class ScaffoldWithNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  DateTime? _lastHomeTap;

  void _onTap(BuildContext context, int index) {
    // Handle double tap on home button (index 0)
    if (index == 0 && widget.navigationShell.currentIndex == 0) {
      final now = DateTime.now();
      if (_lastHomeTap != null &&
          now.difference(_lastHomeTap!).inMilliseconds < 500) {
        // Double tap detected - send refresh notification
        FeedRefreshNotification().dispatch(context);
        // Reset to prevent triple tap triggering another refresh
        _lastHomeTap = null;
        return;
      }
      _lastHomeTap = now;
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
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
