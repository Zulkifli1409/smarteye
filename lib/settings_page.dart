import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> selectedObjects = [];
  List<String> _allObjects = [
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck',
    'boat', 'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench',
    'bird', 'cat', 'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra',
    'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee',
    'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove',
    'skateboard', 'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup', 'fork',
    'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange', 'broccoli',
    'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch', 'potted plant',
    'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse', 'remote', 'keyboard',
    'cell phone', 'microwave', 'oven', 'toaster', 'sink', 'refrigerator', 'book',
    'clock', 'vase', 'scissors', 'teddy bear', 'hair drier', 'toothbrush'
  ];
  List<String> _filteredObjects = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredObjects = List.from(_allObjects);
    _searchController.addListener(_filterObjects);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterObjects() {
    setState(() {
      _filteredObjects = _allObjects
          .where((object) => object
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Objek yang Ingin Dideteksi'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/image/bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari objek...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white), // Set the text color to white
              ),
            ),
            Expanded(
              child: ListView(
                children: _filteredObjects.map((object) {
                  return CheckboxListTile(
                    title: Text(
                      object,
                      style: TextStyle(
                        color: Colors.white, // Set text color to white for the list
                      ),
                    ),
                    value: selectedObjects.contains(object),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedObjects.add(object);
                        } else {
                          selectedObjects.remove(object);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, selectedObjects);
                },
                child: Text('Simpan Pilihan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Replaced primary with backgroundColor
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
