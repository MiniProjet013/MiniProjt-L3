class AbsenceEleveModel {
  String id;
  DateTime date;
  bool absent;
  String eleveId;
  String nom;

  AbsenceEleveModel({
    required this.id,
    required this.date,
    required this.absent,
    required this.eleveId,
    required this.nom,
  });

  factory AbsenceEleveModel.fromJson(Map<String, dynamic> json) {
    return AbsenceEleveModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      absent: json['absent'],
      eleveId: json['eleveId'],
      nom: json['nom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'absent': absent,
      'eleveId': eleveId,
      'nom': nom,
    };
  }
}
