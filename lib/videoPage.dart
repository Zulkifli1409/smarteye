import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'db_helper.dart';
import 'detected_object.dart';

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
        Uri.parse('http://192.168.1.5:5000/api/detect_video'),
      );
      request.files.add(await http.MultipartFile.fromPath('video', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(await response.stream.bytesToString());
        final results = jsonResponse['detections'] as Map<String, dynamic>;

        setState(() {
          detections = Map.fromEntries(
            results.entries.map((e) => MapEntry(
                  double.parse(e.key),
                  List<Map<String, dynamic>>.from(e.value),
                )),
          );
          isProcessing = false;
        });

        // Save detections to database
        final dbHelper = DBHelper();
        for (var timestamp in detections.keys) {
          final detectionsAtTime = detections[timestamp]!;
          for (var detection in detectionsAtTime) {
            if (widget.selectedObjects.contains(detection['label'])) {
              final detectedObject = DetectedObject(
                label: detection['label'],
                confidence: detection['confidence'],
                boundingBox: json.encode(detection['bounding_box']),
                category: "Video", // Pastikan kategori diisi dengan benar
                date: DateTime.now().toIso8601String(),
              );
              await dbHelper.insertObject(detectedObject);
            }
          }
        }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Video Detection',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black45,
                offset: Offset(2.0, 2.0),
              )
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.visibility,
              color: showObjectCounts ? Colors.greenAccent : Colors.white,
            ),
            onPressed: () {
              setState(() {
                showObjectCounts = !showObjectCounts;
              });
            },
          ),
        ],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: _controller.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio: _controller.value.aspectRatio,
                                  child: VideoPlayer(_controller),
                                )
                              : CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                        ),
                        if (_controller.value.isInitialized)
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final currentDetections =
                                    _getCurrentDetections();
                                final videoWidth = _controller.value.size.width;
                                final videoHeight =
                                    _controller.value.size.height;

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
                                              color: Colors.greenAccent,
                                              width: 3),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Container(
                                            color: Colors.greenAccent
                                                .withOpacity(0.7),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 4),
                                            child: Text(
                                              '$label ${(confidence * 100).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                color: Colors.black,
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
                ),
              ),
              VideoControls(controller: _controller),
              Expanded(
                flex: 2,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: isProcessing
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Processing video...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      : errorMessage != null
                          ? Center(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          : ValueListenableBuilder(
                              valueListenable: _controller,
                              builder:
                                  (context, VideoPlayerValue value, child) {
                                final currentDetections =
                                    _getCurrentDetections();
                                final filteredDetections =
                                    _filterSelectedObjects(currentDetections);
                                return ListView.builder(
                                  itemCount: filteredDetections.length,
                                  itemBuilder: (context, index) {
                                    final detection = filteredDetections[index];
                                    return Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.3),
                                            Colors.white.withOpacity(0.1),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          )
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Colors.white.withOpacity(0.3),
                                          child: Text(
                                            detection['label'][0].toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          detection['label'],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Confidence: ${(detection['confidence'] * 100).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              'Time: ${value.position.inSeconds}s',
                                              style: TextStyle(
                                                color: Colors.white70,
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
                ),
              ),
              if (showObjectCounts)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
