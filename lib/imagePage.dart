import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
          'POST', Uri.parse('https://smarteye.zulkifli.xyz/api/detect_image'));
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
      appBar: AppBar(title: Text('Deteksi Gambar')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: isImageLoaded
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final containerWidth = constraints.maxWidth;
                          final containerHeight = constraints.maxHeight;

                          final scaleX = containerWidth / originalImage.width;
                          final scaleY = containerHeight / originalImage.height;

                          return Stack(
                            alignment: Alignment.center,
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
                                  size: Size(
                                    originalImage.width * scaleX,
                                    originalImage.height * scaleY,
                                  ),
                                ),
                            ],
                          );
                        },
                      )
                    : errorMessage != null
                        ? Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red),
                          )
                        : Center(child: CircularProgressIndicator()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Objek yang di Deteksi",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            detectedObjects.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: detectedObjects.length,
                      itemBuilder: (context, index) {
                        final object = detectedObjects[index];
                        final label = object['label'] ?? 'Unknown';
                        final confidence = object['confidence'] ?? 0.0;
                        final boundingBox = object['box'] ?? {};

                        return Card(
                          elevation: 5,
                          margin:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[400],
                              child: Text(
                                label.isNotEmpty ? label[0].toUpperCase() : '?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  '$label',
                                  style: TextStyle(color: Colors.black),
                                ),
                                SizedBox(
                                    width:
                                        8), // Add some space between label and confidence
                                Text(
                                  '(${(confidence * 100).toStringAsFixed(2)}%)',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Bounding Box: $boundingBox',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Map<String, int> objectCounts = {};

                  for (var object in detectedObjects) {
                    final label = object['label'] ?? 'Unknown';
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
                },
                child: Text('Hitung Objek'),
              ),
            ),
          ],
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
