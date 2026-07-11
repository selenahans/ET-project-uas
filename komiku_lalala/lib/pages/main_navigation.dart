// lib/pages/main_navigation.dart
import 'package:flutter/material.dart';
import 'category.dart';
import 'search_comic.dart';
import 'make_comic.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Category(),
    SearchComic(),
    MakeComic(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // ⚠️ PASTIIN BAGIAN INI ADA & TIDAK TERTUTUP
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Mencegah item tersembunyi
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Cari',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Buat Komik',
          ),
        ],
      ),
    );
  }
}