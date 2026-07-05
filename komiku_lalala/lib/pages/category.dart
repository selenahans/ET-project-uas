import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // Membawa variable active_user jika diperlukan
import 'login.dart';
// import 'package:memory_game_sawit/main.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  String _username = active_user; // Mengambil user aktif dari main.dart

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
    // Sesuaikan URL ini dengan file PHP Opsi 2 kamu kemarin
    var url = Uri.parse("https://ubaya.cloud/flutter/160423025/komiku/get_comics_by_category.php");
    
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
          )
        ],
      ),
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
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
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
                    List<dynamic> comics = category['comics'];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama Kategori
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                category['nama_kategori'],
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                              ),
                              Text(
                                "${comics.length} Komik",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              )
                            ],
                          ),
                        ),

                        // List Komik Horizontal di dalam Kategori
                        comics.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                                child: Text("Belum ada komik di kategori ini.", style: TextStyle(color: Colors.grey)),
                              )
                            : SizedBox(
                                height: 220, // Tinggi area scroll komik
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(left: 16.0),
                                  itemCount: comics.length,
                                  itemBuilder: (context, cIndex) {
                                    var comic = comics[cIndex];
                                    return Container(
                                      width: 120, // Lebar card komik
                                      margin: const EdgeInsets.only(right: 12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Gambar Poster Komik
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8.0),
                                            child: Image.network(
                                              comic['poster'],
                                              height: 150,
                                              width: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                // Jika url gambar error/gagal load, tampilkan placeholder grey
                                                return Container(
                                                  height: 150,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Judul Komik
                                          Text(
                                            comic['judul'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          // Jumlah Views
                                          Text(
                                            "👁️ ${comic['views']} views",
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                        const Divider(height: 25, thickness: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}