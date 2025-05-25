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
  
  // Couleurs pour correspondre au style de la gestion des absences
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _loadStudentsFromClass();
  }

  // Charger les élèves de la classe sélectionnée depuis Firebase
  Future<void> _loadStudentsFromClass() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer tous les élèves qui appartiennent à la classe sélectionnée
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

        print("Nouvelle tentative, élèves trouvés: ${querySnapshot.docs.length}");
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
          content: Text("Erreur: Impossible de charger les élèves. Détails: $e"),
          backgroundColor: Colors.red,
        ),
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
        SnackBar(
          content: Text("✅ Absences enregistrées avec succès!"),
          backgroundColor: greenColor,
        ),
      );

      // Revenir à l'écran précédent
      Navigator.pop(context);
    } catch (e) {
      print("Erreur lors de l'enregistrement des absences: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur: Impossible d'enregistrer les absences"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget pour afficher les informations de session
  Widget _buildSessionInfoCard() {
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
                  Icons.info_outline,
                  color: orangeColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Text(
                "Informations de la séance",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoRow(Icons.book, "Matière", widget.selectedMatiere),
          SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, "Date", widget.selectedDate),
          SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, "Heure", widget.selectedHeure),
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

  // Widget pour la liste des élèves
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
                  "${students.length} élèves",
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
          students.isEmpty
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
                          "Aucun élève trouvé pour cette classe",
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
                  itemCount: students.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final studentId = student['id'];
                    final isAbsent = absences[studentId] ?? false;

                    return Container(
                      decoration: BoxDecoration(
                        color: isAbsent 
                            ? Colors.red.withOpacity(0.05)
                            : greenColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAbsent 
                              ? Colors.red.withOpacity(0.2)
                              : greenColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isAbsent ? Colors.red : greenColor,
                          child: Text(
                            "${student['prenom']?[0] ?? ''}${student['nom']?[0] ?? ''}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          "${student['prenom'] ?? ''} ${student['nom'] ?? ''}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkColor,
                          ),
                        ),
                        subtitle: student['idEleve'] != null
                            ? Text(
                                "ID: ${student['idEleve']}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: darkColor.withOpacity(0.6),
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAbsent ? "Absent" : "Présent",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isAbsent ? Colors.red : greenColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            Switch(
                              value: isAbsent,
                              onChanged: (value) {
                                setState(() {
                                  absences[studentId] = value;
                                });
                              },
                              activeColor: Colors.red,
                              inactiveTrackColor: greenColor.withOpacity(0.3),
                              inactiveThumbColor: greenColor,
                            ),
                          ],
                        ),
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
                          'Détails des absences',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Marquer les élèves absents",
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
                        // Informations de la séance
                        _buildSessionInfoCard(),
                        
                        // Liste des élèves
                        _buildStudentsList(),
                        
                        // Bouton d'enregistrement
                        Container(
                          height: 55,
                          margin: EdgeInsets.only(bottom: 30),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _saveAbsences,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              disabledBackgroundColor: darkColor.withOpacity(0.3),
                            ),
                            child: Text(
                              "ENREGISTRER LES ABSENCES",
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