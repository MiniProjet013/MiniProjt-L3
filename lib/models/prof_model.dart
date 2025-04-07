class ProfModel {
  String id;
  String nom;
  String prenom;
  String email;
  String motDePasse;
  String matiere;
  String classeId;

  ProfModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motDePasse,
    required this.matiere,
    required this.classeId,
  });

  // تحويل من JSON
  factory ProfModel.fromJson(Map<String, dynamic> json) {
    return ProfModel(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      motDePasse: json['mot_de_passe'],
      matiere: json['matiere'],
      classeId: json['classeId'],
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'mot_de_passe': motDePasse,
      'matiere': matiere,
      'classeId': classeId,
    };
  }
}
