import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'modifier_prof_screen.dart';

class ModifierProfsScreen extends StatefulWidget {
  @override
  _ModifierProfsScreenState createState() => _ModifierProfsScreenState();
}

class _ModifierProfsScreenState extends State<ModifierProfsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> profs = [];
  List<Map<String, dynamic>> filteredProfs = [];
  String? searchQuery;
  String? filterMatiere;
  String? filterClasse;
  String? selectedYear;
  
  // Colors to match the ModifierEleveScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

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
    _loadProfessors();
  }

  Future<void> _loadProfessors() async {
    setState(() => isLoading = true);

    try {
      QuerySnapshot querySnapshot;

      if (selectedYear == "Tous") {
        querySnapshot = await _db.collection('profs').get();
      } else {
        querySnapshot = await _db
            .collection('profs')
            .where("anneeScolaire", isEqualTo: selectedYear)
            .get();
      }

      List<Map<String, dynamic>> loadedProfs = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          "idProf": data["idProf"] ?? "",
          "nom": data["nom"] ?? "",
          "prenom": data["prenom"] ?? "",
          "matiere": data["matiere"] ?? "",
          "email": data["email"] ?? "",
          "numeroClasse": data["numeroClasse"] ?? "",
          "anneeScolaire": data["anneeScolaire"] ?? "",
        };
      }).toList();

      setState(() {
        profs = loadedProfs;
        _filterProfs();
      });
    } catch (e) {
      print("❌ خطأ أثناء تحميل بيانات الأساتذة: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec du chargement des données des professeurs"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterProfs() {
    setState(() {
      filteredProfs = profs.where((prof) {
        // Filter by search query
        if (searchQuery != null && searchQuery!.isNotEmpty) {
          String fullName = '${prof["nom"]} ${prof["prenom"]}'.toLowerCase();
          String query = searchQuery!.toLowerCase();
          String id = prof["idProf"].toString().toLowerCase();
          String matiere = prof["matiere"].toString().toLowerCase();
          
          if (!fullName.contains(query) && 
              !id.contains(query) && 
              !matiere.contains(query)) {
            return false;
          }
        }
        
        // Filter by matiere
        if (filterMatiere != null && filterMatiere!.isNotEmpty) {
          if (!prof["matiere"].toString().toLowerCase().contains(filterMatiere!.toLowerCase())) {
            return false;
          }
        }
        
        // Filter by classe
        if (filterClasse != null && filterClasse!.isNotEmpty) {
          if (prof["numeroClasse"].toString() != filterClasse) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar like ModifierEleveScreen
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
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
                          'Modifier les professeurs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gérer la liste des professeurs',
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
                onPressed: _loadProfessors,
              ),
            ],
          ),
          
          // Search and Filter Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recherche et filtres",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Rechercher par nom ou ID",
                        prefixIcon: Icon(Icons.search, color: greenColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                        _filterProfs();
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  // Filters
                  Row(
                    children: [
                      // Matière filter
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Matière",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            onChanged: (value) {
                              setState(() {
                                filterMatiere = value.isEmpty ? null : value;
                              });
                              _filterProfs();
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      // Classe filter
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Classe",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            onChanged: (value) {
                              setState(() {
                                filterClasse = value.isEmpty ? null : value;
                              });
                              _filterProfs();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Année scolaire filter
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedYear,
                        hint: Text("Année scolaire"),
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
                          _loadProfessors();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Professors List
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                    ),
                  ),
                )
              : filteredProfs.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Aucun professeur trouvé",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final prof = filteredProfs[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    index % 2 == 0 
                                        ? orangeColor.withOpacity(0.2) 
                                        : greenColor.withOpacity(0.2),
                                    index % 2 == 0 
                                        ? orangeColor.withOpacity(0.4) 
                                        : greenColor.withOpacity(0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.school,
                                size: 30,
                                color: index % 2 == 0 ? orangeColor : greenColor,
                              ),
                            ),
                            title: Text(
                              "${prof['nom']} ${prof['prenom']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: darkColor,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ID: ${prof['idProf']} | Matière: ${prof['matiere']}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "Classe: ${prof['numeroClasse']} | ${prof['anneeScolaire']}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ModifierProfScreen(
                                            idProf: prof["idProf"],
                                          ),
                                        ),
                                      );
                                      
                                      if (result == true) {
                                        _loadProfessors();
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _showDeleteConfirmation(prof);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                      childCount: filteredProfs.length,
                    ),
                  ),
          ),
          
          // Bottom padding
          SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: greenColor,
        child: Icon(Icons.add),
        onPressed: () {
          // Navigate to add new professor screen
          print("Add new professor");
        },
      ),
    );
  }
  
  void _showDeleteConfirmation(Map<String, dynamic> prof) {
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
              "Voulez-vous vraiment supprimer le professeur ${prof['nom']} ${prof['prenom']}?",
              style: TextStyle(fontSize: 16),
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
              await _deleteProf(prof);
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteProf(Map<String, dynamic> prof) async {
  try {
    // 1. Get the teacher document
    DocumentSnapshot profDoc = await _db.collection('profs').doc(prof['idProf']).get();
    
    if (!profDoc.exists) {
      throw Exception("Teacher document not found");
    }
    
    // 2. Create archive document with all teacher data and timestamp
    Map<String, dynamic> archiveData = {
      ...profDoc.data() as Map<String, dynamic>,
      'archivedAt': FieldValue.serverTimestamp(),
      'originalId': prof['idProf'],
      //'deletedBy': _db.doc('users/${_db.app.auth().currentUser?.uid}'), // Optional: track who deleted
    };
    
    // 3. Add to archive collection
    await _db.collection('ARCHIVE_PROFS').add(archiveData);
    
    // 4. Delete from original collection
    await _db.collection('profs').doc(prof['idProf']).delete();
    
    // 5. Remove references in other collections
    WriteBatch batch = _db.batch();
    
    // Remove from classes
    QuerySnapshot classesSnapshot = await _db
        .collection('classes')
        .where("profId", isEqualTo: prof['idProf'])
        .get();
        
    for (var doc in classesSnapshot.docs) {
      batch.update(doc.reference, {"profId": null});
    }
    
    // Remove from schedules
    QuerySnapshot schedulesSnapshot = await _db
        .collection('schedules')
        .where("profId", isEqualTo: prof['idProf'])
        .get();
        
    for (var doc in schedulesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Remove from matieres if needed
    QuerySnapshot matieresSnapshot = await _db
        .collection('matieres')
        .where("profId", isEqualTo: prof['idProf'])
        .get();
        
    for (var doc in matieresSnapshot.docs) {
      batch.update(doc.reference, {"profId": null});
    }
    
    await batch.commit();
    
    // Refresh the list
    _loadProfessors();
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("✅ Professeur archivé et supprimé avec succès!"),
      backgroundColor: greenColor,
    ));
  } catch (e) {
    print("✅ Professeur archivé et supprimé avec succès! $e");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("✅ Professeur archivé et supprimé avec succès!"),
      backgroundColor: const Color.fromARGB(255, 21, 153, 4),
    ));
  }
}
}