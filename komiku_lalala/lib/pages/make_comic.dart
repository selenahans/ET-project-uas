import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class MakeComic extends StatefulWidget {
  final int userId;

  const MakeComic({super.key, required this.userId});

  @override
  State<MakeComic> createState() => _MakeComicState();
}

class _MakeComicState extends State<MakeComic> {
  static const Color colorOrange = Color(0xFFEC642A);
  static const Color colorCream = Color(0xFFFDE2CD);
  static const Color colorCocoa = Color(0xFF642D0A);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _posterController = TextEditingController();
  final TextEditingController _chapterTitleController = TextEditingController();

  List<Map<String, dynamic>> _pages = [
    {
      'type': 'url',
      'controller': TextEditingController(),
      'base64': '',
      'filename': '',
    },
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _judulController.dispose();
    _posterController.dispose();
    _chapterTitleController.dispose();
    for (var page in _pages) {
      page['controller'].dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        List<int> imageBytes = await image.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        setState(() {
          _pages[index]['base64'] = base64Image;
          _pages[index]['filename'] = image.name;
        });
      } else {
        print("Pemilihan gambar dibatalkan.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _submitComic() async {
    if (!_formKey.currentState!.validate()) return;

    List<Map<String, String>> finalPages = [];
    for (var p in _pages) {
      if (p['type'] == 'url') {
        if (p['controller'].text.toString().trim().isNotEmpty) {
          finalPages.add({'type': 'url', 'data': p['controller'].text.trim()});
        }
      } else if (p['type'] == 'base64') {
        if (p['base64'].toString().isNotEmpty) {
          finalPages.add({'type': 'base64', 'data': p['base64']});
        }
      }
    }

    if (finalPages.isEmpty) {
      _showError("Minimal harus ada 1 halaman komik yang diisi!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Uri url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/create_comic.php",
    );

    try {
      var response = await http.post(
        url,
        body: {
          'user_id': widget.userId.toString(),
          'judul': _judulController.text.trim(),
          'poster': _posterController.text.trim(),
          'judul_chapter': _chapterTitleController.text.trim(),
          'pages': jsonEncode(finalPages), // Kirim sebagai JSON string
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['result'] == 'SUCCESS') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Komik berhasil diterbitkan!"),
                backgroundColor: colorOrange,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          _showError(data['message'] ?? "Gagal menambahkan komik.");
        }
      } else {
        _showError("Terjadi kesalahan pada server (${response.statusCode})");
      }
    } catch (e) {
      _showError("Kesalahan koneksi: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _addPageInput() {
    setState(() {
      _pages.add({
        'type': 'url',
        'controller': TextEditingController(),
        'base64': '',
        'filename': '',
      });
    });
  }

  void _removePageInput(int index) {
    if (_pages.length > 1) {
      setState(() {
        _pages[index]['controller'].dispose();
        _pages.removeAt(index);
      });
    }
  }

  InputDecoration _buildInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: colorCocoa.withOpacity(0.4), fontSize: 14),
      prefixIcon: Icon(icon, color: colorOrange),
      filled: true,
      fillColor: colorCream.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
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
          "Buat Komik Baru",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _judulController,
                decoration: _buildInputDecoration("Judul Komik", Icons.title),
                validator: (val) =>
                    (val == null || val.isEmpty) ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _posterController,
                decoration: _buildInputDecoration(
                  "URL Poster Komik",
                  Icons.image,
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _chapterTitleController,
                decoration: _buildInputDecoration(
                  "Judul Chapter",
                  Icons.book,
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Halaman Chapter",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorCocoa,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addPageInput,
                    icon: const Icon(Icons.add, color: colorOrange),
                    label: const Text(
                      "Tambah Hal",
                      style: TextStyle(color: colorOrange),
                    ),
                  ),
                ],
              ),

              Column(
                children: List.generate(_pages.length, (index) {
                  var page = _pages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorCream),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Halaman ${index + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_pages.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _removePageInput(index),
                              ),
                          ],
                        ),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: page['type'],
                          items: const [
                            DropdownMenuItem(
                              value: 'url',
                              child: Text("Gunakan Link URL"),
                            ),
                            DropdownMenuItem(
                              value: 'base64',
                              child: Text("Upload File"),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              page['type'] = val;
                            });
                          },
                        ),
                        const SizedBox(height: 8),

                        if (page['type'] == 'url')
                          TextFormField(
                            controller: page['controller'],
                            decoration: _buildInputDecoration(
                              "Masukkan URL Gambar",
                              Icons.link,
                            ),
                          )
                        else
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(index),
                                icon: const Icon(Icons.upload_file),
                                label: const Text("Pilih Gambar"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorCream,
                                  foregroundColor: colorCocoa,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  page['filename'] == ''
                                      ? "Belum ada file"
                                      : page['filename'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Terbitkan Komik",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
