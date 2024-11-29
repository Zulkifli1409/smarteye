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

  @override
  void initState() {
    super.initState();
    _loadOriginalImage();
    _detectObjects();
  }

  Future<void> _detectObjects() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) return;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.5:5000/api/detect_image'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final data = json.decode(await response.stream.bytesToString());
        final objects =
            List<Map<String, dynamic>>.from(data['detected_objects'] ?? []);

        setState(() {
          detectedObjects = objects.where((object) {
            return widget.selectedObjects.contains(object['label'] ?? '');
          }).toList();
        });

        final dbHelper = DBHelper();
        for (var object in detectedObjects) {
          await dbHelper.insertObject(DetectedObject(
            label: object['label'] ?? 'Unknown',
            confidence: (object['confidence'] as num?)?.toDouble() ?? 0.0,
            boundingBox: json.encode(object['box'] ?? []),
            category: "Image",
            date: DateTime.now().toIso8601String(),
          ));
        }
      }
    } catch (e) {
      print("Error during object detection: $e");
    }
  }

  Future<void> _loadOriginalImage() async {
    try {
      final image =
          await decodeImageFromList(await File(widget.filePath).readAsBytes());
      setState(() {
        originalImage = image;
        isImageLoaded = true;
        errorMessage = null;
      });
    } catch (e) {
      setState(() => errorMessage = "Error loading image: $e");
    }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Object Detection',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.black38,
                offset: Offset(0, 2),
              ),
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
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: isImageLoaded
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final scaleX =
                                  constraints.maxWidth / originalImage.width;
                              final scaleY =
                                  constraints.maxHeight / originalImage.height;
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(widget.filePath),
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
                                ? Text(errorMessage!,
                                    style: TextStyle(color: Colors.white))
                                : CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white)),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "Detected Objects",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(0, 2),
                      ),
                    ],
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
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: detectedObjects.length,
                        itemBuilder: (context, index) {
                          final object = detectedObjects[index];
                          final label = object['label'] ?? 'Unknown';
                          final confidence = object['confidence'] ?? 0.0;

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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1A237E).withOpacity(0.3),
                                ),
                                child: Center(
                                  child: Text(
                                    label.isNotEmpty
                                        ? label[0].toUpperCase()
                                        : '?',
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
                                    label,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(confidence * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Map<String, int> counts = {};
                    for (var obj in detectedObjects) {
                      final label = obj['label'] ?? 'Unknown';
                      counts[label] = (counts[label] ?? 0) + 1;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Detected: ${counts.entries.map((e) => '${e.value} ${e.key}').join(', ')}',
                          style: TextStyle(fontSize: 16),
                        ),
                        backgroundColor: Color(0xFF1A237E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: EdgeInsets.all(16),
                      ),
                    );
                  },
                  icon: Icon(Icons.analytics_outlined),
                  label: Text(
                    'Count Objects',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
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
    final boxPaint = Paint()
      ..color = Color(0xFF1A237E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final labelPaint = Paint()
      ..color = Color(0xFF1A237E).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (var object in objects) {
      final box = object['box'];
      if (box != null) {
        final left = (box[0] * scaleX).clamp(0.0, size.width);
        final top = (box[1] * scaleY).clamp(0.0, size.height);
        final right = (box[2] * scaleX).clamp(left, size.width);
        final bottom = (box[3] * scaleY).clamp(top, size.height);

        final rect = Rect.fromLTRB(left, top, right, bottom);
        canvas.drawRect(rect, boxPaint);

        final label = object['label'] ?? 'Unknown';
        final confidence = object['confidence'] ?? 0.0;
        final labelText = '$label ${(confidence * 100).toStringAsFixed(1)}%';

        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              backgroundColor: Color(0xFF1A237E).withOpacity(0.7),
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        final labelRect = Rect.fromLTWH(
          left,
          top - 24,
          textPainter.width + 8,
          24,
        );

        canvas.drawRect(labelRect, labelPaint);
        textPainter.paint(canvas, Offset(left + 4, top - 24));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
