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
  final Color archiveColor = Color.fromARGB(255, 255, 152, 0); // Orange for archive
  
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
                                    tooltip: "Modifier l'élève",
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
                                    color: archiveColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.archive_outlined, color: archiveColor),
                                    tooltip: "Archiver l'élève",
                                    onPressed: () {
                                      _showArchiveConfirmation(eleve);
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
        ],
      ),
    );
  }
  
  void _showArchiveConfirmation(Map<String, dynamic> eleve) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: archiveColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.archive_outlined,
                color: archiveColor,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Archiver l'élève",
              style: TextStyle(
                color: darkColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: archiveColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: archiveColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: archiveColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${eleve['nom']} ${eleve['prenom']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "ID: ${eleve['idEleve']} | ${eleve['niveau']} | Classe: ${eleve['numeroClasse']}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "L'élève sera archivé avec toutes ses données (notes, présences, remarques) et retiré de la liste active.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Cette action peut être annulée en restaurant l'élève depuis l'archive.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              "Annuler",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: archiveColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: Icon(Icons.archive_outlined, size: 18),
            label: Text(
              "Archiver",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _archiveEleve(eleve);
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _archiveEleve(Map<String, dynamic> eleve) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(archiveColor),
            ),
            SizedBox(height: 16),
            Text(
              "Archivage en cours...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Veuillez patienter",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      print("🔄 Starting archive process for student: ${eleve['idEleve']}");
      
      // 1. Get the student document
      DocumentSnapshot eleveDoc = await _db.collection('eleves').doc(eleve['idEleve']).get();
      
      if (!eleveDoc.exists) {
        throw Exception("Document élève introuvable");
      }
      
      print("✅ Student document found, proceeding with archive...");
      
      // 2. Create archive document with all student data and timestamp
      Map<String, dynamic> archiveData = {
        ...eleveDoc.data() as Map<String, dynamic>,
        'archivedAt': FieldValue.serverTimestamp(),
        'originalId': eleve['idEleve'],
        'archiveReason': 'Manual archive by user',
      };
      
      // 3. Add to archive collection
      await _db.collection('ARCHIVE_ELEVES').add(archiveData);
      print("✅ Student added to archive collection");
      
      // 4. Delete from original collection
      await _db.collection('eleves').doc(eleve['idEleve']).delete();
      print("✅ Student removed from active collection");
      
      // 5. Remove from class if exists
      if (eleve['classeId'] != null && eleve['classeId'].toString().isNotEmpty) {
        try {
          await _db.collection('classes').doc(eleve['classeId']).update({
            "eleves.${eleve['idEleve']}": FieldValue.delete()
          });
          print("✅ Student removed from class");
        } catch (classError) {
          print("⚠️ Warning: Could not remove from class: $classError");
          // Continue execution, this is not critical
        }
      }
      
      // 6. Batch archive references in other collections
      WriteBatch batch = _db.batch();
      int archivedCount = 0;
      
      // Archive remarques
      try {
        QuerySnapshot remarquesSnapshot = await _db
            .collection('remarques')
            .where("eleve", isEqualTo: eleve['idEleve'])
            .get();
            
        for (var doc in remarquesSnapshot.docs) {
          // Add to archive with student reference
          await _db.collection('ARCHIVE_REMARQUES').add({
            ...doc.data() as Map<String, dynamic>,
            'archivedAt': FieldValue.serverTimestamp(),
            'originalId': doc.id,
            'eleveArchivedId': eleve['idEleve'],
          });
          batch.delete(doc.reference);
          archivedCount++;
        }
        print("✅ Archived ${remarquesSnapshot.docs.length} remarques");
      } catch (e) {
        print("⚠️ Warning: Error archiving remarques: $e");
      }
      
      // Archive attendance
      try {
        QuerySnapshot attendanceSnapshot = await _db
            .collection('attendance')
            .where("eleveId", isEqualTo: eleve['idEleve'])
            .get();
            
        for (var doc in attendanceSnapshot.docs) {
          await _db.collection('ARCHIVE_ATTENDANCE').add({
            ...doc.data() as Map<String, dynamic>,
            'archivedAt': FieldValue.serverTimestamp(),
            'originalId': doc.id,
            'eleveArchivedId': eleve['idEleve'],
          });
          batch.delete(doc.reference);
          archivedCount++;
        }
        print("✅ Archived ${attendanceSnapshot.docs.length} attendance records");
      } catch (e) {
        print("⚠️ Warning: Error archiving attendance: $e");
      }
      
      // Archive results
      try {
        QuerySnapshot resultsSnapshot = await _db
            .collection('results')
            .where("eleveId", isEqualTo: eleve['idEleve'])
            .get();
            
        for (var doc in resultsSnapshot.docs) {
          await _db.collection('ARCHIVE_RESULTS').add({
            ...doc.data() as Map<String, dynamic>,
            'archivedAt': FieldValue.serverTimestamp(),
            'originalId': doc.id,
            'eleveArchivedId': eleve['idEleve'],
          });
          batch.delete(doc.reference);
          archivedCount++;
        }
        print("✅ Archived ${resultsSnapshot.docs.length} results");
      } catch (e) {
        print("⚠️ Warning: Error archiving results: $e");
      }
      
      // Commit batch operations
      await batch.commit();
      print("✅ All related data archived successfully");
      
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Refresh the list automatically
      await _fetchEleves();
      print("✅ Student list refreshed");
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${eleve['nom']} ${eleve['prenom']} archivé avec succès!",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (archivedCount > 0)
                    Text(
                      "$archivedCount données associées archivées",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: greenColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 4),
        margin: EdgeInsets.all(16),
      ));
      
      print("🎉 Archive process completed successfully!");
      
    } catch (e) {
      print("❌ Error during archive process: $e");
      
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Erreur lors de l'archivage",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "Veuillez réessayer plus tard",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 5),
        margin: EdgeInsets.all(16),
        action: SnackBarAction(
          label: "Détails",
          textColor: Colors.white,
          onPressed: () {
            print("Error details: $e");
          },
        ),
      ));
    }
  }
}