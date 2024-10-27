import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'settings_page.dart';
import 'widgets/quick_access_button.dart';
import 'detection_results_page.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> imgList = [
      'lib/image/image1.png',
      'lib/image/image2.jpg',
      'lib/image/image3.png',
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'lib/image/bg.jpg'), // Ganti dengan path gambar latar belakang
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Menambahkan Logo
              Image.asset(
                'lib/image/logo.png', // Ganti dengan path logo Anda
                width: 200,
                height: 200,
              ),
              // SizedBox(height: 10.0), // Jarak antara logo dan deskripsi

              // Deskripsi Aplikasi
              Text(
                'Aplikasi SmartEye untuk deteksi objek real-time menggunakan teknologi AI.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white, // Warna teks
                  fontSize: 16, // Ukuran font
                  fontWeight: FontWeight.w500, // Ketebalan font
                ),
              ),
              SizedBox(height: 20.0), // Jarak antara deskripsi dan carousel

              // Carousel Slider
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 2.0,
                  viewportFraction: 0.8,
                ),
                items: imgList
                    .map((item) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            image: DecorationImage(
                              image: AssetImage(item),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              SizedBox(height: 20.0), // Jarak antara carousel dan tombol

              QuickAccessButton(),
              SizedBox(height: 20.0), // Jarak antar elemen

              // Card History
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.history, color: Colors.blue),
                  title: Text('History'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DetectionResultsPage()),
                    );
                  },
                ),
              ),
              SizedBox(height: 12.0),

              // Card Pengaturan
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.settings, color: Colors.green),
                  title: Text('Pengaturan'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
