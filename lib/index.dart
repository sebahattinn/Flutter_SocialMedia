import 'package:flutter/material.dart';

import 'features/feed/feed_page.dart';
import 'features/search/search_page.dart';
import 'features/create/create_post_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/profile/profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _bucket = PageStorageBucket();

  final List<Widget> _pages = const [
    FeedPage(key: PageStorageKey('feed')),
    SearchPage(key: PageStorageKey('search')),
    CreatePostPage(key: PageStorageKey('create')),
    NotificationsPage(key: PageStorageKey('notifs')),
    ProfilePage(key: PageStorageKey('profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // DİKKAT: AppBar yok — sadece sayfaların kendi AppBar'ı görünecek
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
