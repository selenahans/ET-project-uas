import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/main_navigation.dart';
import 'pages/login.dart';
import 'pages/category.dart';
import 'pages/list_comic.dart';
import 'pages/make_comic.dart';
import 'pages/search_comic.dart';

String active_user = "";
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  active_user = prefs.getString("username") ?? "";

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Komiku LALALA',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEC642A), // Orange
          primary: const Color(0xFFEC642A),   // Orange
          secondary: const Color(0xFFFAAA21), // Sunny Yellow
          surface: const Color(0xFFFDE2CD),   // Cream
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF642D0A), // Cocoa
          onSurface: const Color(0xFF642D0A),   // Cocoa
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFEC642A), // Orange
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEC642A), // Orange
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50), 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFFDE2CD), // Cream
          selectedItemColor: Color(0xFFEC642A), // Orange
          unselectedItemColor: Color(0xFF642D0A), // Cocoa
        ),
      ),
      routes: {
        // 'category': (context) => const Category(),
        'login': (context) => const LoginScreen(),
        'search_comic': (context) => const SearchComic(),
        'make': (context) => const MakeComic(userId: 0),
        'main': (context) => const MainNavigationScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == 'list_comic') {
          final arguments = settings.arguments;
          if (arguments is Map<String, dynamic>) {
            final idKategori = arguments['idKategori'];
            final namaKategori = arguments['namaKategori'];

            if (idKategori is int && namaKategori is String) {
              return MaterialPageRoute(
                builder: (context) => ListComicScreen(
                  idKategori: idKategori,
                  namaKategori: namaKategori,
                ),
              );
            }
          }

          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(
                child: Text('Argument route list_comic tidak valid.'),
              ),
            ),
          );
        }

        return null;
      },
      home: active_user == "" ? const LoginScreen() : const MainNavigationScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}