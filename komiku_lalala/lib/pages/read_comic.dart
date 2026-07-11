import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReadComic extends StatefulWidget {
  final int komikId;
  final String judulKomik;

  const ReadComic({
    super.key,
    required this.komikId,
    required this.judulKomik,
  });

  @override
  State<ReadComic> createState() => _ReadComicState();
}

class _ReadComicState extends State<ReadComic> {
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 5.0;
  bool _isSubmitting = false;

  // Variabel penampung Future agar tidak reload terus-menerus
  late Future<Map<String, dynamic>> _comicDetailFuture;

  @override
  void initState() {
    super.initState();
    _comicDetailFuture = fetchComicDetail();
  }

  // Fungsi reload data saat berhasil kirim komentar
  void _reloadComicDetail() {
    setState(() {
      _comicDetailFuture = fetchComicDetail();
    });
  }

  // Fetch detail komik, gambar halaman, dan komentar
  Future<Map<String, dynamic>> fetchComicDetail() async {
    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/get_comic_detail.php?komik_id=${widget.komikId}",
    );

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal memuat detail komik (Status Code: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Kesalahan koneksi: $e");
    }
  }

  // Kirim Komentar & Rating
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt("user_id") ?? 1; // ID user dari SharedPreferences

    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/add_comment.php",
    );

    try {
      var response = await http.post(url, body: {
        "komik_id": widget.komikId.toString(),
        "user_id": userId.toString(),
        "comment": _commentController.text,
        "rating": _userRating.toString(),
      });

      var data = jsonDecode(response.body);

      if (data['result'] == 'OK') {
        _commentController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Komentar berhasil dikirim!")),
          );
        }
        _reloadComicDetail(); // Reload data via Future baru
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${data['message']}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
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
      appBar: AppBar(
        title: Text(widget.judulKomik),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _comicDetailFuture,
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error Connection/SQL
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

          // 3. Response API Error / Empty
          if (responseData == null || responseData['result'] == 'ERROR') {
            return Center(
              child: Text(
                responseData?['message'] ?? "Gagal memuat halaman komik.",
              ),
            );
          }

          var pages = responseData['pages'] as List<dynamic>? ?? [];
          var comments = responseData['comments'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. DAFTAR GAMBAR HALAMAN KOMIK
                pages.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            "Halaman komik belum tersedia.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pages.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            pages[index] ?? '',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                const Divider(height: 32, thickness: 2),

                // 2. FORM INPUT RATING & KOMENTAR
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Beri Rating & Komentar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating Bar Sederhana
                      Row(
                        children: [
                          const Text(
                            "Rating: ",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          DropdownButton<double>(
                            value: _userRating,
                            items: [1.0, 2.0, 3.0, 4.0, 5.0]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text("⭐ $e"),
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
                        decoration: const InputDecoration(
                          hintText: "Tulis komentar...",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitComment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Kirim Komentar"),
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Text(
                        "Komentar Pembaca",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      comments.isEmpty
                          ? const Text(
                              "Belum ada komentar.",
                              style: TextStyle(color: Colors.grey),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                var item = comments[index];
                                // Fallback field nama/komentar
                                String namaUser = item['nama'] ?? 'Anonim';
                                String isiKomentar =
                                    item['comment'] ?? item['komentar'] ?? '';
                                String ratingVal =
                                    "${item['rating'] ?? '0'}";

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    title: Text(
                                      namaUser,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(isiKomentar),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "⭐ $ratingVal",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
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