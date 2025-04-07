class ConvocationModel {
  String id;
  String eleveId;
  String adminId;
  String profId;
  String raison;

  ConvocationModel({
    required this.id,
    required this.eleveId,
    required this.adminId,
    required this.profId,
    required this.raison,
  });

  factory ConvocationModel.fromJson(Map<String, dynamic> json) {
    return ConvocationModel(
      id: json['id'],
      eleveId: json['eleveId'],
      adminId: json['adminId'],
      profId: json['profId'],
      raison: json['raison'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eleveId': eleveId,
      'adminId': adminId,
      'profId': profId,
      'raison': raison,
    };
  }
}
