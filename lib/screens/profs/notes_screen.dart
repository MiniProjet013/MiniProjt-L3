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
  
  // Couleurs pour correspondre au style HomeworkScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

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

  // Widget de champ de sélection personnalisé avec cadre
  Widget _buildDropdown(String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkColor.withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor.withOpacity(0.7),
              ),
            ),
            DropdownButtonFormField<String>(
              value: selectedValue,
              isExpanded: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              icon: Icon(Icons.arrow_drop_down, color: greenColor),
              items: items.map((item) => DropdownMenuItem(
                value: item, 
                child: Text(item)
              )).toList(),
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 16,
                color: darkColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [greenColor.withOpacity(0.8), orangeColor.withOpacity(0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.grade, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'NOTES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Gestion des notes des élèves",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Contenu principal
          SliverToBoxAdapter(
            child: isLoading 
              ? Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: greenColor),
                ))
              : Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section principale - Sélection des critères
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        margin: EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: orangeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.filter_list,
                                    color: orangeColor,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  "Critères de sélection",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            
                            // Champs de sélection
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
                            
                            // Bouton d'action
                            Container(
                              height: 55,
                              child: ElevatedButton(
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
                                  backgroundColor: orangeColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                child: Text(
                                  "AFFICHER LES NOTES",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Section informative
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: greenColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: greenColor,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  "Information",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Veuillez sélectionner tous les critères ci-dessus pour consulter les notes des élèves. Vous pourrez ensuite visualiser, modifier et exporter les informations selon vos besoins.",
                              style: TextStyle(
                                color: darkColor.withOpacity(0.7),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
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
}