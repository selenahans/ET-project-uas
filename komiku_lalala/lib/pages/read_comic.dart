import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReadComic extends StatefulWidget {
  final int komikId;
  final String judulKomik;

  const ReadComic({super.key, required this.komikId, required this.judulKomik});

  @override
  State<ReadComic> createState() => _ReadComicState();
}

class _ReadComicState extends State<ReadComic> {
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 5.0;
  bool _isSubmitting = false;

  late Future<Map<String, dynamic>> _comicDetailFuture;

  // Color Palette dari image_eb2649.png
  static const Color orangeColor = Color(0xFFEC642A);
  static const Color sunnyYellowColor = Color(0xFFFAAA21);
  static const Color creamColor = Color(0xFFFDE2CD);
  static const Color cocoaColor = Color(0xFF642D0A);

  @override
  void initState() {
    super.initState();
    _comicDetailFuture = fetchComicDetail();
  }

  void _reloadComicDetail() {
    setState(() {
      _comicDetailFuture = fetchComicDetail();
    });
  }

  Future<Map<String, dynamic>> fetchComicDetail() async {
    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/get_comic_detail.php?komik_id=${widget.komikId}",
    );

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Gagal memuat detail komik (Status Code: ${response.statusCode})",
        );
      }
    } catch (e) {
      throw Exception("Kesalahan koneksi: $e");
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt("user_id") ?? 1;

    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/add_comment.php",
    );

    try {
      var response = await http.post(
        url,
        body: {
          "komik_id": widget.komikId.toString(),
          "user_id": userId.toString(),
          "comment": _commentController.text,
          "rating": _userRating.toString(),
        },
      );

      var data = jsonDecode(response.body);

      if (data['result'] == 'OK') {
        _commentController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Komentar berhasil dikirim!"),
              backgroundColor: cocoaColor,
            ),
          );
        }
        _reloadComicDetail();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal: ${data['message']}")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamColor.withOpacity(0.4),
      appBar: AppBar(
        title: Text(widget.judulKomik),
        backgroundColor: orangeColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _comicDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: orangeColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          var responseData = snapshot.data;

          if (responseData == null || responseData['result'] == 'ERROR') {
            return Center(
              child: Text(
                responseData?['message'] ?? "Gagal memuat halaman komik.",
                style: const TextStyle(color: cocoaColor),
              ),
            );
          }

          var pages = responseData['pages'] as List<dynamic>? ?? [];
          var comments = responseData['comments'] as List<dynamic>? ?? [];
          String chapterTitle = responseData['chapter_title'] ?? "Chapter 1";

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  color: creamColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        color: cocoaColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chapterTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cocoaColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                pages.isEmpty
                    ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          "Halaman komik belum tersedia.",
                          style: TextStyle(color: cocoaColor),
                        ),
                      ),
                    )
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        return Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500),
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: cocoaColor.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Image.network(
                                  pages[index],
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 220,
                                      color: creamColor.withOpacity(0.3),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: orangeColor,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 150,
                                      color: creamColor.withOpacity(0.3),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image,
                                              color: orangeColor,
                                              size: 36,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "Gagal memuat halaman",
                                              style: TextStyle(
                                                color: cocoaColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  color: creamColor.withOpacity(0.5),
                                  width: double.infinity,
                                  child: Text(
                                    "Halaman ${index + 1} dari ${pages.length}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: cocoaColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Divider(color: creamColor, thickness: 1.5),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Akhir dari Chapter",
                          style: TextStyle(color: cocoaColor, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: creamColor, thickness: 1.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Beri Rating & Komentar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cocoaColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Text(
                            "Rating: ",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: cocoaColor,
                            ),
                          ),
                          DropdownButton<double>(
                            value: _userRating,
                            dropdownColor: creamColor,
                            items:
                                [1.0, 2.0, 3.0, 4.0, 5.0]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          "⭐ $e",
                                          style: const TextStyle(
                                            color: cocoaColor,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _userRating = val);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: _commentController,
                        style: const TextStyle(color: cocoaColor),
                        decoration: InputDecoration(
                          hintText: "Tulis komentar...",
                          hintStyle: TextStyle(
                            color: cocoaColor.withOpacity(0.5),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: orangeColor,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: cocoaColor.withOpacity(0.3),
                            ),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitComment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    "Kirim Komentar",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Text(
                        "Komentar Pembaca",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cocoaColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      comments.isEmpty
                          ? const Text(
                            "Belum ada komentar.",
                            style: TextStyle(color: cocoaColor),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              var item = comments[index];
                              String namaUser = item['nama'] ?? 'Anonim';
                              String isiKomentar =
                                  item['comment'] ?? item['komentar'] ?? '';
                              String ratingVal = "${item['rating'] ?? '0'}";

                              return Card(
                                color: creamColor.withOpacity(0.3),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: creamColor.withOpacity(0.8),
                                  ),
                                ),
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: ListTile(
                                  title: Text(
                                    namaUser,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: cocoaColor,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      isiKomentar,
                                      style: const TextStyle(color: cocoaColor),
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sunnyYellowColor.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "⭐ $ratingVal",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: cocoaColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}