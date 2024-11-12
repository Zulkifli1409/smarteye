import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure this package is added to your pubspec.yaml

class DetectionResultsPage extends StatefulWidget {
  @override
  _DetectionResultsPageState createState() => _DetectionResultsPageState();
}

class _DetectionResultsPageState extends State<DetectionResultsPage> {
  // List of sample detection results with categories
  final List<Map<String, dynamic>> detectedObjects = [
    {
      'category': 'Image Real-time',
      'detections': [
        {
          'date': '2024-10-26',
          'icon': '🍎',
          'objects': ['Objek 1', 'Objek 2'],
        },
        {
          'date': '2024-10-27',
          'icon': '🐶',
          'objects': ['Objek 3', 'Objek 4'],
        },
      ],
    },
    {
      'category': 'Video',
      'detections': [
        {
          'date': '2024-10-28',
          'icon': '🎥',
          'objects': ['Objek 5', 'Objek 6'],
        },
      ],
    },
    // Add more categories here if needed
  ];

  String selectedCategory = 'Image Real-time'; // Default selected category
  DateTime selectedDate = DateTime.now(); // Default selected date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasil Deteksi'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'), // Ensure the path is correct
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          children: [
            // Column for date and category filters
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Date filter
                    Text(
                      'Filter Tanggal:',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        // Select date using DatePicker
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate != null && pickedDate != selectedDate) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Text(
                        DateFormat('dd MMMM yyyy').format(selectedDate),
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Dropdown for category selection
                    Text(
                      'Pilih Kategori:',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    DropdownButton<String>(
                      value: selectedCategory,
                      items: detectedObjects
                          .map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['category'],
                          child: Text(
                            category['category'],
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                      dropdownColor: Colors.black54,
                      style: TextStyle(color: Colors.white),
                      underline: Container(),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),
            // Column for displaying detection results
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: detectedObjects.length,
                  itemBuilder: (context, index) {
                    final category = detectedObjects[index];

                    // Only display selected category
                    if (category['category'] != selectedCategory) {
                      return SizedBox
                          .shrink(); // Don't display unselected categories
                    }

                    // Filter detections based on selected date
                    final filteredDetections =
                        category['detections'].where((obj) {
                      final detectionDate = DateTime.parse(obj['date']);
                      return detectionDate.isBefore(selectedDate) ||
                          detectionDate.isAtSameMomentAs(selectedDate);
                    }).toList();

                    if (filteredDetections.isEmpty) {
                      return SizedBox
                          .shrink(); // No detections for selected date
                    }

                    return Column(
                      children: filteredDetections.map<Widget>((obj) {
                        final formattedDate = DateFormat('dd MMMM yyyy')
                            .format(DateTime.parse(obj['date']));

                        return Card(
                          margin:
                              EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          color: Colors.black54,
                          child: ExpansionTile(
                            title: Text(
                              '$formattedDate ${obj['icon']}',
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Tap untuk melihat objek terdeteksi',
                              style: TextStyle(color: Colors.white70),
                            ),
                            children: obj['objects'].map<Widget>((object) {
                              return ListTile(
                                title: Text(object,
                                    style: TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
