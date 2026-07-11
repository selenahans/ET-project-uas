import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'read_comic.dart';
import 'dart:convert';
// import 'package:memory_game_sawit/main.dart';

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
  // Fungsi fetch data berdasarkan idKategori yang dikirim
  Future<Map<String, dynamic>> fetchComicsByCategory() async {
    // Sesuaikan URL dengan nama file API PHP barumu
    var url = Uri.parse(
      "https://ubaya.cloud/flutter/160423025/komiku/get_list_comics_by_category.php?kategori_id=${widget.idKategori}",
    );

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data; // Mengembalikan seluruh map JSON
      } else {
        throw Exception("Gagal memuat data dari server");
      }
    } catch (e) {
      throw Exception("Kesalahan koneksi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Menampilkan nama kategori di AppBar
        title: Text("Kategori: ${widget.namaKategori}"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchComicsByCategory(),
        builder: (context, snapshot) {
          // 1. Kondisi Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Kondisi Error Koneksi / SQL
          else if (snapshot.hasError) {
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

          // 3. Kondisi Jika Data Kosong dari API (Result == 'EMPTY' atau 'ERROR')
          var responseData = snapshot.data;
          List<dynamic> listKomik =
              responseData?['data'] ?? []; // Pindahkan ke atas untuk dicek

          if (responseData == null ||
              responseData['result'] == 'EMPTY' ||
              responseData['result'] == 'ERROR' ||
              listKomik.isEmpty) {
            // <--- TAMBAHKAN PENGECEKAN INI

            // Ambil pesan dari API, jika tidak ada pakai pesan default
            String msg =
                responseData?['message'] ??
                "Belum ada komik untuk kategori ini.";

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  msg,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    // fontWeight: FontWeight.medium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // 4. Kondisi Sukses (Result == 'OK')
          // List<dynamic> listKomik = responseData['data'] ?? [];

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Menampilkan 2 kolom komik berjajar
              childAspectRatio: 0.65, // Mengatur rasio tinggi/lebar kotak komik
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: listKomik.length,
            itemBuilder: (context, index) {
              var komik = listKomik[index];

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: InkWell(
                  onTap: () {
                    int komikId = int.tryParse(komik['id'].toString()) ?? 0;
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
                      // Gambar Poster Komik
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10.0),
                          ),
                          child: Image.network(
                            komik['poster'] ?? '',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Informasi Judul dan Views Komik
                      // Informasi Judul, Rating, dan Views Komik
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
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Baris Rating & Views
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Tampilan Rating dengan Icon Bintang
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${komik['rating_avg'] ?? '0.0'}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),

                                // Tampilan Views
                                Text(
                                  "👁️ ${komik['views'] ?? 0}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
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
          );
        },
      ),
    );
  }
}
