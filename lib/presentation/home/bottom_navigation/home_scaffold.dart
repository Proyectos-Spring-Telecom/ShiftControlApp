import 'package:flutter/material.dart';

import '../../auth/profile/profile_page.dart';
import '../drawer/app_drawer.dart';
import 'home_tab.dart';
import 'placeholder_tab.dart';

/// Índices de los tabs del BottomNavigation.
enum HomeTabIndex { home, section, profile }

/// Scaffold principal con Bottom Navigation y Drawer.
class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  HomeTabIndex _currentIndex = HomeTabIndex.home;

  Widget _buildPage(HomeTabIndex index) {
    return switch (index) {
      HomeTabIndex.home => const HomeTab(),
      HomeTabIndex.section => const PlaceholderTab(title: 'Otra sección'),
      HomeTabIndex.profile => const ProfilePage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_currentIndex)),
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex.index,
        children: HomeTabIndex.values.map(_buildPage).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex.index,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = HomeTabIndex.values[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Sección',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  String _titleForIndex(HomeTabIndex index) {
    return switch (index) {
      HomeTabIndex.home => 'Inicio',
      HomeTabIndex.section => 'Otra sección',
      HomeTabIndex.profile => 'Perfil',
    };
  }
}
