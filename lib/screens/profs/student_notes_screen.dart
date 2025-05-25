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

  // Couleurs pour correspondre au style des autres interfaces
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveNotes() async {
    bool allValid = true;
    Map<String, double> validNotes = {};

    noteControllers.forEach((studentId, controller) {
      if (controller.text.isNotEmpty) {
        double? note = double.tryParse(controller.text);
        if (note != null && note >= 0 && note <= 10) {
          validNotes[studentId] = note;
        } else {
          allValid = false;
        }
      }
    });

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Veuillez entrer des notes valides (0-10)"),
          backgroundColor: Colors.orange,
        ),
      );
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
        SnackBar(
          content: Text("✅ Notes enregistrées avec succès!"),
          backgroundColor: greenColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Erreur: $e");
      setState(() {
        isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget pour afficher les informations de l'évaluation
  Widget _buildEvaluationInfoCard() {
    return Container(
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
                  Icons.assignment,
                  color: orangeColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Text(
                "Informations de l'évaluation",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoRow(Icons.book, "Matière", widget.matiere),
          SizedBox(height: 12),
          _buildInfoRow(Icons.class_, "Classe", widget.classe),
          SizedBox(height: 12),
          _buildInfoRow(Icons.quiz, "Type", widget.typeEvaluation),
          SizedBox(height: 12),
          _buildInfoRow(Icons.schedule, "Trimestre", widget.trimestre),
        ],
      ),
    );
  }

  // Widget pour une ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: greenColor, size: 20),
        SizedBox(width: 12),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: darkColor.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour la liste des élèves avec leurs notes
  Widget _buildStudentsList() {
    return Container(
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
                  Icons.group,
                  color: greenColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Text(
                "Liste des élèves",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: orangeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${studentList.length} élèves",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: orangeColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // En-tête du tableau
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: darkColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: darkColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "Nom de l'élève",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: darkColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Note /10",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: darkColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12),
          
          // Liste des élèves
          studentList.isEmpty
              ? Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 48,
                          color: darkColor.withOpacity(0.3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Aucun élève trouvé dans cette classe",
                          style: TextStyle(
                            fontSize: 16,
                            color: darkColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: studentList.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = studentList[index];
                    final studentId = student['id'];

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: darkColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar et nom
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: greenColor,
                                  radius: 20,
                                  child: Text(
                                    "${student['prenom']?[0] ?? ''}${student['nom']?[0] ?? ''}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    student['nomComplet'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: darkColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Champ de note
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: TextField(
                                controller: noteControllers[studentId],
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: darkColor,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: darkColor.withOpacity(0.2)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: darkColor.withOpacity(0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: orangeColor, width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  hintText: "0-10",
                                  hintStyle: TextStyle(
                                    color: darkColor.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
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
                          'Saisie des notes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "${widget.matiere} - Classe ${widget.classe}",
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
          isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Chargement des élèves...",
                          style: TextStyle(
                            fontSize: 16,
                            color: darkColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Informations de l'évaluation
                        _buildEvaluationInfoCard(),
                        
                        // Liste des élèves
                        _buildStudentsList(),
                        
                        // Bouton de publication
                        Container(
                          height: 55,
                          margin: EdgeInsets.only(bottom: 30),
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _saveNotes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              disabledBackgroundColor: darkColor.withOpacity(0.3),
                            ),
                            child: isSaving
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "PUBLICATION EN COURS...",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    "PUBLIER LES NOTES",
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
                ),
        ],
      ),
    );
  }
}