import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'read_comic.dart';
import 'dart:convert';
// import 'package:memory_game_sawit/main.dart';

class ListComicScreen extends StatefulWidget {
  final int idKategori;
  final String namaKategori;
  const ListComicScreen({
    super.key,
    required this.idKategori,
    required this.namaKategori,
  });

  @override
  State<StatefulWidget> createState() => _ListComicScreenState();
}

class _ListComicScreenState extends State<ListComicScreen> {
  // Palet Warna
  static const Color colorOrange = Color(0xFFEC642A);
  static const Color colorSunnyYellow = Color(0xFFFAAA21);
  static const Color colorCream = Color(0xFFFDE2CD);
  static const Color colorCocoa = Color(0xFF642D0A);

  // Controller & State untuk Search Bar
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi fetch data berdasarkan idKategori yang dikirim
  Future<Map<String, dynamic>> fetchComicsByCategory() async {
    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/get_list_comics_by_category.php?kategori_id=${widget.idKategori}",
    );

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data; // Mengembalikan seluruh map JSON
      } else {
        throw Exception("Gagal memuat data dari server");
      }
    } catch (e) {
      throw Exception("Kesalahan koneksi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorCocoa,
        title: Text(
          widget.namaKategori,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: colorCocoa,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchComicsByCategory(),
        builder: (context, snapshot) {
          // 1. Kondisi Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: colorOrange),
            );
          }
          // 2. Kondisi Error Koneksi / SQL
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // 3. Kondisi Jika Data Kosong dari API
          var responseData = snapshot.data;
          List<dynamic> rawListKomik = responseData?['data'] ?? [];

          if (responseData == null ||
              responseData['result'] == 'EMPTY' ||
              responseData['result'] == 'ERROR' ||
              rawListKomik.isEmpty) {
            String msg =
                responseData?['message'] ?? "Belum ada komik untuk kategori ini.";

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  msg,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorCocoa.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Filter Komik Berdasarkan Search Keyword (Tanpa Ubah Backend)
          List<dynamic> filteredListKomik = rawListKomik.where((komik) {
            String judul = (komik['judul'] ?? '').toString().toLowerCase();
            return judul.contains(_searchKeyword.toLowerCase());
          }).toList();

          return Column(
            children: [
              // ==================== SEARCH BAR ====================
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchKeyword = value;
                    });
                  },
                  style: const TextStyle(color: colorCocoa, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Cari komik di ${widget.namaKategori}...",
                    hintStyle: TextStyle(
                      color: colorCocoa.withOpacity(0.4),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, color: colorOrange),
                    suffixIcon: _searchKeyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: colorCocoa),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchKeyword = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorCream.withOpacity(0.4),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(color: colorCream, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(color: colorOrange, width: 1.5),
                    ),
                  ),
                ),
              ),

              // ==================== GRID KOMIK ====================
              Expanded(
                child: filteredListKomik.isEmpty
                    ? Center(
                        child: Text(
                          "Komik tidak ditemukan",
                          style: TextStyle(
                            color: colorCocoa.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // Diubah ke 3 kolom agar tampilan di HP proporsional dan jelas
                          childAspectRatio: 0.58,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredListKomik.length,
                        itemBuilder: (context, index) {
                          var komik = filteredListKomik[index];

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16.0),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  int komikId =
                                      int.tryParse(komik['id'].toString()) ?? 0;
                                  String judul = komik['judul'] ?? 'Komik';

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReadComic(
                                        komikId: komikId,
                                        judulKomik: judul,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            komik['poster'] ?? '',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: colorOrange,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              print("URL Poster: ${komik['poster']}");
                                              print("Error Detail: $error");
                                              return Container(
                                                color: colorCream,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image_rounded,
                                                    color: colorCocoa,
                                                    size: 24,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colorCocoa.withOpacity(0.75),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.star_rounded,
                                                    size: 11,
                                                    color: colorSunnyYellow,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    "${komik['rating_avg'] ?? '0.0'}",
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            komik['judul'] ?? 'Tanpa Judul',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: colorCocoa,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.remove_red_eye_rounded,
                                                size: 11,
                                                color: colorOrange,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                "${komik['views'] ?? 0}",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      colorCocoa.withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}