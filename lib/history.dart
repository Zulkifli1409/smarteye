import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'detected_object.dart';

class HistoryPage extends StatelessWidget {
  final DBHelper dbHelper = DBHelper();

  Map<String, List<DetectedObject>> _groupByDate(List<DetectedObject> objects) {
    Map<String, List<DetectedObject>> grouped = {};
    for (var obj in objects) {
      String date = DateFormat('yyyy-MM-dd').format(DateTime.parse(obj.date));
      grouped.putIfAbsent(date, () => []).add(obj);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'History Deteksi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 8.0,
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
          ),
        ),
        child: FutureBuilder<List<DetectedObject>>(
          future: dbHelper.getAllObjects(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        color: Colors.white.withOpacity(0.7), size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada data tersimpan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            final groupedObjects = _groupByDate(snapshot.data!);
            final dates = groupedObjects.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return ListView.builder(
              padding: EdgeInsets.only(top: 100, bottom: 20),
              itemCount: dates.length,
              itemBuilder: (context, dateIndex) {
                final date = dates[dateIndex];
                final objectsForDate = groupedObjects[date]!
                  ..sort((a, b) =>
                      DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white.withOpacity(0.15),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        colorScheme: ColorScheme.dark(),
                      ),
                      child: ExpansionTile(
                        tilePadding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        title: Text(
                          DateFormat('dd MMMM yyyy')
                              .format(DateTime.parse(date)),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: objectsForDate.map((object) {
                          return Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Text(
                                object.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.access_time,
                                    'Waktu: ${DateFormat('HH:mm:ss').format(DateTime.parse(object.date))}',
                                  ),
                                  SizedBox(height: 4),
                                  _buildInfoRow(
                                    Icons.trending_up,
                                    'Confidence: ${(object.confidence * 100).toStringAsFixed(2)}%',
                                  ),
                                  SizedBox(height: 4),
                                  _buildInfoRow(
                                    Icons.category,
                                    'Kategori: ${object.category.isNotEmpty ? object.category : 'Tidak Terkategori'}',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
