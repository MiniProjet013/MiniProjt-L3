class ExamenModel {
  String id;
  DateTime date;
  String description;
  String matiereId;

  ExamenModel({
    required this.id,
    required this.date,
    required this.description,
    required this.matiereId,
  });

  factory ExamenModel.fromJson(Map<String, dynamic> json) {
    return ExamenModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      matiereId: json['matiereId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'matiereId': matiereId,
    };
  }
}
