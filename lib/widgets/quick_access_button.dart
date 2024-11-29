import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smarteye/live_camera_page.dart';
import 'package:smarteye/videoPage.dart';
import 'package:smarteye/imagePage.dart';
import 'package:smarteye/settings_page.dart';

class QuickAccessButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          _buildButton(
            context,
            Icons.camera_alt,
            'Live Camera',
            'Mulai deteksi objek secara real-time',
            LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            LiveCameraPage(selectedObjects: []),
          ),
          SizedBox(height: 12),
          _buildButtonWithFilePicker(
            context,
            Icons.video_camera_back,
            'Video Detection',
            'Deteksi objek dari file video',
            LinearGradient(
              colors: [Colors.green[400]!, Colors.green[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            'video',
          ),
          SizedBox(height: 12),
          _buildButtonWithFilePicker(
            context,
            Icons.image,
            'Image Detection',
            'Deteksi objek dari file gambar',
            LinearGradient(
              colors: [Colors.orange[400]!, Colors.orange[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            'image',
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, IconData icon, String label,
      String description, Gradient gradient, Widget targetPage) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            List<String> selectedObjects = await _getSelectedObjects(context);
            if (selectedObjects.isEmpty) {
              selectedObjects = await _getAllObjects();
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LiveCameraPage(selectedObjects: selectedObjects),
              ),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonWithFilePicker(BuildContext context, IconData icon,
      String label, String description, Gradient gradient, String fileType) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: fileType == 'video' ? FileType.video : FileType.image,
              );

              if (result != null && result.files.isNotEmpty) {
                String filePath = result.files.single.path ?? '';
                List<String> selectedObjects =
                    await _getSelectedObjects(context);

                if (selectedObjects.isEmpty) {
                  selectedObjects = await _getAllObjects();
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => fileType == 'video'
                        ? VideoPage(
                            filePath: filePath,
                            selectedObjects: selectedObjects)
                        : ImagePage(
                            filePath: filePath,
                            selectedObjects: selectedObjects),
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error selecting file: $e')),
              );
            }
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Rest of the code remains the same
  Future<List<String>> _getSelectedObjects(BuildContext context) async {
    final selectedObjects = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
    return selectedObjects ?? [];
  }

  Future<List<String>> _getAllObjects() async {
    return [
      'person',
      'bicycle',
      'car',
      'motorcycle',
      'airplane',
      'bus',
      'train',
      'truck',
      'boat',
      'traffic light',
      'fire hydrant',
      'stop sign',
      'parking meter',
      'bench',
      'bird',
      'cat',
      'dog',
      'horse',
      'sheep',
      'cow',
      'elephant',
      'bear',
      'zebra',
      'giraffe',
      'backpack',
      'umbrella',
      'handbag',
      'tie',
      'suitcase',
      'frisbee',
      'skis',
      'snowboard',
      'sports ball',
      'kite',
      'baseball bat',
      'baseball glove',
      'skateboard',
      'surfboard',
      'tennis racket',
      'bottle',
      'wine glass',
      'cup',
      'fork',
      'knife',
      'spoon',
      'bowl',
      'banana',
      'apple',
      'sandwich',
      'orange',
      'broccoli',
      'carrot',
      'hot dog',
      'pizza',
      'donut',
      'cake',
      'chair',
      'couch',
      'potted plant',
      'bed',
      'dining table',
      'toilet',
      'tv',
      'laptop',
      'mouse',
      'remote',
      'keyboard',
      'cell phone',
      'microwave',
      'oven',
      'toaster',
      'sink',
      'refrigerator',
      'book',
      'clock',
      'vase',
      'scissors',
      'teddy bear',
      'hair drier',
      'toothbrush'
    ];
  }
}
