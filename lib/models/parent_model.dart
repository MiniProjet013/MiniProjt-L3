class ParentModel {
  String id;
  String nom;
  String email;
  String motDePasse;
  List<String> enfants; // قائمة بمراجع الأطفال

  ParentModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.motDePasse,
    required this.enfants,
  });

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    return ParentModel(
      id: json['id'],
      nom: json['nom'],
      email: json['email'],
      motDePasse: json['mot_de_passe'],
      enfants: List<String>.from(json['enfants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'mot_de_passe': motDePasse,
      'enfants': enfants,
    };
  }
}
