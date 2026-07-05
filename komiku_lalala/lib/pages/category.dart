// import 'package:memory_game_sawit/main.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // Membawa variable active_user jika diperlukan
import 'login.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  String _username = active_user; // Mengambil user aktif dari main.dart
  int _currentBottomIndex = 0; // Mengatur index menu bawah yang aktif

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Mengambil username dari SharedPreferences jika active_user kosong
  void _loadUser() async {
    if (_username.isEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _username = prefs.getString("username") ?? "Guest";
      });
    }
  }

  // Fungsi untuk mengambil data kategori + komik dari API
  Future<List<dynamic>> fetchCategoriesWithComics() async {
    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/get_comics_by_category.php",
    );

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['result'] == 'OK') {
          return data['data'];
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception("Gagal memuat data dari server");
      }
    } catch (e) {
      throw Exception("Kesalahan koneksi: $e");
    }
  }

  // Fungsi Logout
  void doLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus data login
    active_user = "";

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Komiku Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: doLogout,
            tooltip: "Logout",
          ),
        ],
      ),

      // ==================== 1. DRAWER SAMPING (MENU KIRI) ====================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_username),
              accountEmail: const Text(
                "user@komiku.com",
              ), // Sesuaikan email jika ada
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
              ),
              decoration: const BoxDecoration(color: Colors.blueAccent),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Bookmark Saya'),
              onTap: () {
                Navigator.pop(context);
                // Navigasi ke halaman bookmark jika ada
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.power_settings_new, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                doLogout();
              },
            ),
          ],
        ),
      ),

      // ==================== KONTEN UTAMA Halaman ====================
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Selamat Datang
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Halo, $_username! Mau baca apa hari ini?",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Konten Utama menggunakan FutureBuilder
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: fetchCategoriesWithComics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada data kategori."));
                }

                var categories = snapshot.data!;

                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    var category = categories[index];
                    List<dynamic> comics = category['comics'] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            print(
                              "Membuka kategori: ${category['nama_kategori']}",
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category['nama_kategori'],
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${comics.length} Komik",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.blueAccent,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // List Komik Horizontal di dalam Kategori
                        comics.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 10,
                                ),
                                child: Text(
                                  "Belum ada komik di kategori ini.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(left: 16.0),
                                  itemCount: comics.length,
                                  itemBuilder: (context, cIndex) {
                                    var comic = comics[cIndex];
                                    return Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(
                                        right: 12.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                            child: Image.network(
                                              comic['poster'] ?? '',
                                              height: 150,
                                              width: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      height: 150,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comic['judul'] ?? 'Tanpa Judul',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            "👁️ ${comic['views'] ?? 0} views",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                        const Divider(
                          height: 25,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ==================== 2. DRAWER DI BAWAH (BOTTOM NAVIGATION BAR) ====================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: (int index) {
          // Memastikan index yang ditekan berada dalam jangkauan yang valid (0 sampai 2)
          if (index >= 0 && index < 3) {
            setState(() {
              _currentBottomIndex = index;
            });
            print("Menu bawah index $index ditekan");
          }
        },
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Jelajah'),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Populer',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
