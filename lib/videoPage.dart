import 'dart:io'; // Tambahkan impor ini
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  final String filePath;

  VideoPage({required this.filePath});

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller video
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {}); // Refresh UI setelah video diinisialisasi
      });
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Jangan lupa untuk membebaskan controller saat tidak digunakan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Deteksi Video')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'lib/image/bg.jpg'), // Ganti dengan path gambar latar belakang
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding:
              const EdgeInsets.only(top: 80.0), // Menambahkan padding di atas
          child: Column(
            children: [
              // Pratinjau Video
              Container(
                height: 200,
                color: Colors.black26,
                child: Center(
                  child: _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : CircularProgressIndicator(), // Menampilkan loading jika video belum siap
                ),
              ),
              SizedBox(height: 20),
              // Kontrol video
              VideoControls(controller: _controller),
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
                        leading: CircleAvatar(child: Text('🚗')),
                        title: Text('${index + 1}. Objek ${index + 1}'),
                        subtitle: Text(
                            'Detected at: 00:${(index * 10 + 5).toString().padLeft(2, '0')}'),
                      ),
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

// Widget untuk kontrol video
class VideoControls extends StatelessWidget {
  final VideoPlayerController controller;

  VideoControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
          onPressed: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        IconButton(
          icon: Icon(Icons.stop, color: Colors.white),
          onPressed: () {
            controller.pause();
            controller.seekTo(Duration.zero);
          },
        ),
      ],
    );
  }
}
