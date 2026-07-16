import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReadComic extends StatefulWidget {
  final int komikId;
  final String judulKomik;
  final int? chapterId;

  const ReadComic({
    super.key,
    required this.komikId,
    required this.judulKomik,
    this.chapterId,
  });

  @override
  State<ReadComic> createState() => _ReadComicState();
}

class _ReadComicState extends State<ReadComic> {
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 1.0;
  bool _isSubmitting = false;
  bool _isRatingExpanded = false;

  int? _replyingToCommentId;
  String? _replyingToUsername;

  late Future<Map<String, dynamic>> _comicDetailFuture;

  static const Color orangeColor = Color(0xFFEC642A);
  static const Color sunnyYellowColor = Color(0xFFFAAA21);
  static const Color creamColor = Color(0xFFFDE2CD);
  static const Color cocoaColor = Color(0xFF642D0A);

  @override
  void initState() {
    super.initState();
    _comicDetailFuture = fetchComicDetail();
  }

  @override
  void didUpdateWidget(covariant ReadComic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterId != widget.chapterId) {
      _reloadComicDetail();
    }
  }

  void _reloadComicDetail() {
    setState(() {
      _comicDetailFuture = fetchComicDetail();
    });
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    bool isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[300] : orangeColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: orangeColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == "Prev") ...[
              Icon(
                icon,
                size: 16,
                color: isDisabled ? Colors.grey[600] : Colors.white,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? Colors.grey[600] : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (label == "Next") ...[
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 16,
                color: isDisabled ? Colors.grey[600] : Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  int? nextId;
  int? prevId;

  void _loadNewChapter(int targetChapterId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReadComic(
          komikId: widget.komikId,
          judulKomik: widget.judulKomik,
          chapterId: targetChapterId,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> fetchComicDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt("user_id") ?? 1;

    String urlStr =
        "https://ubaya.cloud/flutter/160423025/komiku/get_comic_detail.php?komik_id=${widget.komikId}&user_id=$userId";

    if (widget.chapterId != null) {
      urlStr += "&chapter_id=${widget.chapterId}";
    }

    var url = Uri.parse(urlStr);

    print("URL DETAIL KOMIK: $url");

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['user_rating'] != null) {
          double ratingDariServer =
              double.tryParse(data['user_rating'].toString()) ?? 0.0;

          if (ratingDariServer > 0.0) {
            _userRating = ratingDariServer;
            _isRatingExpanded = true;
          }
        }

        return data;
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

    Map<String, String> requestBody = {
      "komik_id": widget.komikId.toString(),
      "user_id": userId.toString(),
      "comment": _commentController.text.trim(),
    };

    if (_replyingToCommentId != null) {
      requestBody["parent_id"] = _replyingToCommentId.toString();
    }

    try {
      var response = await http.post(url, body: requestBody);
      var data = jsonDecode(response.body);

      if (data['result'] == 'OK') {
        _commentController.clear();
        setState(() {
          _replyingToCommentId = null;
          _replyingToUsername = null;
        });
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

  Future<void> _saveRating(double rating) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt("user_id") ?? 1;

    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/add_rating.php",
    );

    try {
      var response = await http.post(
        url,
        body: {
          "komik_id": widget.komikId.toString(),
          "user_id": userId.toString(),
          "rating": rating.toString(),
        },
      );

      var data = jsonDecode(response.body);

      if (data['result'] == 'OK') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: cocoaColor,
              duration: const Duration(seconds: 1),
            ),
          );
        }
        _reloadComicDetail();
      }
    } catch (e) {
      print("Error saat menyimpan rating: $e");
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
      key: ValueKey(widget.chapterId),
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
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          var responseData = snapshot.data;
          if (responseData == null || responseData['result'] == 'ERROR') {
            return const Center(child: Text("Gagal memuat halaman."));
          }

          var pages = responseData['pages'] as List<dynamic>? ?? [];
          var rawComments = responseData['comments'] as List<dynamic>? ?? [];
          String chapterTitle = responseData['chapter_title'] ?? "Chapter 1";
          bool canInteract = responseData['can_interact'] == true;

          int? prevId = responseData['prev_chapter_id'] != null
              ? int.tryParse(responseData['prev_chapter_id'].toString())
              : null;
          int? nextId = responseData['next_chapter_id'] != null
              ? int.tryParse(responseData['next_chapter_id'].toString())
              : null;

          List<dynamic> parentComments = [];
          Map<int, List<dynamic>> repliesMap = {};

          for (var c in rawComments) {
            if (c['parent_id'] == null) {
              parentComments.add(c);
            } else {
              int pId = int.parse(c['parent_id'].toString());
              if (!repliesMap.containsKey(pId)) {
                repliesMap[pId] = [];
              }
              repliesMap[pId]!.add(c);
            }
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
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

              
              if (pages.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      "Halaman komik belum tersedia.",
                      style: TextStyle(color: cocoaColor),
                    ),
                  ),
                )
              else
                Column(
                  children: pages.asMap().entries.map((entry) {
                    int index = entry.key;
                    String pageUrl = entry.value.toString();

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
                              pageUrl,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
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
                                    child: Icon(
                                      Icons.broken_image,
                                      color: orangeColor,
                                      size: 36,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
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
                  }).toList(),
                ),

              
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(color: creamColor, thickness: 1.5),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "Akhir Chapter",
                            style: TextStyle(color: cocoaColor, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: creamColor, thickness: 1.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavButton(
                          label: "Prev",
                          icon: Icons.arrow_back_ios_rounded,
                          onTap: prevId != null
                              ? () => _loadNewChapter(prevId)
                              : null,
                        ),

                        _buildNavButton(
                          label: "Next",
                          icon: Icons.arrow_forward_ios_rounded,
                          onTap: nextId != null
                              ? () => _loadNewChapter(nextId)
                              : null,
                        ),
                      ],
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
                    Text(
                      canInteract ? "Beri Rating & Komentar" : "Mode Preview",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cocoaColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (!canInteract)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: creamColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: orangeColor.withOpacity(0.4),
                          ),
                        ),
                        child: const Text(
                          "Komik ini masih berstatus Draft. Pembaca hanya dapat melihat preview dan belum dapat memberi rating atau komentar.",
                          style: TextStyle(
                            color: cocoaColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else ...[
                      AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: _isRatingExpanded
                            ? Row(
                                children: List.generate(5, (index) {
                                  bool isSelected = index < _userRating;
                                  return GestureDetector(
                                    onTap: () {
                                      double selectedRating = index + 1.0;
                                      setState(
                                        () => _userRating = selectedRating,
                                      );
                                      _saveRating(selectedRating);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionBuilder: (child, animation) =>
                                            ScaleTransition(
                                              scale: animation,
                                              child: child,
                                            ),
                                        child: Icon(
                                          isSelected
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          key: ValueKey<bool>(isSelected),
                                          color: isSelected
                                              ? sunnyYellowColor
                                              : cocoaColor.withOpacity(0.3),
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              )
                            : InkWell(
                                onTap: () =>
                                    setState(() => _isRatingExpanded = true),
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: sunnyYellowColor,
                                      size: 36,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Ketuk untuk beri rating",
                                      style: TextStyle(
                                        color: cocoaColor.withOpacity(0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),

                      if (_replyingToCommentId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: creamColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Membalas @$_replyingToUsername",
                                style: const TextStyle(
                                  color: cocoaColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() {
                                  _replyingToCommentId = null;
                                  _replyingToUsername = null;
                                }),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: cocoaColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                      TextField(
                        controller: _commentController,
                        style: const TextStyle(color: cocoaColor),
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null
                              ? "Tulis balasan..."
                              : "Tulis komentar...",
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
                          child: _isSubmitting
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
                                  style: TextStyle(fontWeight: FontWeight.bold),
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

                      
                      parentComments.isEmpty
                          ? const Text(
                              "Belum ada komentar.",
                              style: TextStyle(color: cocoaColor),
                            )
                          : Column(
                              children: parentComments.map((parent) {
                                int parentId = int.parse(
                                  parent['id'].toString(),
                                );
                                List<dynamic> replies =
                                    repliesMap[parentId] ?? [];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: creamColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: creamColor.withOpacity(0.8),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            parent['username'] ?? 'Anonim',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: cocoaColor,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: sunnyYellowColor
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "⭐ ${parent['rating'] ?? '-'}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: cocoaColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        parent['isi_komentar'] ?? '',
                                        style: const TextStyle(
                                          color: cocoaColor,
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _replyingToCommentId = parentId;
                                              _replyingToUsername =
                                                  parent['username'] ??
                                                  'Anonim';
                                            });
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 4.0,
                                            ),
                                            child: Text(
                                              "Balas",
                                              style: TextStyle(
                                                color: orangeColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (replies.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            top: 8.0,
                                            left: 16.0,
                                          ),
                                          padding: const EdgeInsets.only(
                                            left: 12.0,
                                          ),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: creamColor,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: replies.map((reply) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "↳ ${reply['username'] ?? 'Anonim'}",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: cocoaColor,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      reply['isi_komentar'] ??
                                                          '',
                                                      style: const TextStyle(
                                                        color: cocoaColor,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
