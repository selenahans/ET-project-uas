import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

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
  final TextEditingController _posterUrlController = TextEditingController();

  bool _isLoadingSubmit = false;
  bool _isLoadingCategories = true;

  List<Map<String, dynamic>> _kategoriList = [];
  final List<int> _selectedKategoriIds = [];

  String _posterType = 'url';
  String _posterBase64 = '';
  String _posterFilename = '';
  Uint8List? _posterImageBytes;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _posterUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    final Uri url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/get_categories.php",
    );
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['result'] == 'OK') {
          if (mounted) {
            setState(() {
              _kategoriList = List<Map<String, dynamic>>.from(
                jsonResponse['data'],
              );
              _isLoadingCategories = false;
            });
          }
        } else {
          _showError(jsonResponse['message'] ?? "Gagal memuat kategori");
          if (mounted) setState(() => _isLoadingCategories = false);
        }
      } else {
        _showError("Error server: ${response.statusCode}");
        if (mounted) setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      _showError("Koneksi bermasalah: $e");
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickPosterImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        List<int> imageBytes = await image.readAsBytes();
        setState(() {
          _posterImageBytes = Uint8List.fromList(imageBytes);
          _posterBase64 = base64Encode(imageBytes);
          _posterFilename = image.name;
        });
      }
    } catch (e) {
      _showError("Gagal memilih gambar: $e");
    }
  }

  Future<void> _submitComic() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKategoriIds.isEmpty) {
      _showError("Pilih minimal 1 kategori!");
      return;
    }

    String posterDataToSubmit = '';
    if (_posterType == 'url') {
      if (_posterUrlController.text.trim().isEmpty) {
        _showError("URL Poster wajib diisi!");
        return;
      }
      posterDataToSubmit = _posterUrlController.text.trim();
    } else {
      if (_posterBase64.isEmpty) {
        _showError("Harap pilih gambar untuk poster!");
        return;
      }
      posterDataToSubmit = _posterBase64;
    }

    setState(() {
      _isLoadingSubmit = true;
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
          'poster_type': _posterType,
          'poster_data': posterDataToSubmit,
          'kategori_ids': jsonEncode(_selectedKategoriIds),
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['result'] == 'SUCCESS') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Buku Komik berhasil dibuat!"),
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
          _isLoadingSubmit = false;
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
          "Buat Buku Komik Baru",
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
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorCream),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pilih Poster Komik:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorCocoa,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _posterType,
                      items: const [
                        DropdownMenuItem(
                          value: 'url',
                          child: Text("Gunakan Link URL"),
                        ),
                        DropdownMenuItem(
                          value: 'base64',
                          child: Text("Upload Foto Lokal"),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _posterType = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    if (_posterType == 'url') ...[
                      TextFormField(
                        controller: _posterUrlController,
                        decoration: _buildInputDecoration(
                          "Masukkan URL Poster",
                          Icons.link,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_posterUrlController.text.isNotEmpty)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _posterUrlController.text,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Text(
                                    "Format URL gambar tidak valid atau rusak.",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                    ] else ...[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickPosterImage,
                            icon: const Icon(Icons.upload_file),
                            label: const Text("Pilih Foto"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorCream,
                              foregroundColor: colorCocoa,
                            ),
                          ),
                          Text(
                            _posterFilename.isEmpty
                                ? "Belum ada file"
                                : _posterFilename,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_posterImageBytes != null)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _posterImageBytes!,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Pilih Kategori (Bisa lebih dari 1):",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorCocoa,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),

              _isLoadingCategories
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: colorOrange),
                      ),
                    )
                  : _kategoriList.isEmpty
                  ? const Text("Belum ada kategori tersedia.")
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorCream),
                      ),
                      child: Column(
                        children: _kategoriList.map((kategori) {
                          return CheckboxListTile(
                            activeColor: colorOrange,
                            title: Text(kategori['nama_kategori']),
                            value: _selectedKategoriIds.contains(
                              kategori['id'],
                            ),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedKategoriIds.add(kategori['id']);
                                } else {
                                  _selectedKategoriIds.remove(kategori['id']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoadingSubmit || _isLoadingCategories
                      ? null
                      : _submitComic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoadingSubmit
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Buat Komik",
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
