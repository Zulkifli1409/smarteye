class DetectedObject {
  final int? id;
  final String label;
  final double confidence;
  final String boundingBox;
  final String category;
  final String date;

  DetectedObject({
    this.id,
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'confidence': confidence,
      'boundingBox': boundingBox,
      'category': category,
      'date': date,
    };
  }

  static DetectedObject fromMap(Map<String, dynamic> map) {
    return DetectedObject(
      id: map['id'],
      label: map['label'],
      confidence: map['confidence'],
      boundingBox: map['boundingBox'],
      category: map['category'] ?? 'Tidak Terkategori',
      date: map['date'] ?? DateTime.now().toIso8601String(),
    );
  }
}
