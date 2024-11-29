import 'package:flutter/material.dart';
import 'dart:async';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  int _currentPage = 0;
  double _scrollOffset = 0;

  final List<TeamMember> _teamMembers = [
    TeamMember('Zulkifli', 'Ketua', 'lib/image/zoel.jpg'),
    TeamMember('Muhammad Alfata', 'Anggota', 'lib/image/ata.jpg'),
    TeamMember('Muhammad Rasyid Wanandi', 'Anggota', 'lib/image/sid.jpg'),
    TeamMember('Fachri Yumanda Putra', 'Anggota', 'lib/image/fahri.jpg'),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _scrollController.addListener(_onScroll);
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) setState(() => _currentPage = next);
    });
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < _teamMembers.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A237E),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 60,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'lib/image/logo.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    _buildInfoSection(),
                    _buildFeatureSection(),
                    _buildTeamSection(),
                    _buildContactSection(),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return _buildCard(
      'Tentang Aplikasi',
      'SmartEye adalah solusi inovatif untuk deteksi objek real-time menggunakan AI. Aplikasi ini dirancang untuk mengenali berbagai objek dengan akurasi tinggi.',
      Icons.info_outline,
    );
  }

  Widget _buildFeatureSection() {
    return _buildCard(
      'Fitur Utama',
      '• Deteksi Objek Real-Time\n• Dukungan Multi Objek\n• Antarmuka Sederhana',
      Icons.star_outline,
    );
  }

  Widget _buildContactSection() {
    return _buildCard(
      'Contact Us',
      'Email: zulkifli@gmail.com\nPhone: +62 123 1234 1234\nAddress: Tempeut Teungoh, Langsa',
      Icons.contact_mail_outlined,
    );
  }

  Widget _buildCard(String title, String content, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 8,
        shadowColor: Color(0xFF0288D1).withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A237E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: Color(0xFF1A237E), size: 24),
                    ),
                    SizedBox(width: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(
                    color: Color(0xFF1A237E).withOpacity(0.1),
                    thickness: 1,
                  ),
                ),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, color: Color(0xFF1A237E), size: 28),
                SizedBox(width: 10),
                Text(
                  'Our Team',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 450,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _teamMembers.length,
              itemBuilder: (context, index) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = (_currentPage - index)
                      .abs()
                      .toDouble(); // Convert to double here
                  value = (1 - value.clamp(0.0, 1.0));
                }


                return Transform.scale(
                  scale: 0.9 + (value * 0.1),
                  child: Opacity(
                    opacity: 0.5 + (value * 0.5),
                    child: _buildTeamCard(_teamMembers[index]),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _teamMembers.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? Color(0xFF1A237E)
                        : Color(0xFF1A237E).withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(TeamMember member) {
    return Card(
      elevation: 8,
      shadowColor: Color(0xFF0288D1).withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                image: DecorationImage(
                  image: AssetImage(member.imagePath),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    member.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A237E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      member.role,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamMember {
  final String name;
  final String role;
  final String imagePath;

  TeamMember(this.name, this.role, this.imagePath);
}
