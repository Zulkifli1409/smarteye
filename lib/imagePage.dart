import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'db_helper.dart';
import 'detected_object.dart';

class ImagePage extends StatefulWidget {
  final String filePath;
  final List<String> selectedObjects;

  ImagePage({required this.filePath, required this.selectedObjects});

  @override
  _ImagePageState createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  List<Map<String, dynamic>> detectedObjects = [];
  late ui.Image originalImage;
  bool isImageLoaded = false;
  String? errorMessage;

  Future<void> _detectObjects() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        print("File does not exist at path: ${widget.filePath}");
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.5:5000/api/detect_image'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final jsonResponse = await response.stream.bytesToString();
        final data = json.decode(jsonResponse) as Map<String, dynamic>;
        final objects =
            List<Map<String, dynamic>>.from(data['detected_objects'] ?? []);

        setState(() {
          detectedObjects = objects.where((object) {
            final label = object['label'] ?? '';
            return widget.selectedObjects.contains(label);
          }).toList();
        });

        // Simpan hasil deteksi ke database
        final dbHelper = DBHelper();
        for (var object in detectedObjects) {
          final label = object['label'] ?? 'Unknown';
          final confidence = (object['confidence'] as num?)?.toDouble() ?? 0.0;
          final boundingBox = json.encode(object['box'] ?? []);
          final date = DateTime.now().toIso8601String();

          final detectedObject = DetectedObject(
            label: label,
            confidence: confidence,
            boundingBox: boundingBox,
            category: "Image", // Pastikan kategori diisi dengan benar
            date: date,
          );

          await dbHelper.insertObject(detectedObject);
        }
      } else {
        print("Error detecting objects: ${response.statusCode}");
      }
    } catch (e) {
      print("Error during object detection: $e");
    }
  }



  Future<void> _loadOriginalImage() async {
    try {
      final data = await File(widget.filePath).readAsBytes();
      final image = await decodeImageFromList(data);
      setState(() {
        originalImage = image;
        isImageLoaded = true;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error loading image: $e";
      });
      print("Error loading image: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOriginalImage();
    _detectObjects();
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
          'Object Detection',
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
                    child: isImageLoaded
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final containerWidth = constraints.maxWidth;
                              final containerHeight = constraints.maxHeight;

                              final scaleX = containerWidth / originalImage.width;
                              final scaleY = containerHeight / originalImage.height;

                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(widget.filePath),
                                    width: originalImage.width * scaleX,
                                    height: originalImage.height * scaleY,
                                    fit: BoxFit.contain,
                                  ),
                                  if (detectedObjects.isNotEmpty)
                                    CustomPaint(
                                      painter: BoundingBoxPainter(
                                        detectedObjects,
                                        scaleX,
                                        scaleY,
                                        Size(
                                          originalImage.width.toDouble(),
                                          originalImage.height.toDouble(),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          )
                        : Center(
                            child: errorMessage != null
                                ? Text(
                                    errorMessage!,
                                    style: TextStyle(color: Colors.white),
                                  )
                                : CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Detected Objects",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: detectedObjects.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: detectedObjects.length,
                        itemBuilder: (context, index) {
                          final object = detectedObjects[index];
                          final label = object['label'] ?? 'Unknown';
                          final confidence = object['confidence'] ?? 0.0;
                          final boundingBox = object['box'] ?? {};

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
                                backgroundColor: Colors.white.withOpacity(0.3),
                                child: Text(
                                  label.isNotEmpty ? label[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '(${(confidence * 100).toStringAsFixed(2)}%)',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Bounding Box: $boundingBox',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Map<String, int> objectCounts = {};

                    for (var object in detectedObjects) {
                      final label = object['label'] ?? 'Unknown';
                      objectCounts[label] = (objectCounts[label] ?? 0) + 1;
                    }

                    String countMessage = objectCounts.entries
                        .map((entry) => '${entry.value} ${entry.key}')
                        .join(', ');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Total objects detected: $countMessage'),
                        backgroundColor: Colors.blue.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.calculate_outlined),
                  label: Text('Count Objects'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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

class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> objects;
  final double scaleX;
  final double scaleY;
  final Size imageSize;

  BoundingBoxPainter(this.objects, this.scaleX, this.scaleY, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var object in objects) {
      final box = object['box'];
      if (box != null) {
        final left = (box[0] * scaleX).clamp(0.0, imageSize.width);
        final top = (box[1] * scaleY).clamp(0.0, imageSize.height);
        final right = (box[2] * scaleX).clamp(left, imageSize.width);
        final bottom = (box[3] * scaleY).clamp(top, imageSize.height);

        final rect = Rect.fromLTRB(left, top, right, bottom);
        canvas.drawRect(rect, paint);

        final label = object['label'] ?? 'Unknown';
        final confidence = object['confidence'] ?? 0.0;

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$label ${(confidence * 100).toStringAsFixed(2)}%',
            style:
                TextStyle(color: Colors.black, backgroundColor: Colors.white),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(left, top));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
