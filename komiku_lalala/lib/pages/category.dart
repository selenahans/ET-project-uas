import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:komiku_lalala/pages/list_comic.dart';
import 'package:komiku_lalala/pages/read_comic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  String _username = active_user;
  int _userId = 0;
  int _currentBottomIndex = 0;

  static const Color colorOrange = Color(0xFFEC642A);
  static const Color colorSunnyYellow = Color(0xFFFAAA21);
  static const Color colorCream = Color(0xFFFDE2CD);
  static const Color colorCocoa = Color(0xFF642D0A);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _username = prefs.getString("username") ?? active_user;
      _userId = prefs.getInt("user_id") ?? 0;
    });

    print("USER ID = $_userId");
  }

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

  void doLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    active_user = "";

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<List<dynamic>> fetchReadingHistory() async {
    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/get_reading_history.php?user_id=$_userId",
    );

    var response = await http.get(url);
    print(response.body);
    var data = jsonDecode(response.body);

    return data["data"];
  }

  Future<void> saveReadingHistory(int comicId) async {
    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/save_reading_history.php",
    );

    await http.post(
      url,
      body: {"user_id": _userId.toString(),"comic_id": comicId.toString()},
    );
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
          "Komiku",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: colorCocoa,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: colorCream.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: colorOrange),
              onPressed: doLogout,
              tooltip: "Logout",
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchCategoriesWithComics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: colorOrange),
            );
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

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [colorOrange, colorSunnyYellow],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorOrange.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Halo, $_username! 👋",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Mau baca komik apa hari ini?",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<List<dynamic>>(
                  future: fetchReadingHistory(),
                  builder: (context, historySnapshot) {
                    if (!historySnapshot.hasData ||
                        historySnapshot.data!.isEmpty) {
                      return const SizedBox();
                    }

                    List<dynamic> allRecentComics = historySnapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "Terakhir Dibaca",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorCocoa,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(left: 16.0),
                            itemCount: allRecentComics.length,
                            itemBuilder: (context, cIndex) {
                              var comic = allRecentComics[cIndex];

                              return GestureDetector(
                                onTap: () async {
                                  int comicId = int.parse(comic['id'].toString());
                                  await saveReadingHistory(comicId);
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReadComic(
                                        komikId: int.parse(
                                          comic['id'].toString(),
                                        ),
                                        judulKomik: comic['judul'],
                                        chapterId: null,
                                      ),
                                    ),
                                  );

                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(
                                    right: 14.0,
                                    bottom: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                        child: Image.network(
                                          comic['poster'] ?? '',
                                          height: 135,
                                          width: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  height: 135,
                                                  color: colorCream,
                                                  child: const Icon(
                                                    Icons.broken_image_rounded,
                                                    color: colorCocoa,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comic['judul'] ?? 'Tanpa Judul',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: colorCocoa,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.remove_red_eye_rounded,
                                                  size: 12,
                                                  color: colorOrange,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${comic['views'] ?? 0}",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: colorCocoa
                                                        .withOpacity(0.7),
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
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    "Kategori Komik",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorCocoa,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    var category = categories[index];
                    List<dynamic> comics = category['comics'] ?? [];
                    int totalComics = comics.length;

                    int idYangDitemukan =
                        int.tryParse(category['id'].toString()) ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: colorCream.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorCream, width: 1.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        title: Text(
                          category['nama_kategori'] ?? 'Kategori',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorCocoa,
                          ),
                        ),
                        subtitle: Text(
                          "$totalComics Komik",
                          style: TextStyle(
                            color: colorCocoa.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ListComicScreen(
                                idKategori: idYangDitemukan,
                                namaKategori:
                                    category['nama_kategori'] ?? 'Kategori',
                              ),
                            ),
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
