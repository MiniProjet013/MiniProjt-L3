import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({Key? key}) : super(key: key);

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedClass;
  List<Map<String, dynamic>> studentList = [];
  List<String> classesList = [];
  bool isLoadingStudents = false;
  bool isLoadingClasses = true;

  // Couleurs pour correspondre au style de la page Devoir
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      isLoadingClasses = true;
      classesList.clear();
    });

    try {
      // Récupérer les classes distinctes à partir de la collection des élèves
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('eleves')
          .get();

      Set<String> uniqueClasses = {};
      
      for (var doc in studentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('numeroClasse') && data['numeroClasse'] != null) {
          uniqueClasses.add(data['numeroClasse'].toString());
        }
      }
      
      List<String> sortedClasses = uniqueClasses.toList()..sort();

      setState(() {
        classesList = sortedClasses;
        isLoadingClasses = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des classes: $e");
      setState(() {
        isLoadingClasses = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }

  Future<void> _loadStudents(String numeroClasse) async {
    setState(() {
      isLoadingStudents = true;
      studentList.clear();
    });

    try {
      print("Recherche des élèves pour la classe numéro: $numeroClasse");

      QuerySnapshot studentsSnapshot = await _firestore
          .collection('eleves')
          .where('numeroClasse', isEqualTo: numeroClasse)
          .get();

      print("Nombre d'élèves trouvés: ${studentsSnapshot.docs.length}");

      List<Map<String, dynamic>> students = [];

      for (var studentDoc in studentsSnapshot.docs) {
        Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;

        students.add({
          'id': studentDoc.id,
          'nom': studentData['nom'] ?? '',
          'prenom': studentData['prenom'] ?? '',
          'nomComplet': "${studentData['prenom'] ?? ''} ${studentData['nom'] ?? ''}",
        });
      }

      // Trier les élèves par nom
      students.sort((a, b) => a['nomComplet'].compareTo(b['nomComplet']));

      setState(() {
        studentList = students;
        isLoadingStudents = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des élèves: $e");
      setState(() {
        isLoadingStudents = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }

  // Widget de champ de saisie personnalisé avec cadre
  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    String? value,
    required Function(String?) onChanged,
  }) {
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
              value: value,
              items: items.map((item) => 
                DropdownMenuItem(
                  value: item, 
                  child: Text("Classe $item")
                )
              ).toList(),
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                suffixIcon: Icon(Icons.class_, color: greenColor),
              ),
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
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  _loadClasses();
                  if (selectedClass != null) {
                    _loadStudents(selectedClass!);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [orangeColor.withOpacity(0.8), greenColor.withOpacity(0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Liste des élèves',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Consultation par classe",
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
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section de sélection de classe
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
                                Icons.school,
                                color: orangeColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Sélection de classe",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        if (isLoadingClasses)
                          Center(
                            child: CircularProgressIndicator(color: greenColor),
                          )
                        else if (classesList.isEmpty)
                          Center(
                            child: Text(
                              "Aucune classe trouvée dans la base de données",
                              style: TextStyle(
                                color: darkColor.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          _buildDropdownField(
                            label: "CLASSE",
                            items: classesList,
                            value: selectedClass,
                            onChanged: (value) {
                              setState(() {
                                selectedClass = value;
                              });
                              if (value != null) {
                                _loadStudents(value);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  
                  // Section liste des élèves
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
                                color: greenColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.people,
                                color: greenColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              selectedClass != null ? "Élèves de la classe $selectedClass" : "Liste des élèves",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        // Liste des élèves
                        if (isLoadingStudents)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(color: greenColor),
                            ),
                          )
                        else if (selectedClass == null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                "Veuillez sélectionner une classe",
                                style: TextStyle(
                                  color: darkColor.withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else if (studentList.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                "Aucun élève trouvé dans cette classe",
                                style: TextStyle(
                                  color: darkColor.withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: studentList.length,
                            itemBuilder: (context, index) {
                              final student = studentList[index];
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: darkColor.withOpacity(0.1),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    student['nomComplet'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: darkColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "ID: ${student['id']}",
                                    style: TextStyle(
                                      color: darkColor.withOpacity(0.6),
                                    ),
                                  ),
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: greenColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      child: Text(
                                        student['nomComplet'].isNotEmpty 
                                            ? student['nomComplet'][0].toUpperCase() 
                                            : "?",
                                        style: TextStyle(
                                          color: greenColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: darkColor.withOpacity(0.3),
                                  ),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Élève sélectionné: ${student['nomComplet']}"),
                                        backgroundColor: greenColor,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
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
}