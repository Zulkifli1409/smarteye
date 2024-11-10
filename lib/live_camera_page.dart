import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LiveCameraPage extends StatefulWidget {
  @override
  _LiveCameraPageState createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<Detection> detectedObjects = [];
  Timer? _timer;
  final String apiUrl = 'http://192.168.1.5:5000/api/detect_realtime';
  bool isLoading = false;
  bool isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startDetectionTimer();
  }

  void _startDetectionTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!isLoading) {
        _fetchDetections();
      }
    });
  }

  Future<void> _fetchDetections() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      isLoading = true;
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(apiUrl),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'image.jpg',
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        if (data['detections'] != null) {
          setState(() {
            detectedObjects = (data['detections'] as List)
                .map((detection) => Detection.fromJson(detection))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching detections: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      cameras.forEach((camera) {
        print(camera.lensDirection);
      });
      final selectedCamera = isFrontCamera
          ? cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front)
          : cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back);

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _toggleCamera() {
    setState(() {
      isFrontCamera = !isFrontCamera;
    });
    _initializeCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Object Detection'),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: _toggleCamera,
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.2),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Align(
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          CameraPreview(_controller!),
                          CustomPaint(
                            painter: DetectionPainter(detectedObjects),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                      strokeWidth: 5,
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: detectedObjects.isEmpty
                  ? Center(
                      child: Text(
                        'No objects detected',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: detectedObjects.length,
                      itemBuilder: (context, index) {
                        final detection = detectedObjects[index];
                        return Card(
                          color: Colors.white.withOpacity(0.9),
                          margin: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                detection.label.substring(0, 1).toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              '${detection.label} (${(detection.confidence * 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Detected at: ${detection.timestamp}'),
                                Text(
                                  'Location: (${detection.box[0]}, ${detection.box[1]})',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class Detection {
  final String label;
  final double confidence;
  final List<int> box; // Ensure this is a list of integers
  final String timestamp;

  Detection({
    required this.label,
    required this.confidence,
    required this.box,
    required this.timestamp,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    // Convert box coordinates to integers if they are strings
    List<int> boxList = (json['box'] as List)
        .map((e) =>
            int.tryParse(e.toString()) ??
            0) // Convert to integer, defaulting to 0 if parsing fails
        .toList();

    return Detection(
      label: json['label'],
      confidence: json['confidence'].toDouble(),
      box: boxList,
      timestamp: json['timestamp'],
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<Detection> detections;

  DetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (var detection in detections) {
      final Rect rect = Rect.fromLTWH(
        detection.box[0].toDouble(),
        detection.box[1].toDouble(),
        (detection.box[2] - detection.box[0]).toDouble(),
        (detection.box[3] - detection.box[1]).toDouble(),
      );

      // Draw the bounding box
      canvas.drawRect(rect, paint);

      // Prepare the label and confidence text
      textPainter.text = TextSpan(
        text:
            '${detection.label} (${(detection.confidence * 100).toStringAsFixed(1)}%)',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      );
      textPainter.layout();

      // Position the text above the bounding box, centered horizontally
      final double textX = rect.left + (rect.width - textPainter.width) / 2;
      final double textY =
          rect.top - textPainter.height - 2; // Add a small offset for spacing
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
