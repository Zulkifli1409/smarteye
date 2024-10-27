import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Define fading animation for the image
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Define scaling animation for the image
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);

    // Define fading animation for the text
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 1.0), // Text fades in after half the duration
      ),
    );

    // Start the animations
    _controller.forward();

    // Navigate to the next screen after delay
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 255, 255, 255), // Background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation, // Fade effect for the image
              child: ScaleTransition(
                scale: _scaleAnimation, // Scale effect for the image
                child: Image.asset(
                  'lib/image/logo.png', // Replace with your image path
                  width: 200, // Set image width
                  height: 200, // Set image height
                ),
              ),
            ),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _textFadeAnimation, // Fade effect for the text
              child: Text(
                'SmartEye',
                style: TextStyle(
                  fontFamily: 'Roboto', // Use the Roboto font here
                  fontSize: 24,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
