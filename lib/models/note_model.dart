class NoteModel {
  String id;
  double note;
  String date;
  String eleveId;
  String matiereId;

  NoteModel({
    required this.id,
    required this.note,
    required this.date,
    required this.eleveId,
    required this.matiereId,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      note: json['note'],
      date: json['date'],
      eleveId: json['eleveId'],
      matiereId: json['matiereId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note': note,
      'date': date,
      'eleveId': eleveId,
      'matiereId': matiereId,
    };
  }
}
