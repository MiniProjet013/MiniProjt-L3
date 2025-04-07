class AdministrationModel {
  String id;
  String email;
  String motDePasse;

  AdministrationModel({
    required this.id,
    required this.email,
    required this.motDePasse,
  });

  factory AdministrationModel.fromJson(Map<String, dynamic> json) {
    return AdministrationModel(
      id: json['id'],
      email: json['email'],
      motDePasse: json['mot_de_passe'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'mot_de_passe': motDePasse,
    };
  }
}
