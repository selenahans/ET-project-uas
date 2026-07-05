import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:memory_game_sawit/main.dart';

class ListComicScreen extends StatefulWidget {
  const ListComicScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ListComicScreenState();
}

class _ListComicScreenState extends State<ListComicScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Comic'),
      ),
      body: const Center(
        child: Text('This is the List Comic Screen'),
      ),
    );
  }
}
