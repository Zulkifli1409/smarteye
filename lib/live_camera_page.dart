import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class LiveCameraPage extends StatefulWidget {
  @override
  _LiveCameraPageState createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  // List untuk menyimpan objek yang terdeteksi
  List<String> detectedObjects = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    // Mulai logika deteksi objek
    startObjectDetection();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller!.initialize();
  }

  Future<void> startObjectDetection() async {
    // Tambahkan logika deteksi objek di sini
    // Simulasi deteksi objek
    await Future.delayed(Duration(seconds: 3)); // Simulasi waktu deteksi
    setState(() {
      detectedObjects.add('Objek 1');
      detectedObjects.add('Objek 2');
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kamera Langsung')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'), // Pastikan path ini benar
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Column(
                children: [
                  // Menampilkan tampilan kamera dengan padding
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 5.0), // Padding tambahan
                    child: Container(
                      height: MediaQuery.of(context).size.height *
                          0.5, // Mengurangi tinggi
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  ),
                  // ListView untuk objek yang terdeteksi
                  Expanded(
                    child: ListView.builder(
                      itemCount: detectedObjects.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('🍎'), // Menggunakan icon
                            ),
                            title:
                                Text('${index + 1}. ${detectedObjects[index]}'),
                            subtitle: Text(
                              'Detected at: 10:${(index * 5 + 5).toString().padLeft(2, '0')} AM', // Format waktu
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
