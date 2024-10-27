import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smarteye/live_camera_page.dart';
import 'package:smarteye/videoPage.dart';
import 'package:smarteye/imagePage.dart'; 

class QuickAccessButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(context, Icons.camera_alt, 'Live Camera', Colors.blue,
            LiveCameraPage()),
        SizedBox(height: 16.0), // Jarak antara tombol
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildButtonWithFilePicker(context, Icons.video_camera_back,
                'Video', Colors.green, 'video'),
            _buildButtonWithFilePicker(
                context, Icons.image, 'Gambar', Colors.orange, 'image'),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, IconData icon, String label,
      Color color, Widget targetPage) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 5,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      icon: Icon(icon, color: Colors.white, size: 24),
      label: Text(
        label,
        style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildButtonWithFilePicker(BuildContext context, IconData icon,
      String label, Color color, String fileType) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 5,
      ),
      onPressed: () async {
        try {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: fileType == 'video' ? FileType.video : FileType.image,
          );

          if (result != null && result.files.isNotEmpty) {
            String filePath = result.files.single.path ?? '';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => fileType == 'video'
                    ? VideoPage(filePath: filePath)
                    : ImagePage(filePath: filePath),
              ),
            );
          } else {
            // File picking was canceled by user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File selection was canceled')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error selecting file: $e')),
          );
        }
      },
      icon: Icon(icon, color: Colors.white, size: 24),
      label: Text(
        label,
        style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
