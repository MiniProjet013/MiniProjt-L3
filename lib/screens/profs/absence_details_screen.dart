import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AbsenceDetailsScreen extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;
  final String selectedDate;
  final String selectedHeure;

  const AbsenceDetailsScreen({
    super.key,
    required this.selectedClass,
    required this.selectedMatiere,
    required this.selectedDate,
    required this.selectedHeure,
  });

  @override
  _AbsenceDetailsScreenState createState() => _AbsenceDetailsScreenState();
}

class _AbsenceDetailsScreenState extends State<AbsenceDetailsScreen> {
  List<Map<String, dynamic>> students = [];
  Map<String, bool> absences = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentsFromClass();
  }

  // Charger les élèves de la classe sélectionnée depuis Firebase
  // Correction de la méthode _loadStudentsFromClass dans AbsenceDetailsScreen

  Future<void> _loadStudentsFromClass() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer tous les élèves qui appartiennent à la classe sélectionnée
      // CORRECTION: Utiliser le champ correct selon la structure Firebase
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('eleves')
          .where('classeId', isEqualTo: widget.selectedClass)
          .get();

      // Imprimer pour débogage
      print("Nombre d'élèves trouvés: ${querySnapshot.docs.length}");
      print("Recherche des élèves avec classeId: ${widget.selectedClass}");

      List<Map<String, dynamic>> loadedStudents = [];

      if (querySnapshot.docs.isEmpty) {
        // Si aucun élève trouvé avec classeId, essayer avec classeID (majuscule)
        print("Tentative avec classeID...");
        querySnapshot = await FirebaseFirestore.instance
            .collection('eleves')
            .where('classeID', isEqualTo: widget.selectedClass)
            .get();

        print(
            "Nouvelle tentative, élèves trouvés: ${querySnapshot.docs.length}");
      }

      // Si toujours aucun résultat, essayer une requête sans filtrage
      if (querySnapshot.docs.isEmpty) {
        print("Récupération de tous les élèves pour inspection...");
        QuerySnapshot allStudents = await FirebaseFirestore.instance
            .collection('eleves')
            .limit(5)
            .get();

        // Analyser les documents pour trouver le bon nom de champ
        for (var doc in allStudents.docs) {
          print("Document élève: ${doc.id}");
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print("Champs disponibles: ${data.keys.join(', ')}");
        }
      }

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ajouter l'ID du document pour faciliter l'enregistrement plus tard
        data['id'] = doc.id;
        loadedStudents.add(data);

        // Initialiser tous les élèves comme présents (absence = false)
        absences[doc.id] = false;
      }

      setState(() {
        students = loadedStudents;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des élèves: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Erreur: Impossible de charger les élèves. Détails: $e")),
      );
    }
  }

  // Enregistrer les absences dans Firebase
  Future<void> _saveAbsences() async {
    try {
      // Référence à la collection "absences"
      CollectionReference absencesCollection =
          FirebaseFirestore.instance.collection('absences');

      // Date formatée pour faciliter les requêtes ultérieures
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final dateFormatted =
          formatter.format(DateTime.parse(widget.selectedDate));

      // Pour chaque élève marqué absent
      List<Future> saveTasks = [];
      for (String studentId in absences.keys) {
        if (absences[studentId] == true) {
          // Trouver les informations de l'élève
          Map<String, dynamic>? student = students.firstWhere(
            (s) => s['id'] == studentId,
            orElse: () => {},
          );

          if (student.isNotEmpty) {
            // Créer un document d'absence
            saveTasks.add(absencesCollection.add({
              'eleveId': studentId,
              'nom': student['nom'],
              'prenom': student['prenom'],
              'classeId': widget.selectedClass,
              'matiere': widget.selectedMatiere,
              'date': dateFormatted,
              'heure': widget.selectedHeure,
              'timestamp': FieldValue.serverTimestamp(),
            }));
          }
        }
      }

      // Attendre que tous les enregistrements soient terminés
      await Future.wait(saveTasks);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Absences enregistrées avec succès!")),
      );

      // Revenir à l'écran précédent
      Navigator.pop(context);
    } catch (e) {
      print("Erreur lors de l'enregistrement des absences: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur: Impossible d'enregistrer les absences")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Détails des absences"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations sur la session
            Text("📚 Matière: ${widget.selectedMatiere}",
                style: TextStyle(fontSize: 16)),
            Text("📅 Date: ${widget.selectedDate}",
                style: TextStyle(fontSize: 16)),
            Text("⏰ Heure: ${widget.selectedHeure}",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),

            // Liste des élèves
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : students.isEmpty
                      ? Center(
                          child: Text("Aucun élève trouvé pour cette classe",
                              style: TextStyle(fontSize: 18)))
                      : ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final studentId = student['id'];

                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                title: Text(
                                  "${student['prenom']} ${student['nom']}",
                                  style: TextStyle(fontSize: 18),
                                ),
                                subtitle:
                                    Text("ID: ${student['idEleve'] ?? ''}"),
                                trailing: Switch(
                                  value: absences[studentId] ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      absences[studentId] = value;
                                    });
                                  },
                                  activeColor: Colors.red,
                                  inactiveTrackColor: Colors.green,
                                  inactiveThumbColor: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
            ),

            SizedBox(height: 20),

            // Bouton d'enregistrement
            Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveAbsences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(213, 230, 122, 0),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text("ENREGISTRER"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
