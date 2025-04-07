class AbsenceProfModel {
  String id;
  DateTime date;
  bool absent;
  String profId;
  String raison;
  String nom;

  AbsenceProfModel({
    required this.id,
    required this.date,
    required this.absent,
    required this.profId,
    required this.raison,
    required this.nom,
  });

  factory AbsenceProfModel.fromJson(Map<String, dynamic> json) {
    return AbsenceProfModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      absent: json['absent'],
      profId: json['profId'],
      raison: json['raison'],
      nom: json['nom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'absent': absent,
      'profId': profId,
      'raison': raison,
      'nom': nom,
    };
  }
}
