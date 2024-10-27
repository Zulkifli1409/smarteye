import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true; // Status notifikasi
  List<Map<String, String>> cocoNames = []; // Daftar objek dari coco.names
  List<bool> selectedObjects = []; // Status checklist objek
  String searchQuery = ""; // Variabel untuk pencarian

  @override
  void initState() {
    super.initState();
    loadCocoNames();
  }

  void loadCocoNames() {
    // Simulasi pembacaan file coco.names
    // Ganti dengan pembacaan file nyata jika perlu
    cocoNames = [
      {'english': 'person', 'indonesian': 'orang'},
      {'english': 'bicycle', 'indonesian': 'sepeda'},
      {'english': 'car', 'indonesian': 'mobil'},
      {'english': 'motorbike', 'indonesian': 'motor'},
      {'english': 'aeroplane', 'indonesian': 'pesawat terbang'},
      {'english': 'bus', 'indonesian': 'bus'},
      {'english': 'train', 'indonesian': 'kereta'},
      {'english': 'truck', 'indonesian': 'truk'},
      {'english': 'boat', 'indonesian': 'perahu'},
      {'english': 'traffic light', 'indonesian': 'lampu lalu lintas'},
      {'english': 'fire hydrant', 'indonesian': 'hydrant pemadam kebakaran'},
      {'english': 'stop sign', 'indonesian': 'tanda berhenti'},
      {'english': 'parking meter', 'indonesian': 'meter parkir'},
      {'english': 'bench', 'indonesian': 'bangku'},
      {'english': 'bird', 'indonesian': 'burung'},
      {'english': 'cat', 'indonesian': 'kucing'},
      {'english': 'dog', 'indonesian': 'anjing'},
      {'english': 'horse', 'indonesian': 'kuda'},
      {'english': 'sheep', 'indonesian': 'domba'},
      {'english': 'cow', 'indonesian': 'sapi'},
      {'english': 'elephant', 'indonesian': 'gajah'},
      {'english': 'bear', 'indonesian': 'beruang'},
      {'english': 'zebra', 'indonesian': 'zebra'},
      {'english': 'giraffe', 'indonesian': 'jiraf'},
      // Tambahkan lebih banyak objek sesuai dengan file coco.names
    ];
    // Inisialisasi checklist status sesuai jumlah objek
    selectedObjects = List<bool>.filled(cocoNames.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Halaman Pengaturan')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'), // Pastikan path ini benar
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Pengaturan Aktifkan Notifikasi
            SwitchListTile(
              title: Text('Aktifkan Notifikasi Ancaman',
                  style: TextStyle(color: Colors.white)), // Mengatur warna teks
              value: notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
            ),
            Divider(color: Colors.white), // Pemisah
            // Pencarian
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Cari Objek',
                  labelStyle:
                      TextStyle(color: Colors.white), // Mengatur warna label
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: cocoNames.length,
                itemBuilder: (context, index) {
                  if (cocoNames[index]['indonesian']!
                      .toLowerCase()
                      .contains(searchQuery)) {
                    return CheckboxListTile(
                      title: Text(
                          '${cocoNames[index]['english']} (${cocoNames[index]['indonesian']})',
                          style: TextStyle(
                              color: Colors.white)), // Mengatur warna teks
                      value: selectedObjects[index],
                      onChanged: (bool? value) {
                        setState(() {
                          selectedObjects[index] = value!;
                        });
                      },
                    );
                  }
                  return SizedBox
                      .shrink(); // Menghindari item yang tidak sesuai pencarian
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
