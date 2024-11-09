import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class VideoPage extends StatefulWidget {
  final String filePath;

  VideoPage({required this.filePath});

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _controller;
  Map<double, List<Map<String, dynamic>>> detections = {};
  bool isProcessing = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {});
        _detectObjects();
        _controller.addListener(
            _updateBoundingBoxes); // Menambahkan listener untuk setiap frame
      });
  }

  void _updateBoundingBoxes() {
    setState(() {}); // Memaksa tampilan untuk di-update setiap frame
  }

  Future<void> _detectObjects() async {
    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception("Video file does not exist");
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.116:5000/api/detect_video'),
      );
      request.files.add(await http.MultipartFile.fromPath('video', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(await response.stream.bytesToString());

        setState(() {
          final results = jsonResponse['detections'] as Map<String, dynamic>;
          detections = Map.fromEntries(
            results.entries.map((e) => MapEntry(
                  double.parse(e.key),
                  List<Map<String, dynamic>>.from(e.value),
                )),
          );
          isProcessing = false;
        });
      } else {
        throw Exception("Failed to process video: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isProcessing = false;
      });
      print("Error during video detection: $e");
    }
  }

  List<Map<String, dynamic>> _getCurrentDetections() {
    if (detections.isEmpty || !_controller.value.isInitialized) return [];

    final currentTime = _controller.value.position.inMilliseconds / 1000.0;
    final closestTimestamp = detections.keys.reduce(
        (a, b) => (a - currentTime).abs() < (b - currentTime).abs() ? a : b);

    return detections[closestTimestamp] ?? [];
  }

  @override
  void dispose() {
    _controller.removeListener(_updateBoundingBoxes);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Deteksi Video')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 80.0),
          child: Column(
            children: [
              Container(
                height: 200,
                color: Colors.black26,
                child: Stack(
                  children: [
                    Center(
                      child: _controller.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            )
                          : CircularProgressIndicator(),
                    ),
                    if (_controller.value.isInitialized)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final currentDetections = _getCurrentDetections();
                            final videoWidth = _controller.value.size.width;
                            final videoHeight = _controller.value.size.height;

                            return Stack(
                              children: currentDetections.map((detection) {
                                final box = detection['bounding_box'];
                                final label = detection['label'];
                                final confidence = detection['confidence'];

                                // Menghitung posisi dan ukuran bounding box berdasarkan ukuran video dan tampilan saat ini
                                final left = (box[0] / videoWidth) *
                                    constraints.maxWidth;
                                final top = (box[1] / videoHeight) *
                                    constraints.maxHeight;
                                final width = (box[2] / videoWidth) *
                                    constraints.maxWidth;
                                final height = (box[3] / videoHeight) *
                                    constraints.maxHeight;

                                return Positioned(
                                  left: left,
                                  top: top,
                                  width: width,
                                  height: height,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.red, width: 2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Container(
                                        color: Colors.red,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        child: Text(
                                          '$label ${(confidence * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              VideoControls(controller: _controller),
              SizedBox(height: 20),
              if (isProcessing)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Processing video...',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              else if (errorMessage != null)
                Text(errorMessage!, style: TextStyle(color: Colors.red))
              else
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) {
                      final currentDetections = _getCurrentDetections();
                      return ListView.builder(
                        itemCount: currentDetections.length,
                        itemBuilder: (context, index) {
                          final detection = currentDetections[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child:
                                    Text(detection['label'][0].toUpperCase()),
                                backgroundColor: Colors.blue,
                              ),
                              title: Text('${detection['label']}'),
                              subtitle: Text(
                                  'Confidence: ${(detection['confidence'] * 100).toStringAsFixed(1)}%\n'
                                  'Time: ${value.position.inSeconds}s'),
                            ),
                          );
                        },
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
