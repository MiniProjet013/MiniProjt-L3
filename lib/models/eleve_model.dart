class EleveModel {
  String id;
  String nom;
  DateTime dateNaissance;
  String classeId;
  String parentId;

  EleveModel({
    required this.id,
    required this.nom,
    required this.dateNaissance,
    required this.classeId,
    required this.parentId,
  });

  factory EleveModel.fromJson(Map<String, dynamic> json) {
    return EleveModel(
      id: json['id'],
      nom: json['nom'],
      dateNaissance: DateTime.parse(json['dateNaissance']),
      classeId: json['classeId'],
      parentId: json['parentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'dateNaissance': dateNaissance.toIso8601String(),
      'classeId': classeId,
      'parentId': parentId,
    };
  }
}
