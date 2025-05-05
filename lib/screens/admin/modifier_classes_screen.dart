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

  // Supprimer une classe depuis Firestore
  Future<void> _deleteClass(String classId) async {
    try {
      await _db.collection('classes').doc(classId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Classe supprimée avec succès!"),
        backgroundColor: Colors.green,
      ));
      _loadClasses();
    } catch (e) {
      print("❌ Error deleting class: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Erreur lors de la suppression de la classe!"),
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
          "Confirmation",
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 50,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Voulez-vous vraiment archiver et supprimer la classe ${classData['numeroClasse']}?",
              style: TextStyle(fontSize: 16),
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
            onPressed: () async {
              Navigator.pop(context);
              await _deleteClass(classData['idClasse']);
            },
            child: Text(
              "Supprimer",
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Supprimer",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteClass(classData['idClasse']);
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
                                                // Bouton de suppression
                                                Container(
                                                  height: 36,
                                                  width: 36,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    icon: Icon(Icons.delete, size: 18, color: Colors.red),
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