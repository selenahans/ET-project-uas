import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'read_comic.dart';
import 'dart:convert';

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
  static const Color colorOrange = Color(0xFFEC642A);
  static const Color colorSunnyYellow = Color(0xFFFAAA21);
  static const Color colorCream = Color(0xFFFDE2CD);
  static const Color colorCocoa = Color(0xFF642D0A);
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchKeyword = "";

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchComics() async {
    Uri url;
    int now = DateTime.now().millisecondsSinceEpoch;

    if (_searchKeyword.trim().isNotEmpty) {
      url = Uri.parse(
        "https://ubaya.cloud/flutter/160423025/komiku/search_comics.php?q=${Uri.encodeComponent(_searchKeyword.trim())}&kategori_id=${widget.idKategori}&t=$now",
      );
    } else {
      url = Uri.parse(
        "https://ubaya.cloud/flutter/160423025/komiku/get_list_comics_by_category.php?kategori_id=${widget.idKategori}&t=$now",
      );
    }

    try {
      var response = await http.get(url);
      print("RESPON LIST: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal memuat data dari server");
      }
    } catch (e) {
      throw Exception("Kesalahan koneksi: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchKeyword = query;
      });
    });
  }

  Future<void> saveReadingHistory(int userId, int comicId) async {
    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/save_reading_history.php",
    );
    await http.post(
      url,
      body: {"user_id": userId.toString(), "comic_id": comicId.toString()},
    );
  }

  Future<int> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id") ?? 0;
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
          _searchKeyword.isEmpty
              ? widget.namaKategori
              : "Hasil Cari: '$_searchKeyword'",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: colorCocoa,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: colorCocoa, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Cari judul/deskripsi komik...",
                hintStyle: TextStyle(
                  color: colorCocoa.withOpacity(0.4),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: colorOrange),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: colorCocoa),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged("");
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
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              key: ValueKey(_searchKeyword),
              future: fetchComics(),
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
                    responseData['result'] == 'ERROR' ||
                    listKomik.isEmpty) {
                  String msg;
                  if (_searchKeyword.trim().isNotEmpty) {
                    msg =
                        "Tidak ada komik dengan nama '$_searchKeyword' pada kategori '${widget.namaKategori}'.";
                  } else {
                    msg =
                        responseData?['message'] ??
                        "Tidak ada komik di kategori ini.";
                  }
                  if (_searchKeyword.trim().isEmpty) {
                    msg =
                        responseData?['message'] ??
                        "Tidak ada komik yang ditemukan.";
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        msg,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorCocoa.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                          onTap: () async {
                            int komikId =
                                int.tryParse(komik['id'].toString()) ?? 0;
                            String judul = komik['judul'] ?? "Komik";

                            //misalnya user id didapat dari SharedPreference
                            int userId = await getCurrentUserId();;

                            await saveReadingHistory(userId, komikId);

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReadComic(
                                  komikId: komikId,
                                  judulKomik: judul,
                                  chapterId: null,
                                ),
                              ),
                            );

                            if (mounted) {
                              setState(() {});
                            }
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
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
          ),
        ],
      ),
    );
  }
}
