import 'package:flutter/material.dart';
import '../core/theme/zen_theme.dart';
import 'zen_hifz_screen.dart';
import 'mutun_screen.dart';
import 'anashid_screen.dart';
import 'halaqa_screen.dart';
import 'alarms_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  bool _isFocusMode = false;

  void _onFocusChanged(bool isFocus) {
    setState(() {
      _isFocusMode = isFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sageColor = isDark ? ZenTheme.darkSage : ZenTheme.lightSage;

    final screens = [
      ZenHifzScreen(onFocusModeChanged: _onFocusChanged),
      const MutunScreen(),
      const AnashidScreen(),
      const HalaqaScreen(),
      const AlarmsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _isFocusMode
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              backgroundColor: isDark ? ZenTheme.darkSurface : ZenTheme.lightSurface,
              indicatorColor: sageColor.withValues(alpha: 0.2),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'المصحف',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories),
                  label: 'المتون',
                ),
                NavigationDestination(
                  icon: Icon(Icons.headphones_outlined),
                  selectedIcon: Icon(Icons.headphones),
                  label: 'الأناشيد',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'الحلقة',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_active_outlined),
                  selectedIcon: Icon(Icons.notifications_active),
                  label: 'المنبهات',
                ),
              ],
            ),
    );
  }
}
