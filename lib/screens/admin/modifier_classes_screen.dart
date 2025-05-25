import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'ModifierClasseScreen.dart';

class ModifierClassesScreen extends StatefulWidget {
  @override
  _ModifierClassesScreenState createState() => _ModifierClassesScreenState();
}

class _ModifierClassesScreenState extends State<ModifierClassesScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> classes = [];
  String? selectedYear;

  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  // Liste des années scolaires disponibles
  final List<String> schoolYears = [
    "Tous",
    "2023-2024",
    "2024-2025",
    "2025-2026",
    "2026-2027",
    "2027-2028"
  ];

  @override
  void initState() {
    super.initState();
    selectedYear = "Tous";
    _loadClasses();
  }

  // Charger les classes depuis Firestore
  Future<void> _loadClasses() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot;
      
      if (selectedYear != null && selectedYear != "Tous") {
        snapshot = await _db.collection('classes')
            .where('anneeScolaire', isEqualTo: selectedYear)
            .orderBy('timestamp', descending: true)
            .get();
      } else {
        snapshot = await _db.collection('classes')
            .orderBy('timestamp', descending: true)
            .get();
      }

      List<Map<String, dynamic>> loadedClasses = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        loadedClasses.add({
          'id': doc.id,
          'idClasse': data['idClasse'] ?? '',
          'numeroClasse': data['numeroClasse'] ?? '',
          'anneeScolaire': data['anneeScolaire'] ?? '',
          'niveauxEtude': data['niveauxEtude'] is List 
              ? List<String>.from(data['niveauxEtude']) 
              : <String>[],
        });
      }

      setState(() {
        classes = loadedClasses;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading classes: $e");
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Erreur lors du chargement des classes!"),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Archiver et supprimer une classe
  Future<void> _archiveAndDeleteClass(String classId) async {
    try {
      // 1. Récupérer les données de la classe
      DocumentSnapshot classDoc = await _db.collection('classes').doc(classId).get();
      
      if (!classDoc.exists) {
        throw Exception("Classe non trouvée");
      }

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      
      // 2. Ajouter les métadonnées d'archivage
      classData['archivedAt'] = FieldValue.serverTimestamp();
      classData['archivedBy'] = 'system'; // Vous pouvez remplacer par l'ID de l'utilisateur connecté
      classData['originalId'] = classId;
      
      // 3. Sauvegarder dans archives_classes
      await _db.collection('archives_classes').add(classData);
      
      // 4. Supprimer de la collection classes
      await _db.collection('classes').doc(classId).delete();
      
      // 5. Supprimer de toutes les autres collections liées (si nécessaire)
      // Par exemple, supprimer les étudiants de cette classe
      QuerySnapshot studentsSnapshot = await _db.collection('students')
          .where('classeId', isEqualTo: classId)
          .get();
      
      // Archiver les étudiants aussi
      WriteBatch batch = _db.batch();
      for (var studentDoc in studentsSnapshot.docs) {
        Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
        studentData['archivedAt'] = FieldValue.serverTimestamp();
        studentData['archivedBy'] = 'system';
        studentData['originalId'] = studentDoc.id;
        studentData['archivedReason'] = 'Classe supprimée';
        
        // Ajouter à archives_students
        batch.set(_db.collection('archives_students').doc(), studentData);
        
        // Supprimer de students
        batch.delete(studentDoc.reference);
      }
      
      // Supprimer les emplois du temps liés à cette classe
      QuerySnapshot schedulesSnapshot = await _db.collection('schedules')
          .where('classeId', isEqualTo: classId)
          .get();
      
      for (var scheduleDoc in schedulesSnapshot.docs) {
        Map<String, dynamic> scheduleData = scheduleDoc.data() as Map<String, dynamic>;
        scheduleData['archivedAt'] = FieldValue.serverTimestamp();
        scheduleData['archivedBy'] = 'system';
        scheduleData['originalId'] = scheduleDoc.id;
        scheduleData['archivedReason'] = 'Classe supprimée';
        
        // Ajouter à archives_schedules
        batch.set(_db.collection('archives_schedules').doc(), scheduleData);
        
        // Supprimer de schedules
        batch.delete(scheduleDoc.reference);
      }
      
      // Supprimer les notes liées à cette classe
      QuerySnapshot gradesSnapshot = await _db.collection('grades')
          .where('classeId', isEqualTo: classId)
          .get();
      
      for (var gradeDoc in gradesSnapshot.docs) {
        Map<String, dynamic> gradeData = gradeDoc.data() as Map<String, dynamic>;
        gradeData['archivedAt'] = FieldValue.serverTimestamp();
        gradeData['archivedBy'] = 'system';
        gradeData['originalId'] = gradeDoc.id;
        gradeData['archivedReason'] = 'Classe supprimée';
        
        // Ajouter à archives_grades
        batch.set(_db.collection('archives_grades').doc(), gradeData);
        
        // Supprimer de grades
        batch.delete(gradeDoc.reference);
      }
      
      // Exécuter toutes les opérations en lot
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Classe archivée et supprimée avec succès!"),
        backgroundColor: Colors.green,
      ));
      
      _loadClasses();
      
    } catch (e) {
      print("❌ Error archiving and deleting class: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Erreur lors de l'archivage de la classe: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Fonction pour afficher la confirmation de suppression
  void _showDeleteConfirmation(Map<String, dynamic> classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Confirmation d'archivage",
          style: TextStyle(
            color: darkColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.archive_outlined,
                color: Colors.orange,
                size: 50,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Voulez-vous vraiment archiver la classe ${classData['numeroClasse']}?",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Cette action archivera:\n• La classe\n• Tous les étudiants de cette classe\n• Les emplois du temps\n• Les notes associées",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              "Annuler",
              style: TextStyle(color: Colors.grey[600]),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Archiver",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _archiveAndDeleteClass(classData['id']);
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
          // En-tête avec gradient
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
                          'Modifier Classes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gérer les classes de l\'établissement',
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
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadClasses,
              ),
            ],
          ),
          
          // Filtre par année scolaire
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedYear,
                    hint: Text("Filtrer par année scolaire"),
                    icon: Icon(Icons.calendar_today, color: greenColor),
                    items: schoolYears.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value;
                      });
                      _loadClasses();
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Liste des classes
          isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                    ),
                  ),
                )
              : classes.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.class_, size: 60, color: Colors.grey.shade400),
                            SizedBox(height: 16),
                            Text(
                              "Aucune classe disponible",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final classData = classes[index];
                            final bool isEvenIndex = index % 2 == 0;
                            final Color cardAccentColor = isEvenIndex ? orangeColor : greenColor;
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 12.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 63, 61, 61).withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    // Barre de couleur à gauche
                                    Container(
                                      width: 8,
                                      decoration: BoxDecoration(
                                        color: cardAccentColor,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(12.0),
                                          bottomLeft: Radius.circular(12.0),
                                        ),
                                      ),
                                    ),
                                    // Contenu de la carte
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            // Informations de la classe
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: cardAccentColor.withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          "Classe ${classData['numeroClasse']}",
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: cardAccentColor,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: darkColor.withOpacity(0.08),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          classData['anneeScolaire'],
                                                          style: TextStyle(
                                                            color: const Color.fromARGB(255, 70, 68, 68),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    "ID: ${classData['idClasse']}",
                                                    style: TextStyle(
                                                      color: const Color.fromARGB(255, 70, 68, 68),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "Niveaux: ${classData['niveauxEtude'].join(', ')}",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: darkColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Boutons d'action
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                // Bouton d'édition
                                                Container(
                                                  height: 36,
                                                  width: 36,
                                                  margin: EdgeInsets.only(bottom: 8),
                                                  decoration: BoxDecoration(
                                                    color: cardAccentColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    icon: Icon(Icons.edit, size: 18, color: cardAccentColor),
                                                    onPressed: () async {
                                                      final result = await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => ModifierClasseScreen(
                                                            classId: classData['idClasse'],
                                                          ),
                                                        ),
                                                      );
                                                      
                                                      if (result == true) {
                                                        _loadClasses();
                                                      }
                                                    },
                                                  ),
                                                ),
                                                // Bouton d'archivage
                                                Container(
                                                  height: 36,
                                                  width: 36,
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    icon: Icon(Icons.archive_outlined, size: 18, color: Colors.orange),
                                                    onPressed: () {
                                                      _showDeleteConfirmation(classData);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: classes.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}