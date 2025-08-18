import 'package:flutter/material.dart';

/// Main shell with bottom navigation (no AppBar).
/// Child pages will render their own headers/toolbars later.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _bucket = PageStorageBucket();

  // For now: each tab is a pure white blank page.
  // Later: replace each with your real widget (from /widgets or /screens).
  final List<Widget> _pages = const <Widget>[
    _BlankWhitePage(key: PageStorageKey('home')),
    _BlankWhitePage(key: PageStorageKey('search')),
    _BlankWhitePage(key: PageStorageKey('create')),
    _BlankWhitePage(key: PageStorageKey('alerts')),
    _BlankWhitePage(key: PageStorageKey('profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Make scaffold background white too (safety net).
      backgroundColor: Colors.white,
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Post',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// A totally blank, full-screen white page.
/// Swap this with your real widget later.
class _BlankWhitePage extends StatelessWidget {
  const _BlankWhitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.white, child: SizedBox.expand());
  }
}
