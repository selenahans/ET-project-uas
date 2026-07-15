import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'read_comic.dart';
import 'make_comic.dart';
import 'manage_comic.dart';

class MyComicsPage extends StatefulWidget {
  final int userId;

  const MyComicsPage({super.key, required this.userId});

  @override
  State<MyComicsPage> createState() => _MyComicsPageState();
}

class _MyComicsPageState extends State<MyComicsPage> {
  static const Color colorOrange = Color(0xFFEC642A);
  static const Color colorSunnyYellow = Color(0xFFFAAA21);
  static const Color colorCream = Color(0xFFFDE2CD);
  static const Color colorCocoa = Color(0xFF642D0A);

  late Future<Map<String, dynamic>> _futureMyComics;

  @override
  void initState() {
    super.initState();
    _refreshComics();
  }

  void _refreshComics() {
    setState(() {
      _futureMyComics = fetchMyComics();
    });
  }

  Future<Map<String, dynamic>> fetchMyComics() async {
    final Uri url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/get_my_comics.php?user_id=${widget.userId}",
    );

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
        title: const Text(
          "Komik Saya",
          style: TextStyle(
            color: colorCocoa,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          int currentUserId = prefs.getInt("user_id") ?? 0;

          if (mounted) {
            var refreshed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MakeComic(userId: currentUserId),
              ),
            );

            if (refreshed == true) {
              _refreshComics();
            }
          }
        },
        backgroundColor: colorOrange,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Buat Komik",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureMyComics,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: colorOrange),
            );
          }

          if (snapshot.hasError) {
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

          var responseData = snapshot.data;
          List<dynamic> listKomik = responseData?['data'] ?? [];

          if (responseData == null ||
              responseData['result'] == 'EMPTY' ||
              listKomik.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 72,
                    color: colorCream.withOpacity(0.8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Kamu belum membuat komik.",
                    style: TextStyle(
                      fontSize: 14,
                      color: colorCocoa.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: listKomik.length,
            itemBuilder: (context, index) {
              var komik = listKomik[index];

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
                      int komikId = int.tryParse(komik['id'].toString()) ?? 0;
                      String judul = komik['judul'] ?? 'Komik';

                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  judul,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: colorCocoa,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colorCream,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorCream.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit_document,
                                      color: colorOrange,
                                    ),
                                  ),
                                  title: const Text(
                                    "Kelola Komik",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorCocoa,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Tambah chapter, edit judul, atau atur status",
                                  ),
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ManageComicScreen(
                                          komikId: komikId,
                                          judulKomik: judul,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const Divider(color: colorCream, height: 1),

                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorCream.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      color: colorOrange,
                                    ),
                                  ),
                                  title: const Text(
                                    "Preview Pembaca",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorCocoa,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Lihat tampilan komik dari sisi pembaca",
                                  ),
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                    );
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
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          );
                        },
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
                                errorBuilder: (context, error, stackTrace) {
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
                                    borderRadius: BorderRadius.circular(8),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      color: colorCocoa.withOpacity(0.6),
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
          );
        },
      ),
    );
  }
}
