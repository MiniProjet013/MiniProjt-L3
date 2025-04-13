import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentListScreen extends StatefulWidget {
  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedClass;
  List<Map<String, dynamic>> studentList = [];
  List<String> classesList = [];
  bool isLoadingStudents = false;
  bool isLoadingClasses = true;

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
      // Méthode 1: Récupérer les classes distinctes à partir de la collection des élèves
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
      
      // Méthode 2 (alternative): Si vous avez une collection séparée pour les classes
      // QuerySnapshot classesSnapshot = await _firestore.collection('classes').get();
      // List<String> classes = classesSnapshot.docs.map((doc) {
      //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      //   return data['numero'].toString();
      // }).toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Row(
          children: [
            Icon(Icons.people, color: Colors.white),
            SizedBox(width: 10),
            Text("LISTE D'ÉLÈVES", style: TextStyle(color: Colors.white)),
          ],
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
      ),
      body: Column(
        children: [
          if (isLoadingClasses)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (classesList.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text("Aucune classe trouvée dans la base de données"),
              ),
            )
          else
            _buildDropdown("CLASSE", classesList),
          
          if (isLoadingStudents)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (studentList.isEmpty && selectedClass != null)
            Expanded(
              child: Center(
                child: Text("Aucun élève trouvé dans cette classe"),
              ),
            )
          else if (selectedClass != null)
            Expanded(
              child: ListView.builder(
                itemCount: studentList.length,
                itemBuilder: (context, index) {
                  final student = studentList[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(
                        student['nomComplet'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("ID: ${student['id']}"),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(
                          student['nomComplet'].isNotEmpty 
                              ? student['nomComplet'][0].toUpperCase() 
                              : "?",
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        // Action à effectuer quand on sélectionne un élève
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Élève sélectionné: ${student['nomComplet']}")),
                        );
                      },
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text("Veuillez sélectionner une classe"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label, 
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        value: selectedClass,
        items: items.map((item) => 
          DropdownMenuItem(
            value: item, 
            child: Text("Classe $item")
          )
        ).toList(),
        onChanged: (value) {
          setState(() {
            selectedClass = value;
          });
          if (value != null) {
            _loadStudents(value);
          }
        },
      ),
    );
  }
}