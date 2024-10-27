import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // Mengimpor paket image

class ImagePage extends StatelessWidget {
  final String filePath;

  ImagePage({required this.filePath});

  Future<img.Image?> _loadAndFixImage() async {
    // Membaca gambar dari file
    final file = File(filePath);
    if (await file.exists()) {
      // Mengonversi gambar menjadi format img
      final imageBytes = await file.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      // Mengembalikan gambar asli tanpa rotasi
      return originalImage;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Deteksi Gambar')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<img.Image?>(
          future: _loadAndFixImage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final image = snapshot.data;
              return Column(
                children: [
                  // Menambahkan padding untuk menghindari tumpang tindih dengan AppBar
                  SizedBox(height: 20), // Padding di atas
                  // Pratinjau Gambar
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black54, // Warna transparan untuk latar belakang
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Center(
                      child: image != null
                          ? Image.memory(
                              img.encodeJpg(image), // Mengonversi kembali ke byte
                              fit: BoxFit.contain,
                            )
                          : Text(
                              'Gambar tidak ditemukan',
                              style: TextStyle(color: Colors.white, fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // List objek yang terdeteksi
                  Expanded(
                    child: ListView.builder(
                      itemCount: 5, // contoh jumlah objek
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('🍎')),
                            title: Text('${index + 1}. Objek ${index + 1}'),
                            subtitle: Text('Detected at: 10:${(index * 5 + 5).toString().padLeft(2, '0')} AM'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
