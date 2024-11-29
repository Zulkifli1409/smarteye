import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'settings_page.dart';
import 'widgets/quick_access_button.dart';
import 'history.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'about.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> imgList = [
      'lib/image/image1.png',
      'lib/image/image2.jpg',
      'lib/image/image3.png',
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white, size: 30),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: IconButton(
                icon: Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'SmartEye',
                    applicationVersion: '1.0.0',
                    children: [
                      Text('Advanced AI-powered object detection application')
                    ],
                  );
                },
              ),
            ),
          ),
        ],
        title: Row(
          children: [
            Image.asset(
              'lib/image/logo.png',
              width: 40,
              height: 40,
            ),
            SizedBox(width: 10),
            Text(
              'SmartEye',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A90E2).withOpacity(0.9),
              Color(0xFF50C878).withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  SizedBox(height: 40),

                  // Enhanced Carousel
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 250,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 16 / 9,
                      viewportFraction: 0.8,
                    ),
                    items: imgList
                        .map((item) => Container(
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: AssetImage(item),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),

                  SizedBox(height: 20),

                  // New Card with transparent background and typing text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Card(
                      color: Colors.transparent, // Make the card transparent
                      elevation: 0, // Remove elevation to enhance transparency
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1), // Adjust opacity of the background color
                          borderRadius: BorderRadius.circular(15), // Maintain rounded corners
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Detection Overview',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  Icon(
                                    Icons.analytics_outlined,
                                    color: Colors.blue[700],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),

                              // Typing text effect with repeated animation
                              AnimatedTextKit(
                                animatedTexts: [
                                  TypewriterAnimatedText(
                                    'Explore advanced AI-powered object detection capabilities. '
                                    'SmartEye provides real-time, accurate insights for various scenarios.',
                                    speed: Duration(milliseconds: 100),
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                                isRepeatingAnimation: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // QuickAccessButton fixed at the bottom
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: QuickAccessButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom method to create the Drawer
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Center(
              child: Text(
                'SmartEye',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('History'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

