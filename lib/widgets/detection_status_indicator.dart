import 'package:flutter/material.dart';

class DetectionStatusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Status Deteksi: Aktif',
      style: TextStyle(fontSize: 20, color: Colors.green),
    );
  }
}
