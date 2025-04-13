import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_notes_screen.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Variables pour stocker les sélections
  String? selectedYear;
  String? selectedTrimestre;
  String? selectedClasse;
  String? selectedMatiere;
  String? selectedEvalType;
  
  // Variables pour stocker les listes de données
  List<String> anneesScolaires = [];
  List<String> trimestres = ["1er trimestre", "2ème trimestre", "3ème trimestre"];
  List<String> classes = [];
  List<String> matieres = ["Mathématiques", "Français", "Physique", "Histoire", "Sport", "Sciences"];
  List<String> typesEvaluation = ["Examen", "Devoir"];
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Récupérer les années scolaires
      QuerySnapshot yearSnapshot = await _firestore.collection('classes').get();
      Set<String> years = {};
      
      for (var doc in yearSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('anneeScolaire')) {
          years.add(data['anneeScolaire']);
        }
      }
      anneesScolaires = years.toList();
      
      // Récupérer les classes
      QuerySnapshot classSnapshot = await _firestore.collection('classes').get();
      List<String> classesList = [];
      
      for (var doc in classSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('numeroClasse')) {
          classesList.add(data['numeroClasse']);
        }
      }
      classes = classesList;
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des données: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Row(
          children: [
            Icon(Icons.grade, color: Colors.white),
            SizedBox(width: 10),
            Text("NOTES", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDropdown(
                  "ANNÉE SCOLAIRE", 
                  anneesScolaires,
                  selectedYear,
                  (value) => setState(() => selectedYear = value)
                ),
                _buildDropdown(
                  "TRIMESTRE", 
                  trimestres,
                  selectedTrimestre,
                  (value) => setState(() => selectedTrimestre = value)
                ),
                _buildDropdown(
                  "CLASSE", 
                  classes,
                  selectedClasse,
                  (value) => setState(() => selectedClasse = value)
                ),
                _buildDropdown(
                  "MATIÈRE", 
                  matieres,
                  selectedMatiere,
                  (value) => setState(() => selectedMatiere = value)
                ),
                _buildDropdown(
                  "TYPE D'ÉVALUATION", 
                  typesEvaluation,
                  selectedEvalType,
                  (value) => setState(() => selectedEvalType = value)
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _canSubmit() ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentNotesScreen(
                          anneeScolaire: selectedYear!,
                          trimestre: selectedTrimestre!,
                          classe: selectedClasse!,
                          matiere: selectedMatiere!,
                          typeEvaluation: selectedEvalType!,
                        )
                      )
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(185, 255, 115, 0),
                    shape: StadiumBorder(),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text("AFFICHER LES NOTES", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
    );
  }

  bool _canSubmit() {
    return selectedYear != null && 
           selectedTrimestre != null && 
           selectedClasse != null && 
           selectedMatiere != null && 
           selectedEvalType != null;
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label, 
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item, 
          child: Text(item)
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }
}