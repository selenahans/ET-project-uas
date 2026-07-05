import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:memory_game_sawit/main.dart';

class MakeComic extends StatefulWidget {
  const MakeComic({super.key});

  @override
  State<StatefulWidget> createState() => _MakeComicState();
}

class _MakeComicState extends State<MakeComic> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Comic'),
      ),
      body: const Center(
        child: Text('This is the List Comic Screen'),
      ),
    );
  }
}
