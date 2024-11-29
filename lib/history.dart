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
      appBar: AppBar(
        title: Text('History Deteksi'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<DetectedObject>>(
          future: dbHelper.getAllObjects(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'Belum ada data tersimpan.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }

            final groupedObjects = _groupByDate(snapshot.data!);
            final dates = groupedObjects.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return ListView.builder(
              itemCount: dates.length,
              itemBuilder: (context, dateIndex) {
                final date = dates[dateIndex];
                final objectsForDate = groupedObjects[date]!;

                objectsForDate.sort((a, b) =>
                    DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: Colors.black54,
                  child: ExpansionTile(
                    title: Text(
                      DateFormat('dd MMMM yyyy').format(DateTime.parse(date)),
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    children: objectsForDate.map((object) {
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        color: Colors.black38,
                        child: ListTile(
                          title: Text(
                            object.label,
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waktu: ${DateFormat('HH:mm:ss').format(DateTime.parse(object.date))}',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Confidence: ${(object.confidence * 100).toStringAsFixed(2)}%',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Kategori: ${object.category.isNotEmpty ? object.category : 'Tidak Terkategori'}',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
