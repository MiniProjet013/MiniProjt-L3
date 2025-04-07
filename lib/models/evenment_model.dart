class EvenementModel {
  String id;
  DateTime date;
  String heure;
  String type;

  EvenementModel({
    required this.id,
    required this.date,
    required this.heure,
    required this.type,
  });

  factory EvenementModel.fromJson(Map<String, dynamic> json) {
    return EvenementModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      heure: json['heure'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'heure': heure,
      'type': type,
    };
  }
}
