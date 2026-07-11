import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'read_comic.dart'; 

class SearchComic extends StatefulWidget {
  const SearchComic({super.key});

  @override
  State<SearchComic> createState() => _SearchComicState();
}

class _SearchComicState extends State<SearchComic> {

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
  Future<Map<String, dynamic>> fetchSearchResult() async {
    if (_searchKeyword.trim().isEmpty) {
      return {'result': 'EMPTY_QUERY'};
    }

    final Uri url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/search_comics.php?q=${Uri.encodeComponent(_searchKeyword.trim())}",
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchKeyword = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorCocoa,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: colorCocoa, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Cari judul atau deskripsi komik...",
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
      ),
      body: _searchKeyword.trim().isEmpty
          ? _buildInitialState()
          : FutureBuilder<Map<String, dynamic>>(
              key: ValueKey(_searchKeyword),
              future: fetchSearchResult(),
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
                  String msg = responseData?['message'] ??
                      "Komik '$_searchKeyword' tidak ditemukan.";

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: colorCocoa.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            msg,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorCocoa.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
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

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 72,
            color: colorCream.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            "Ketik judul atau kata kunci komik",
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
}