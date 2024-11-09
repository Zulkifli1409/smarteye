import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;

class ImagePage extends StatefulWidget {
  final String filePath;

  ImagePage({required this.filePath});

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
          'POST', Uri.parse('http://192.168.0.116:5000/api/detect'));
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final jsonResponse = await response.stream.bytesToString();
        setState(() {
          detectedObjects =
              List<Map<String, dynamic>>.from(json.decode(jsonResponse));
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
        errorMessage = null; // Clear any previous error messages
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error loading image: $e"; // Set error message
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
                    ? FittedBox(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Image.file(
                                File(widget.filePath),
                                width: originalImage.width.toDouble(),
                                height: originalImage.height.toDouble(),
                              ),
                            ),
                            if (detectedObjects.isNotEmpty)
                              CustomPaint(
                                painter: BoundingBoxPainter(
                                    detectedObjects, originalImage),
                                child: Container(
                                  width: originalImage.width.toDouble(),
                                  height: originalImage.height.toDouble(),
                                ),
                              ),
                          ],
                        ),
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
                              child: Text(object['label'][0].toUpperCase(),
                                  style: TextStyle(color: Colors.white)),
                            ),
                            title: Text(
                              '${object['label']} (${(object['confidence'] * 100).toStringAsFixed(2)}%)',
                              style: TextStyle(color: Colors.black),
                            ),
                            subtitle: Text(
                                'Bounding Box: ${object['bounding_box']}',
                                style: TextStyle(color: Colors.black54)),
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

class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> objects;
  final ui.Image originalImage;

  BoundingBoxPainter(this.objects, this.originalImage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30;

    // Text style with larger font size and white color
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize:80, // Adjusted size for better fit
      fontWeight: FontWeight.bold,
    );

    for (var object in objects) {
      final boundingBox = object['bounding_box'];
      final label = object['label'];

      // Adjust bounding box according to the aspect ratio
      final left = boundingBox[0].toDouble();
      final top = boundingBox[1].toDouble();
      final width = boundingBox[2].toDouble();
      final height = boundingBox[3].toDouble();

      // Draw the bounding box
      canvas.drawRect(Rect.fromLTWH(left, top, width, height), paint);

      // Create a background for the label
      final labelBackgroundPaint = Paint()
        ..color = Colors.black.withOpacity(0.7);
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelOffset = Offset(left, top - textPainter.height - 4);
      canvas.drawRect(
        Rect.fromLTWH(labelOffset.dx, labelOffset.dy, textPainter.width + 4,
            textPainter.height + 4),
        labelBackgroundPaint,
      );

      // Draw the label text
      textPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
