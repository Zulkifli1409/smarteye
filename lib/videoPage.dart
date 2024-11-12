import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  final String filePath;
  final List<String> selectedObjects;

  VideoPage({required this.filePath, required this.selectedObjects});

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _controller;
  Map<double, List<Map<String, dynamic>>> detections = {};
  bool isProcessing = false;
  String? errorMessage;
  bool showObjectCounts = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {});
        _detectObjects();
        _controller.addListener(_updateBoundingBoxes);
      });
  }

  void _updateBoundingBoxes() {
    setState(() {});
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
        Uri.parse('https://smarteye.zulkifli.xyz/api/detect_video'),
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

  List<Map<String, dynamic>> _filterSelectedObjects(
      List<Map<String, dynamic>> detections) {
    return detections.where((detection) {
      final label = detection['label'];
      return widget.selectedObjects.contains(label);
    }).toList();
  }

  Map<String, int> _getCurrentObjectCounts() {
    if (detections.isEmpty || !_controller.value.isInitialized) return {};

    final currentTime = _controller.value.position.inMilliseconds / 1000.0;
    final closestTimestamp = detections.keys.reduce(
        (a, b) => (a - currentTime).abs() < (b - currentTime).abs() ? a : b);

    final currentDetections = detections[closestTimestamp] ?? [];
    final objectCounts = <String, int>{};
    for (final detection in currentDetections) {
      final label = detection['label'];
      objectCounts[label] = (objectCounts[label] ?? 0) + 1;
    }
    return objectCounts;
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
      appBar: AppBar(
        title: Text('Deteksi Video'),
        actions: [
          IconButton(
            icon: Icon(Icons.visibility),
            onPressed: () {
              setState(() {
                showObjectCounts = !showObjectCounts;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Column(
            children: [
              Container(
                height: 300,
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

                            final filteredDetections =
                                _filterSelectedObjects(currentDetections);

                            return Stack(
                              children: filteredDetections.map((detection) {
                                final box = detection['bounding_box'];
                                final label = detection['label'];
                                final confidence = detection['confidence'];

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
                                          color: Colors.green, width: 3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Container(
                                        color: Colors.green.withOpacity(0.7),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 4),
                                        child: Text(
                                          '$label ${(confidence * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
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
                      final filteredDetections =
                          _filterSelectedObjects(currentDetections);
                      return ListView.builder(
                        itemCount: filteredDetections.length,
                        itemBuilder: (context, index) {
                          final detection = filteredDetections[index];
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Confidence: ${(detection['confidence'] * 100).toStringAsFixed(1)}%',
                                  ),
                                  Text(
                                    'Time: ${value.position.inSeconds}s',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              // Floating count text
              if (showObjectCounts)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.6),
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        'Object Count: ${_getCurrentObjectCounts().values.fold(0, (sum, count) => sum + count)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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

class VideoControls extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.play_arrow),
          onPressed: () {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.stop),
          onPressed: () {
            controller.seekTo(Duration.zero);
            controller.pause();
          },
        ),
      ],
    );
  }
}
