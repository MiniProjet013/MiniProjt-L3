import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentNotesScreen extends StatefulWidget {
  final String anneeScolaire;
  final String trimestre;
  final String classe; // هذا هو numeroClasse (مثال: "2")
  final String matiere;
  final String typeEvaluation;

  StudentNotesScreen({
    required this.anneeScolaire,
    required this.trimestre,
    required this.classe,
    required this.matiere,
    required this.typeEvaluation,
  });

  @override
  _StudentNotesScreenState createState() => _StudentNotesScreenState();
}

class _StudentNotesScreenState extends State<StudentNotesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> studentList = [];
  Map<String, TextEditingController> noteControllers = {};
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    noteControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      isLoading = true;
      studentList.clear();
      noteControllers.clear();
    });

    try {
      print("Recherche des élèves pour la classe numéro: ${widget.classe}");

      // 1. Trouver tous les élèves qui ont ce numeroClasse
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('eleves')
          .where('numeroClasse', isEqualTo: widget.classe)
          .get();

      print("Nombre d'élèves trouvés: ${studentsSnapshot.docs.length}");

      List<Map<String, dynamic>> students = [];

      for (var studentDoc in studentsSnapshot.docs) {
        Map<String, dynamic> studentData =
            studentDoc.data() as Map<String, dynamic>;

        students.add({
          'id': studentDoc.id,
          'nom': studentData['nom'] ?? '',
          'prenom': studentData['prenom'] ?? '',
          'nomComplet':
              "${studentData['prenom'] ?? ''} ${studentData['nom'] ?? ''}",
        });

        noteControllers[studentDoc.id] = TextEditingController();
      }

      setState(() {
        studentList = students;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
    }
  }

  Future<void> _saveNotes() async {
    bool allValid = true;
    Map<String, double> validNotes = {};

    noteControllers.forEach((studentId, controller) {
      if (controller.text.isNotEmpty) {
        double? note = double.tryParse(controller.text);
        if (note != null && note >= 0 && note <= 20) {
          validNotes[studentId] = note;
        } else {
          allValid = false;
        }
      }
    });

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Veuillez entrer des notes valides (0-20)")));
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      String collectionName = widget.typeEvaluation.toLowerCase() == "examen"
          ? "note_examen"
          : "note_devoir";

      DocumentReference evaluationRef =
          await _firestore.collection(collectionName).add({
        'anneeScolaire': widget.anneeScolaire,
        'trimestre': widget.trimestre,
        'classe': widget.classe,
        'matiere': widget.matiere,
        'dateCreation': FieldValue.serverTimestamp(),
      });

      Map<String, Map<String, dynamic>> trimestreData = {};

      for (var student in studentList) {
        String studentId = student['id'];
        if (validNotes.containsKey(studentId)) {
          trimestreData[studentId] = {
            'nomComplet': student['nomComplet'],
            'note': validNotes[studentId],
          };
        }
      }

      await evaluationRef.update({
        widget.trimestre: trimestreData,
      });

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Notes enregistrées avec succès!")));

      Navigator.pop(context);
    } catch (e) {
      print("Erreur: $e");
      setState(() {
        isSaving = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text(
          "${widget.matiere} - Classe ${widget.classe} - ${widget.typeEvaluation}",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : studentList.isEmpty
              ? Center(child: Text("Aucun élève trouvé dans cette classe"))
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Nom de l'élève",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              "Note /20",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(thickness: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: studentList.length,
                        itemBuilder: (context, index) {
                          final student = studentList[index];
                          final studentId = student['id'];

                          return Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    student['nomComplet'],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: noteControllers[studentId],
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      hintText: "0-20",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveNotes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(185, 255, 115, 0),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: isSaving
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "PUBLIER LES NOTES",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
