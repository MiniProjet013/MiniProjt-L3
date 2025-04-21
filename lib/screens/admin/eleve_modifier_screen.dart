import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'modifier_eleve_detail_screen.dart'; // Importamos la pantalla de modificación detallada

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
      
      // Aplicar filtros si están seleccionados
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
      
      // Filtrar por búsqueda si hay una consulta
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
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text("Modifier les élèves"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchEleves,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher par nom ou ID",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                _fetchEleves();
              },
            ),
          ),
          
          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Niveau",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
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
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Classe",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filterClasse = value.isEmpty ? null : value;
                      });
                      _fetchEleves();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 10),
          
          // Lista de alumnos
          Expanded(
            child: isLoading 
              ? Center(child: CircularProgressIndicator())
              : eleves.isEmpty 
                ? Center(
                    child: Text(
                      "Aucun élève trouvé",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    itemCount: eleves.length,
                    itemBuilder: (context, index) {
                      final eleve = eleves[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            "${eleve['nom']} ${eleve['prenom']}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "ID: ${eleve['idEleve']} | ${eleve['niveau']} | Classe: ${eleve['numeroClasse']}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ModifierEleveScreen(eleveId: eleve['idEleve']),
                                    ),
                                  );
                                  
                                  // Si se modificó con éxito, actualizamos la lista
                                  if (result == true) {
                                    _fetchEleves();
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmation(eleve);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(Map<String, dynamic> eleve) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmation"),
        content: Text("Voulez-vous vraiment supprimer l'élève ${eleve['nom']} ${eleve['prenom']}?"),
        actions: [
          TextButton(
            child: Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
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
      // 1. Eliminar de la colección de estudiantes
      await _db.collection('eleves').doc(eleve['idEleve']).delete();
      
      // 2. Eliminar de la clase si existe
      if (eleve['classeId'] != null) {
        await _db.collection('classes').doc(eleve['classeId']).update({
          "eleves.${eleve['idEleve']}": FieldValue.delete()
        });
      }
      
      // 3. Buscar y eliminar referencias en otras colecciones
      WriteBatch batch = _db.batch();
      
      // Eliminar de remarques
      QuerySnapshot remarquesSnapshot = await _db
          .collection('remarques')
          .where("eleve", isEqualTo: eleve['idEleve'])
          .get();
          
      for (var doc in remarquesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Eliminar de attendance
      QuerySnapshot attendanceSnapshot = await _db
          .collection('attendance')
          .where("eleveId", isEqualTo: eleve['idEleve'])
          .get();
          
      for (var doc in attendanceSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Eliminar de results
      QuerySnapshot resultsSnapshot = await _db
          .collection('results')
          .where("eleveId", isEqualTo: eleve['idEleve'])
          .get();
          
      for (var doc in resultsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Actualizar la lista
      _fetchEleves();
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Élève supprimé avec succès!"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print("❌ Error deleting eleve: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Erreur lors de la suppression de l'élève!"),
        backgroundColor: Colors.red,
      ));
    }
  }
}