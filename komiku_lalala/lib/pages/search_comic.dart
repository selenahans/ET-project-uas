import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:memory_game_sawit/main.dart';

class SearchComic extends StatefulWidget {
  const SearchComic({super.key});

  @override
  State<StatefulWidget> createState() => _SearchComicState();
}

class _SearchComicState extends State<SearchComic> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Comic'),
      ),
      body: const Center(
        child: Text('This is the Search Comic Screen'),
      ),
    );
  }
}
