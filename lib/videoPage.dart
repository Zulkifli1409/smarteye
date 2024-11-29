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

  void _updateBoundingBoxes() => setState(() {});

  Future<void> _detectObjects() async {
    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) throw Exception("Video file does not exist");

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://smarteye.zulkifli.xyz/api/detect_video'),
      );
      request.files.add(await http.MultipartFile.fromPath('video', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final results =
            json.decode(await response.stream.bytesToString())['detections'];

        setState(() {
          detections = Map.fromEntries(
            (results as Map<String, dynamic>).entries.map((e) => MapEntry(
                  double.parse(e.key),
                  List<Map<String, dynamic>>.from(e.value),
                )),
          );
          isProcessing = false;
        });

        final dbHelper = DBHelper();
        for (var entry in detections.entries) {
          for (var detection in entry.value
              .where((d) => widget.selectedObjects.contains(d['label']))) {
            await dbHelper.insertObject(DetectedObject(
              label: detection['label'],
              confidence: detection['confidence'],
              boundingBox: json.encode(detection['bounding_box']),
              category: "Video",
              date: DateTime.now().toIso8601String(),
            ));
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
    }
  }

  List<Map<String, dynamic>> _getCurrentDetections() {
    if (!_controller.value.isInitialized || detections.isEmpty) return [];
    final currentTime = _controller.value.position.inMilliseconds / 1000.0;
    return detections[detections.keys.reduce((a, b) =>
            (a - currentTime).abs() < (b - currentTime).abs() ? a : b)] ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Video Detection',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 8,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.analytics_outlined,
              color: showObjectCounts ? Color(0xFF0288D1) : Colors.white,
            ),
            onPressed: () =>
                setState(() => showObjectCounts = !showObjectCounts),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
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
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildVideoPlayer(),
                        if (_controller.value.isInitialized)
                          _buildDetectionOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildVideoControls(),
              Expanded(
                flex: 2,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: isProcessing
                      ? _buildLoadingIndicator()
                      : errorMessage != null
                          ? _buildErrorMessage()
                          : _buildDetectionsList(),
                ),
              ),
              if (showObjectCounts) _buildObjectCounter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
    );
  }

  Widget _buildDetectionOverlay() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, value, child) {
        final currentDetections = _getCurrentDetections()
            .where(
              (d) => widget.selectedObjects.contains(d['label']),
            )
            .toList();

        return CustomPaint(
          painter: DetectionPainter(
            detections: currentDetections,
            videoSize: _controller.value.size,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildVideoControls() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, child) {
              return IconButton(
                icon: Icon(
                  value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  value.isPlaying ? _controller.pause() : _controller.play();
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.replay, color: Colors.white, size: 32),
            onPressed: () {
              _controller.seekTo(Duration.zero);
              _controller.pause();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Processing video...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Text(
        errorMessage!,
        style: TextStyle(color: Colors.redAccent, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDetectionsList() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, value, child) {
        final currentDetections = _getCurrentDetections()
            .where((d) => widget.selectedObjects.contains(d['label']))
            .toList();

        return ListView.builder(
          itemCount: currentDetections.length,
          padding: EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final detection = currentDetections[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1A237E).withOpacity(0.3),
                  ),
                  child: Center(
                    child: Text(
                      detection['label'][0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      detection['label'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(detection['confidence'] * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Time: ${value.position.inSeconds}s',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildObjectCounter() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E).withOpacity(0.9),
            Color(0xFF0288D1).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, child) {
          Map<String, int> objectCounts = {};
          final currentDetections = _getCurrentDetections()
              .where((d) => widget.selectedObjects.contains(d['label']));

          for (var detection in currentDetections) {
            final label = detection['label'] as String;
            objectCounts[label] = (objectCounts[label] ?? 0) + 1;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Objects Detected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              if (objectCounts.isEmpty)
                Text(
                  'No objects detected',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: objectCounts.entries.map((entry) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_updateBoundingBoxes);
    _controller.dispose();
    super.dispose();
  }
}

class DetectionPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Size videoSize;

  DetectionPainter({required this.detections, required this.videoSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF1A237E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final labelPaint = Paint()
      ..color = Color(0xFF1A237E).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (var detection in detections) {
      final box = detection['bounding_box'];
      final scaleX = size.width / videoSize.width;
      final scaleY = size.height / videoSize.height;

      final rect = Rect.fromLTWH(
        box[0] * scaleX,
        box[1] * scaleY,
        box[2] * scaleX,
        box[3] * scaleY,
      );

      canvas.drawRect(rect, paint);

      final label = detection['label'];
      final confidence = detection['confidence'];
      final labelText = '$label ${(confidence * 100).toStringAsFixed(1)}%';

      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - 24,
        textPainter.width + 8,
        24,
      );

      canvas.drawRect(labelRect, labelPaint);
      textPainter.paint(canvas, Offset(rect.left + 4, rect.top - 24));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
