import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LiveCameraPage extends StatefulWidget {
  final List<String> selectedObjects;

  LiveCameraPage({required this.selectedObjects});

  @override
  _LiveCameraPageState createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<Detection> detectedObjects = [];
  Timer? _timer;
  final String apiUrl = 'https://smarteye.zulkifli.xyz/api/detect_realtime';
  bool isLoading = false;
  bool isFrontCamera = false;
  bool isFlashOn = false;
  double zoomLevel = 1.0;

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
                .where((detection) =>
                    widget.selectedObjects.contains(detection.label))
                .toList(); // Filter hasil deteksi berdasarkan selectedObjects
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

  void _toggleFlash() {
    setState(() {
      isFlashOn = !isFlashOn;
      _controller!.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  void _zoomIn() {
    if (_controller != null) {
      setState(() {
        zoomLevel = (zoomLevel + 0.1).clamp(1.0, 4.0);
        _controller!.setZoomLevel(zoomLevel);
      });
    }
  }

  void _zoomOut() {
    if (_controller != null) {
      setState(() {
        zoomLevel = (zoomLevel - 0.1).clamp(1.0, 4.0);
        _controller!.setZoomLevel(zoomLevel);
      });
    }
  }

  void _countObjects() {
    Map<String, int> objectCounts = {};

    for (var detection in detectedObjects) {
      final label = detection.label;
      if (objectCounts.containsKey(label)) {
        objectCounts[label] = objectCounts[label]! + 1;
      } else {
        objectCounts[label] = 1;
      }
    }

    String countMessage = objectCounts.entries
        .map((entry) => '${entry.value} ${entry.key}')
        .join(', ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Total objek terdeteksi: $countMessage'),
      ),
    );
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
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: Icon(Icons.calculate),
            onPressed: _countObjects,
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
                          Transform(
                            alignment: Alignment.center,
                            transform: isFrontCamera
                                ? Matrix4.rotationY(
                                    3.14159) // Membalikkan tampilan horizontal (flip kanan)
                                : Matrix4
                                    .identity(), // Tidak ada transformasi untuk kamera belakang
                            child: CameraPreview(_controller!),
                          ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.zoom_out),
                  onPressed: _zoomOut,
                ),
                Text(
                  'Zoom: ${zoomLevel.toStringAsFixed(1)}x',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.zoom_in),
                  onPressed: _zoomIn,
                ),
              ],
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
  final List<int> box;
  final String timestamp;

  Detection({
    required this.label,
    required this.confidence,
    required this.box,
    required this.timestamp,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    List<int> boxList = (json['box'] as List)
        .map((e) => int.tryParse(e.toString()) ?? 0)
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
      final rect = Rect.fromLTRB(
        detection.box[0].toDouble(),
        detection.box[1].toDouble(),
        detection.box[0].toDouble() + detection.box[2].toDouble(),
        detection.box[1].toDouble() + detection.box[3].toDouble(),
      );
      canvas.drawRect(rect, paint);

      final text = TextSpan(
        text:
            '${detection.label} (${(detection.confidence * 100).toStringAsFixed(1)}%)',
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      );
      textPainter.text = text;
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 15));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
