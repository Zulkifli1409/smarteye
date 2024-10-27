import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pastikan untuk menambahkan package ini

class DetectionResultsPage extends StatelessWidget {
  // Daftar contoh hasil deteksi
  final List<Map<String, dynamic>> detectedObjects = [
    {
      'date': '2024-10-26',
      'icon': '🍎',
      'objects': ['Objek 1', 'Objek 2'],
    },
    {
      'date': '2024-10-27',
      'icon': '🐶',
      'objects': ['Objek 3', 'Objek 4'],
    },
    // Tambahkan lebih banyak objek terdeteksi di sini
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hasil Deteksi')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'), // Pastikan path ini benar
            fit: BoxFit.cover,
          ),
        ),
        child: ListView.builder(
          itemCount: detectedObjects.length,
          itemBuilder: (context, index) {
            final obj = detectedObjects[index];
            final formattedDate = DateFormat('dd MMMM yyyy')
                .format(DateTime.parse(obj['date']!)); // Format tanggal

            return Card(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              color: Colors
                  .black54, // Memberikan latar belakang transparan pada card
              child: ExpansionTile(
                title: Text(
                  '${index + 1}. $formattedDate ${obj['icon']}', // Format nomor, tanggal, dan icon
                  style: TextStyle(color: Colors.white), // Mengatur warna teks
                ),
                subtitle: Text(
                  'Tap untuk melihat objek terdeteksi',
                  style:
                      TextStyle(color: Colors.white70), // Mengatur warna teks
                ),
                children: obj['objects'].map<Widget>((object) {
                  return ListTile(
                    title: Text(object,
                        style: TextStyle(
                            color: Colors.white)), // Menampilkan nama objek
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
