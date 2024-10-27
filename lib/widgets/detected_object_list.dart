import 'package:flutter/material.dart';

class DetectedObjectList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // Ganti dengan jumlah objek terdeteksi
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Objek Terdeteksi $index'),
          subtitle: Text('Detail objek...'),
        );
      },
    );
  }
}
