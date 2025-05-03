import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '/services/archive_service.dart';

class ArchivedClassesScreen extends StatefulWidget {
  @override
  _ArchivedClassesScreenState createState() => _ArchivedClassesScreenState();
}

class _ArchivedClassesScreenState extends State<ArchivedClassesScreen> {
  final ArchiveService _archiveService = ArchiveService();
  bool isLoading = true;
  List<Map<String, dynamic>> archivedClasses = [];

  @override
  void initState() {
    super.initState();
    _loadArchivedClasses();
  }

  Future<void> _loadArchivedClasses() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Utiliser "classes" au lieu de "classe" pour être cohérent
      List<Map<String, dynamic>> fetchedClasses = await _archiveService.getArchivedItems('classes');
      
      setState(() {
        archivedClasses = fetchedClasses;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur lors du chargement des classes archivées: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur lors du chargement des classes archivées"), backgroundColor: Colors.red),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _restoreClass(String archiveId) async {
    try {
      // Utiliser "classes" au lieu de "classe"
      await _archiveService.restoreItem(archiveId, 'classes');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Classe restaurée avec succès"), backgroundColor: Colors.green),
      );
      
      _loadArchivedClasses();
    } catch (e) {
      print("❌ Erreur lors de la restauration de la classe: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur lors de la restauration de la classe: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _permanentlyDeleteClass(String archiveId) async {
    try {
      await _archiveService.permanentlyDeleteArchivedItem(archiveId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Classe supprimée définitivement"), backgroundColor: Colors.green),
      );
      
      _loadArchivedClasses();
    } catch (e) {
      print("❌ Erreur lors de la suppression définitive de la classe: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur lors de la suppression de la classe"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text("Classes Archivées"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadArchivedClasses,
          ),
        ],
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : archivedClasses.isEmpty
          ? Center(child: Text("Aucune classe archivée"))
          : ListView.builder(
              itemCount: archivedClasses.length,
              itemBuilder: (context, index) {
                final archivedClass = archivedClasses[index];
                final classData = archivedClass['data'];
                final deletedDate = archivedClass['deletedTimestamp'];
                final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(deletedDate);
                
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  elevation: 3,
                  child: ExpansionTile(
                    title: Text(
                      "Classe: ${classData['numeroClasse']}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Archivée le: $formattedDate",
                      style: TextStyle(color: Colors.grey),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ID: ${classData['idClasse']}"),
                            Text("Année scolaire: ${classData['anneeScolaire']}"),
                            Text("Niveaux: ${classData['niveauxEtude'].join(', ')}"),
                            Text("Archivée par: ${archivedClass['deletedBy'] ?? 'Non spécifié'}"),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  icon: Icon(Icons.restore),
                                  label: Text("Restaurer"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _showRestoreConfirmation(archivedClass['id']),
                                ),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.delete_forever),
                                  label: Text("Supprimer"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _showPermanentDeleteConfirmation(archivedClass['id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showRestoreConfirmation(String archiveId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmer la restauration"),
          content: Text("Voulez-vous restaurer cette classe?"),
          actions: [
            TextButton(
              child: Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Restaurer", style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
                _restoreClass(archiveId);
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermanentDeleteConfirmation(String archiveId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmer la suppression permanente"),
          content: Text("Voulez-vous supprimer définitivement cette classe? Cette action est irréversible."),
          actions: [
            TextButton(
              child: Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Supprimer", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _permanentlyDeleteClass(archiveId);
              },
            ),
          ],
        );
      },
    );
  }
}