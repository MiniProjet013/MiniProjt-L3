class MatiereModel {
  String id;
  String nom;
  int coef;
  String profId;

  MatiereModel({
    required this.id,
    required this.nom,
    required this.coef,
    required this.profId,
  });

  factory MatiereModel.fromJson(Map<String, dynamic> json) {
    return MatiereModel(
      id: json['id'],
      nom: json['nom'],
      coef: json['coef'],
      profId: json['profId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'coef': coef,
      'profId': profId,
    };
  }
}
