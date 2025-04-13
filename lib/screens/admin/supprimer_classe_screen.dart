import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupprimerClasseScreen extends StatefulWidget {
  @override
  _SupprimerClasseScreenState createState() => _SupprimerClasseScreenState();
}

class _SupprimerClasseScreenState extends State<SupprimerClasseScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> classesFiltered = [];
  bool isLoading = true;
  String? selectedClassId;
  Map<String, dynamic>? selectedClass;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await _db.collection('classes')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> loadedClasses = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        loadedClasses.add(data);
      }

      setState(() {
        classes = loadedClasses;
        classesFiltered = loadedClasses;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur lors du chargement des classes: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Échec du chargement des classes! Veuillez réessayer."), backgroundColor: Colors.red),
      );
    }
  }

  void _searchClasses(String query) {
    if (query.isEmpty) {
      setState(() {
        classesFiltered = classes;
      });
      return;
    }

    setState(() {
      classesFiltered = classes.where((classe) {
        return classe['numeroClasse'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _selectClass(String classId) {
    Map<String, dynamic>? foundClass = classes.firstWhere(
      (cls) => cls['idClasse'] == classId,
      orElse: () => {},
    );

    setState(() {
      selectedClassId = classId;
      selectedClass = foundClass.isNotEmpty ? foundClass : null;
    });
  }

  Future<void> _deleteClass() async {
    if (selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Veuillez sélectionner une classe à supprimer!"), backgroundColor: Colors.orange),
      );
      return;
    }

    // Afficher la confirmation de suppression
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmation de suppression"),
        content: Text("Êtes-vous sûr de vouloir supprimer cette classe? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmDelete) return;

    try {
      await _db.collection('classes').doc(selectedClassId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Classe supprimée avec succès!"), backgroundColor: Colors.green),
      );

      // Recharger la liste après la suppression
      _loadClasses();
      
      // Réinitialiser la sélection
      setState(() {
        selectedClassId = null;
        selectedClass = null;
      });
    } catch (e) {
      print("❌ Erreur lors de la suppression: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Échec de la suppression de la classe! Veuillez réessayer."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text("Supprimer une classe"),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section de recherche par numéro de classe
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Rechercher par numéro de classe",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: _searchClasses,
                  ),
                ),

                // Liste des classes disponibles
                Text(
                  "Liste des classes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                
                Expanded(
                  child: classesFiltered.isEmpty
                    ? Center(
                        child: Text(
                          "Aucune classe disponible",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: classesFiltered.length,
                        itemBuilder: (context, index) {
                          final classData = classesFiltered[index];
                          final bool isSelected = selectedClassId == classData['idClasse'];
                          
                          return Card(
                            elevation: isSelected ? 5 : 1,
                            margin: EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? Colors.red : Colors.transparent,
                                width: isSelected ? 2 : 0,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                "Classe ${classData['numeroClasse']}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("ID: ${classData['idClasse']}"),
                                  Text("Année scolaire: ${classData['anneeScolaire'] ?? 'N/A'}"),
                                  Text("Niveaux: ${(classData['niveauxEtude'] as List<dynamic>).join(', ')}"),
                                ],
                              ),
                              trailing: Radio<String>(
                                value: classData['idClasse'],
                                groupValue: selectedClassId,
                                activeColor: Colors.red,
                                onChanged: (value) => _selectClass(value!),
                              ),
                              onTap: () => _selectClass(classData['idClasse']),
                            ),
                          );
                        },
                      ),
                ),
                
                SizedBox(height: 20),
                
                // Informations sur la classe sélectionnée
                if (selectedClass != null) ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 235, 235),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Classe sélectionnée",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text("ID: ${selectedClass!['idClasse']}"),
                        Text("Numéro: ${selectedClass!['numeroClasse']}"),
                        Text("Année scolaire: ${selectedClass!['anneeScolaire'] ?? 'N/A'}"),
                        Text("Niveaux d'étude: ${(selectedClass!['niveauxEtude'] as List<dynamic>).join(', ')}"),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
                
                // Bouton de suppression
                ElevatedButton.icon(
                  onPressed: selectedClassId != null ? _deleteClass : null,
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text("Supprimer la classe", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                
                SizedBox(height: 10),
                
                // Bouton d'actualisation
                OutlinedButton.icon(
                  onPressed: _loadClasses,
                  icon: Icon(Icons.refresh),
                  label: Text("Actualiser la liste"),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}