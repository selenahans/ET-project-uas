import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final TextEditingController _deskripsiController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _judulController.dispose();
    _posterController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _submitComic() async {
    if (!_formKey.currentState!.validate()) return;

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
          'deskripsi': _deskripsiController.text.trim(),
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
            Navigator.pop(context, true); // Kembali & memicu auto-refresh
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
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: colorCocoa.withOpacity(0.4),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: colorOrange),
      filled: true,
      fillColor: colorCream.withOpacity(0.4),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: colorCream, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: colorOrange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
          style: TextStyle(
            color: colorCocoa,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Judul Komik",
                style: TextStyle(
                  color: colorCocoa,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _judulController,
                style: const TextStyle(color: colorCocoa, fontSize: 14),
                decoration: _buildInputDecoration(
                  "Masukkan judul komik...",
                  Icons.title_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Judul tidak boleh kosong";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                "URL Poster / Cover",
                style: TextStyle(
                  color: colorCocoa,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _posterController,
                style: const TextStyle(color: colorCocoa, fontSize: 14),
                decoration: _buildInputDecoration(
                  "https://example.com/poster.jpg",
                  Icons.image_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "URL poster tidak boleh kosong";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                "Deskripsi / Sinopsis",
                style: TextStyle(
                  color: colorCocoa,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                style: const TextStyle(color: colorCocoa, fontSize: 14),
                decoration: _buildInputDecoration(
                  "Tulis deskripsi atau sinopsis singkat...",
                  Icons.description_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Deskripsi tidak boleh kosong";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Terbitkan Komik",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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