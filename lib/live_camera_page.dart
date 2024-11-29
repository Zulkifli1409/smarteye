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
  final String apiUrl = 'http://192.168.1.5:5000/api/detect_realtime';
  bool isLoading = false;
  bool isFrontCamera = false;
  bool isFlashOn = false;
  double zoomLevel = 1.0;
  Timer? _countTimer;

  final Color primaryColor = Color(0xFF1A237E);
  final Color secondaryColor = Color(0xFF0288D1);

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

  bool isFloatingVisible = false; // Status apakah teks floating sedang aktif
  OverlayEntry? overlayEntry; // Referensi ke OverlayEntry

  void _countObjects() {
    if (isFloatingVisible) {
      // Cancel the count timer when hiding overlay
      _countTimer?.cancel();
      _countTimer = null;
      overlayEntry?.remove();
      overlayEntry = null;
      isFloatingVisible = false;
    } else {
      // Create and show the overlay
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).size.height * 0.2,
          left: MediaQuery.of(context).size.width * 0.1,
          right: MediaQuery.of(context).size.width * 0.1,
          child: Material(
            color: Colors.transparent,
            child: ValueListenableBuilder<Map<String, int>>(
              valueListenable: _objectCountNotifier,
              builder: (context, counts, child) {
                String countMessage = counts.entries
                    .map((entry) => '${entry.value} ${entry.key}')
                    .join(', ');

                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Detected Objects',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        countMessage.isEmpty
                            ? 'No objects detected'
                            : countMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Add the overlay and start realtime counting
      Overlay.of(context)?.insert(overlayEntry!);
      isFloatingVisible = true;
      _startRealtimeCounting();
    }
  }

  // Add these new variables and methods
  final ValueNotifier<Map<String, int>> _objectCountNotifier =
      ValueNotifier<Map<String, int>>({});

  void _startRealtimeCounting() {
    // Update counts immediately
    _updateCounts();

    // Start periodic updates
    _countTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _updateCounts();
    });
  }

  void _updateCounts() {
    Map<String, int> objectCounts = {};

    for (var detection in detectedObjects) {
      final label = detection.label;
      objectCounts[label] = (objectCounts[label] ?? 0) + 1;
    }

    _objectCountNotifier.value = objectCounts;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countTimer?.cancel();
    _controller?.dispose();
    overlayEntry?.remove();
    _objectCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Live Object Detection',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        actions: [
          _buildActionButton(Icons.switch_camera, _toggleCamera),
          _buildActionButton(
              isFlashOn ? Icons.flash_on : Icons.flash_off, _toggleFlash),
          _buildActionButton(Icons.calculate, _countObjects),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, secondaryColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCameraPreview(),
              _buildZoomControls(),
              Expanded(
                child: _buildDetectionsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: AspectRatio(
          aspectRatio: 3 / 4, // Adjusted to match screenshot
          child: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: isFrontCamera
                          ? Matrix4.rotationY(3.14159)
                          : Matrix4.identity(),
                      child: CameraPreview(_controller!),
                    ),
                    CustomPaint(
                      painter: DetectionPainter(detectedObjects),
                    ),
                  ],
                );
              }
              return Container(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      margin: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.remove_circle_outline,
                color: Colors.white, size: 28),
            onPressed: _zoomOut,
          ),
          SizedBox(width: 8),
          Text(
            '${zoomLevel.toStringAsFixed(1)}x',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
            onPressed: _zoomIn,
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionsList() {
    if (detectedObjects.isEmpty) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryColor.withOpacity(0.8), secondaryColor],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: Colors.white.withOpacity(0.7),
                ),
                SizedBox(height: 16),
                Text(
                  'No objects detected',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: EdgeInsets.only(top: 8),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: detectedObjects.length,
          itemBuilder: (context, index) {
            final detection = detectedObjects[index];
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      detection.label.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  detection.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
