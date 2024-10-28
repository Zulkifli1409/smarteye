import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true; // Status notifikasi
  List<String> cocoNames = []; // Daftar objek dari coco.names
  List<bool> selectedObjects = []; // Status checklist objek
  String searchQuery = ""; // Variabel untuk pencarian

  @override
  void initState() {
    super.initState();
    loadCocoNames();
  }

  Future<void> loadCocoNames() async {
    try {
      // Membaca file coco.names dari folder backend/darknet/data/
      final content =
          await rootBundle.loadString('backend/darknet/data/coco.names');
      final lines = content.split('\n');

      cocoNames = lines.where((line) => line.isNotEmpty).toList();

      // Inisialisasi checklist status sesuai jumlah objek
      selectedObjects = List<bool>.filled(cocoNames.length, false);
      setState(() {});
    } catch (e) {
      print("Error loading coco.names file: $e");
    }
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
            SwitchListTile(
              title: Text('Aktifkan Notifikasi Ancaman',
                  style: TextStyle(color: Colors.white)),
              value: notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
            ),
            Divider(color: Colors.white),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                style: TextStyle(color: Colors.white), // Warna teks pencarian
                decoration: InputDecoration(
                  labelText: 'Cari Objek',
                  labelStyle: TextStyle(color: Colors.white),
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
                  if (cocoNames[index].toLowerCase().contains(searchQuery)) {
                    return CheckboxListTile(
                      title: Text(
                        cocoNames[index],
                        style: TextStyle(
                          color: const Color.fromARGB(255, 255, 255, 255), // Warna teks daftar
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: selectedObjects[index],
                      onChanged: (bool? value) {
                        setState(() {
                          selectedObjects[index] = value!;
                        });
                      },
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
