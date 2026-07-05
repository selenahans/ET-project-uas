import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:memory_game_sawit/main.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<StatefulWidget> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category'),
      ),
      body: const Center(
        child: Text('This is the List Comic Screen'),
      ),
    );
  }
}
