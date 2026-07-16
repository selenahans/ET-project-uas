import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_chapter.dart';

class ManageComicScreen extends StatefulWidget {
  final int komikId;
  final String judulKomik;

  const ManageComicScreen({
    super.key,
    required this.komikId,
    required this.judulKomik,
  });

  @override
  State<ManageComicScreen> createState() => _ManageComicScreenState();
}

class _ManageComicScreenState extends State<ManageComicScreen> {
  static const Color colorOrange = Color(0xFFEC642A);
  static const Color colorSunnyYellow = Color(0xFFFAAA21);
  static const Color colorCream = Color(0xFFFDE2CD);
  static const Color colorCocoa = Color(0xFF642D0A);

  bool _isLoading = true;
  Map<String, dynamic>? _comicData;
  List<dynamic> _chapters = [];

  @override
  void initState() {
    super.initState();
    _fetchComicData();
  }

  Future<void> _fetchComicData() async {
    setState(() => _isLoading = true);
    final Uri url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/get_manage_comic.php?komik_id=${widget.komikId}",
    );

    try {
      var response = await http.get(url);
      print("STATUS CODE: ${response.statusCode}");
      print("RAW RESPONSE: ${response.body}");
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['result'] == 'OK') {
          setState(() {
            _comicData = jsonResponse['comic'];
            _chapters = jsonResponse['chapters'] ?? [];
            _isLoading = false;
          });
        } else {
          _showError(jsonResponse['message']);
        }
      } else {
        _showError("Gagal terhubung ke server.");
      }
    } catch (e) {
      print("DETAIL ERROR: $e");
      _showError("Terjadi kesalahan: $e");
    }
  }

  Future<void> _toggleStatus() async {
    if (_comicData == null) return;

    String currentStatus = _comicData!['status'];
    String newStatus = currentStatus == 'Published' ? 'Draft' : 'Published';

   
    if (newStatus == 'Published' && _chapters.isEmpty) {
      _showError("Komik minimal harus memiliki 1 Chapter untuk di-publish!");
      return;
    }

    final Uri url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/update_comic_status.php",
    );

    try {
      var response = await http.post(
        url,
        body: {'komik_id': widget.komikId.toString(), 'status': newStatus},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['result'] == 'SUCCESS') {
     
          _fetchComicData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Status komik diubah menjadi $newStatus"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showError(data['message']);
        }
      }
    } catch (e) {
      _showError("Gagal mengupdate status: $e");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
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
          widget.judulKomik,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          bool? refreshed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddChapterScreen(komikId: widget.komikId),
            ),
          );
          if (refreshed == true) {
            _fetchComicData();
          }
        },
        backgroundColor: colorOrange,
        icon: const Icon(Icons.add_box_rounded, color: Colors.white),
        label: const Text(
          "Tambah Chapter",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: colorOrange))
          : _comicData == null
          ? const Center(child: Text("Data tidak ditemukan."))
          : RefreshIndicator(
              color: colorOrange,
              onRefresh: _fetchComicData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _comicData!['poster'] ?? '',
                              width: 90,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 90,
                                height: 120,
                                color: colorCream,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: colorCocoa,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _comicData!['judul'] ?? '',
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorCocoa,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.visibility,
                                      size: 14,
                                      color: colorOrange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${_comicData!['views'] ?? 0} Views",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorCocoa.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                ElevatedButton.icon(
                                  onPressed: _toggleStatus,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _comicData!['status'] == 'Published'
                                        ? Colors.green
                                        : colorCocoa.withOpacity(0.6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  icon: Icon(
                                    _comicData!['status'] == 'Published'
                                        ? Icons.public
                                        : Icons.public_off,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _comicData!['status'] == 'Published'
                                        ? "Published"
                                        : "Draft",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      "Daftar Chapter",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorCocoa,
                      ),
                    ),
                    const SizedBox(height: 12),

                    
                    if (_chapters.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorCream.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorCream),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.menu_book,
                              size: 48,
                              color: colorCream,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Belum ada chapter.\nKomikmu tidak bisa di-publish.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorCocoa.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _chapters.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          var chapter = _chapters[index];
                          return ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorCream.withOpacity(0.5),
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: colorCream,
                              child: Text(
                                "${chapter['chapter'] ?? chapter['urutan_chapter'] ?? '-'}",
                                style: const TextStyle(
                                  color: colorOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              chapter['judul_chapter'] ?? 'Tanpa Judul',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorCocoa,
                              ),
                            ),
                            subtitle: Text(
                              "Dibuat: ${chapter['created_at'] ?? '-'}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: colorCream,
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 80), 
                  ],
                ),
              ),
            ),
    );
  }
}
