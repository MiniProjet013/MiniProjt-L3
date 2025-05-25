import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';

class ArchivedClassesScreen extends StatefulWidget {
  @override
  _ArchivedClassesScreenState createState() => _ArchivedClassesScreenState();
}

class _ArchivedClassesScreenState extends State<ArchivedClassesScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> archivedClasses = [];
  String? selectedYear;

  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  // liste des années scolaires disponibles
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
    _loadArchivedClasses();
  }

  Future<void> _loadArchivedClasses() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot;
      
      if (selectedYear != null && selectedYear != "Tous") {
        snapshot = await _db.collection('archives_classes')
            .where('anneeScolaire', isEqualTo: selectedYear)
            .orderBy('archivedAt', descending: true)
            .get();
      } else {
        snapshot = await _db.collection('archives_classes')
            .orderBy('archivedAt', descending: true)
            .get();
      }

      List<Map<String, dynamic>> loadedClasses = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        loadedClasses.add({
          'id': doc.id,
          'originalId': data['originalId'] ?? doc.id,
          'idClasse': data['idClasse'] ?? '',
          'numeroClasse': data['numeroClasse'] ?? '',
          'anneeScolaire': data['anneeScolaire'] ?? '',
          'niveauxEtude': data['niveauxEtude'] is List 
              ? List<String>.from(data['niveauxEtude']) 
              : <String>[],
          'archivedAt': data['archivedAt']?.toDate() ?? DateTime.now(),
          'archivedBy': data['archivedBy'] ?? 'system',
          'archivedReason': data['archivedReason'] ?? 'Suppression manuelle',
          'timestamp': data['timestamp']?.toDate(),
        });
      }

      setState(() {
        archivedClasses = loadedClasses;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur lors du chargement des classes archivées: $e");
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Erreur lors du chargement des classes archivées!"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _restoreClass(Map<String, dynamic> classData) async {
    try {
      // 1. Restaurer la classe dans la collection principale
      Map<String, dynamic> restoredData = {
        'idClasse': classData['idClasse'],
        'numeroClasse': classData['numeroClasse'],
        'anneeScolaire': classData['anneeScolaire'],
        'niveauxEtude': classData['niveauxEtude'],
        'timestamp': FieldValue.serverTimestamp(),
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredFrom': classData['id'],
      };

      await _db.collection('classes').add(restoredData);
      
      // 2. Supprimer de l'archive
      await _db.collection('archives_classes').doc(classData['id']).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Classe restaurée avec succès!"),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadArchivedClasses();
    } catch (e) {
      print("❌ Erreur lors de la restauration: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la restauration: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _permanentlyDeleteClass(String archiveId) async {
    try {
      await _db.collection('archives_classes').doc(archiveId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Classe supprimée définitivement!"),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadArchivedClasses();
    } catch (e) {
      print("❌ Erreur lors de la suppression définitive: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la suppression définitive!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // En-tête avec gradient (même style que ModifierClassesScreen)
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
                          'Classes Archivées',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gérer les classes archivées (${archivedClasses.length})',
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
                onPressed: _loadArchivedClasses,
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
                      _loadArchivedClasses();
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Liste des classes archivées
          isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                    ),
                  ),
                )
              : archivedClasses.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.archive_outlined, size: 60, color: Colors.grey.shade400),
                            SizedBox(height: 16),
                            Text(
                              "Aucune classe archivée",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Les classes supprimées apparaîtront ici",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
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
                            final classData = archivedClasses[index];
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
                                                          color: Colors.red.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.archive_outlined, size: 12, color: Colors.red),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              "ARCHIVÉE",
                                                              style: TextStyle(
                                                                color: Colors.red,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
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
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "Archivée le: ${_formatDate(classData['archivedAt'])}",
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Boutons d'action
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                // Bouton de restauration
                                                Container(
                                                  height: 36,
                                                  width: 36,
                                                  margin: EdgeInsets.only(bottom: 8),
                                                  decoration: BoxDecoration(
                                                    color: greenColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    icon: Icon(Icons.restore, size: 18, color: greenColor),
                                                    onPressed: () => _showRestoreConfirmation(classData),
                                                  ),
                                                ),
                                                // Bouton de suppression définitive
                                                Container(
                                                  height: 36,
                                                  width: 36,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    icon: Icon(Icons.delete_forever, size: 18, color: Colors.red),
                                                    onPressed: () => _showPermanentDeleteConfirmation(classData),
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
                          childCount: archivedClasses.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  void _showRestoreConfirmation(Map<String, dynamic> classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Restaurer la classe",
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
                color: greenColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.restore,
                color: greenColor,
                size: 50,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Voulez-vous restaurer la classe ${classData['numeroClasse']}?",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Elle sera ajoutée à nouveau dans la liste des classes actives.",
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
              backgroundColor: greenColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Restaurer",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.pop(context);
              _restoreClass(classData);
            },
          ),
        ],
      ),
    );
  }

  void _showPermanentDeleteConfirmation(Map<String, dynamic> classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Suppression définitive",
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
              "Supprimer définitivement la classe ${classData['numeroClasse']}?",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "⚠️ Cette action est irréversible!\nToutes les données seront perdues définitivement.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w500,
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
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Supprimer définitivement",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.pop(context);
              _permanentlyDeleteClass(classData['id']);
            },
          ),
        ],
      ),
    );
  }
}