import 'package:flutter/material.dart';
import 'package:smarteye/splash_screen.dart';

void main() {
  runApp(DeteksiObjekApp());
}

class DeteksiObjekApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartEye',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
    );
  }
}