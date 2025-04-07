class ClasseModel {
  String id;
  int num;
  List<String> profs;
  List<String> eleves;

  ClasseModel({
    required this.id,
    required this.num,
    required this.profs,
    required this.eleves,
  });

  factory ClasseModel.fromJson(Map<String, dynamic> json) {
    return ClasseModel(
      id: json['id'],
      num: json['num'],
      profs: List<String>.from(json['profs'] ?? []),
      eleves: List<String>.from(json['eleves'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'num': num,
      'profs': profs,
      'eleves': eleves,
    };
  }
}
