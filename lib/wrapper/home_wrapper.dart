import 'package:flutter/material.dart';
import 'package:the_music_tech/components/mini_player.dart';
import 'package:the_music_tech/pages/home_page.dart';
import 'package:the_music_tech/pages/my_playlist_page.dart';
import 'package:the_music_tech/pages/search_page.dart';
import 'package:the_music_tech/pages/settings_page.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int selectedIndex = 0;
  final _items = [
    const BottomNavigationBarItem(
      label: 'Home',
      icon: Icon(
        Icons.home,
      ),
    ),
    const BottomNavigationBarItem(
      label: 'Search',
      icon: Icon(
        Icons.search_rounded,
      ),
    ),
    const BottomNavigationBarItem(
      label: 'My Library',
      icon: Icon(
        Icons.library_music_rounded,
      ),
    ),
    const BottomNavigationBarItem(
      label: 'Setting',
      icon: Icon(
        Icons.settings,
      ),
    ),
  ];

  final screens = const [
    HomePage(),
    SearchPage(),
    MyPlaylistPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.orange,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        items: _items,
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: screens,
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: 70,
              child: const MiniPlayer(),
            ),
          ),
        ],
      ),
    );
  }
}
