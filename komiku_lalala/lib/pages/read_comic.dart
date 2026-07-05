import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:memory_game_sawit/main.dart';

class ReadComic extends StatefulWidget {
  const ReadComic({super.key});

  @override
  State<StatefulWidget> createState() => _ReadComicState();
}

class _ReadComicState extends State<ReadComic> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Read Comic'),
      ),
      body: const Center(
        child: Text('This is the List Comic Screen'),
      ),
    );
  }
}
