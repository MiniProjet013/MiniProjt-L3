import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'modifier_eleve_detail_screen.dart';

class EleveModifierScreen extends StatefulWidget {
  @override
  _EleveModifierScreenState createState() => _EleveModifierScreenState();
}

class _EleveModifierScreenState extends State<EleveModifierScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> eleves = [];
  String? searchQuery;
  String? filterNiveau;
  String? filterClasse;
  
  // Colors to match the ModifierScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);
  
  List<String> niveauxEtude = [
    "1ère année", "2ème année", "3ème année",
    "4ème année", "5ème année", "6ème année"
  ];

  @override
  void initState() {
    super.initState();
    _fetchEleves();
  }

  Future<void> _fetchEleves() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      Query query = _db.collection('eleves');
      
      if (filterNiveau != null) {
        query = query.where('niveau', isEqualTo: filterNiveau);
      }
      
      if (filterClasse != null) {
        query = query.where('numeroClasse', isEqualTo: filterClasse);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      List<Map<String, dynamic>> fetchedEleves = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'nom': data['nom'] ?? '',
          'prenom': data['prenom'] ?? '',
          'niveau': data['niveau'] ?? '',
          'numeroClasse': data['numeroClasse'] ?? '',
          'idEleve': data['idEleve'] ?? doc.id,
        };
      }).toList();
      
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        fetchedEleves = fetchedEleves.where((eleve) {
          String fullName = '${eleve['nom']} ${eleve['prenom']}'.toLowerCase();
          String query = searchQuery!.toLowerCase();
          String id = eleve['idEleve'].toString().toLowerCase();
          return fullName.contains(query) || id.contains(query);
        }).toList();
      }
      
      setState(() {
        eleves = fetchedEleves;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching eleves: $e");
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Erreur lors du chargement des élèves!"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar like ModifierScreen
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
                          'Modifier les élèves',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gérer la liste des élèves',
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
                onPressed: _fetchEleves,
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
                        _fetchEleves();
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: Text("Niveau"),
                              value: filterNiveau,
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text("Tous"),
                                ),
                                ...niveauxEtude.map((niveau) => DropdownMenuItem<String>(
                                  value: niveau,
                                  child: Text(niveau),
                                )).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  filterNiveau = value;
                                });
                                _fetchEleves();
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
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
                              _fetchEleves();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Students List
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
              : eleves.isEmpty
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
                            "Aucun élève trouvé",
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
                        final eleve = eleves[index];
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
                                Icons.person,
                                size: 30,
                                color: index % 2 == 0 ? orangeColor : greenColor,
                              ),
                            ),
                            title: Text(
                              "${eleve['nom']} ${eleve['prenom']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: darkColor,
                              ),
                            ),
                            subtitle: Text(
                              "ID: ${eleve['idEleve']} | ${eleve['niveau']} | Classe: ${eleve['numeroClasse']}",
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
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
                                          builder: (context) => ModifierEleveScreen(eleveId: eleve['idEleve']),
                                        ),
                                      );
                                      
                                      if (result == true) {
                                        _fetchEleves();
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
                                      _showDeleteConfirmation(eleve);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: eleves.length,
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
          // Navigate to add new student screen
          print("Add new student");
        },
      ),
    );
  }
  
  void _showDeleteConfirmation(Map<String, dynamic> eleve) {
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
              "Voulez-vous vraiment supprimer l'élève ${eleve['nom']} ${eleve['prenom']}?",
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
              await _deleteEleve(eleve);
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteEleve(Map<String, dynamic> eleve) async {
  try {
    // 1. Get the student document
    DocumentSnapshot eleveDoc = await _db.collection('eleves').doc(eleve['idEleve']).get();
    
    if (!eleveDoc.exists) {
      throw Exception("Student document not found");
    }
    
    // 2. Create archive document with all student data and timestamp
    Map<String, dynamic> archiveData = {
      ...eleveDoc.data() as Map<String, dynamic>,
      'archivedAt': FieldValue.serverTimestamp(),
      'originalId': eleve['idEleve'],
    };
    
    // 3. Add to archive collection
    await _db.collection('ARCHIVE_ELEVES').add(archiveData);
    
    // 4. Delete from original collection
    await _db.collection('eleves').doc(eleve['idEleve']).delete();
    
    // 5. Remove from class if exists
    if (eleve['classeId'] != null) {
      await _db.collection('classes').doc(eleve['classeId']).update({
        "eleves.${eleve['idEleve']}": FieldValue.delete()
      });
    }
    
    // 6. Batch delete references in other collections
    WriteBatch batch = _db.batch();
    
    // Delete from remarques
    QuerySnapshot remarquesSnapshot = await _db
        .collection('remarques')
        .where("eleve", isEqualTo: eleve['idEleve'])
        .get();
        
    for (var doc in remarquesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete from attendance
    QuerySnapshot attendanceSnapshot = await _db
        .collection('attendance')
        .where("eleveId", isEqualTo: eleve['idEleve'])
        .get();
        
    for (var doc in attendanceSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete from results
    QuerySnapshot resultsSnapshot = await _db
        .collection('results')
        .where("eleveId", isEqualTo: eleve['idEleve'])
        .get();
        
    for (var doc in resultsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    
    // Refresh the list
    _fetchEleves();
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("✅ Élève archivé et supprimé avec succès!"),
      backgroundColor: greenColor,
    ));
  } catch (e) {
    print("❌ Error deleting/archiving eleve: $e");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("❌ Erreur lors de l'archivage/suppression de l'élève!"),
      backgroundColor: Colors.red,
    ));
  }
}
}