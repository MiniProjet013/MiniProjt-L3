class DevoirModel {
  String id;
  String titre;
  String type;
  String matiereId;

  DevoirModel({
    required this.id,
    required this.titre,
    required this.type,
    required this.matiereId,
  });

  factory DevoirModel.fromJson(Map<String, dynamic> json) {
    return DevoirModel(
      id: json['id'],
      titre: json['titre'],
      type: json['type'],
      matiereId: json['matiereId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'type': type,
      'matiereId': matiereId,
    };
  }
}
