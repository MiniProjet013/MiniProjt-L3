class RemarqueModel {
  String id;
  String profId;
  String eleveId;
  String message;

  RemarqueModel({
    required this.id,
    required this.profId,
    required this.eleveId,
    required this.message,
  });

  factory RemarqueModel.fromJson(Map<String, dynamic> json) {
    return RemarqueModel(
      id: json['id'],
      profId: json['profId'],
      eleveId: json['eleveId'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profId': profId,
      'eleveId': eleveId,
      'message': message,
    };
  }
}
