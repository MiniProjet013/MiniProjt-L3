import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ModifierProfsScreen extends StatefulWidget {
  @override
  _ModifierProfsScreenState createState() => _ModifierProfsScreenState();
}

class _ModifierProfsScreenState extends State<ModifierProfsScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  StreamController<bool> filterStreamController =
      StreamController<bool>.broadcast();
  final _formKey = GlobalKey<FormState>();
  List<String> anneesScolaires = [];
  List<int> numerosClasses = [];
  String? selectedAnneeScolaire;
  int? selectedNumeroClasse;

  @override
  void initState() {
    super.initState();
    _generateAnneesScolaires();
    _fetchNumerosClasses();
  }

  void _generateAnneesScolaires() {
    int startYear = 2025;
    int endYear = 2051;
    for (int year = startYear; year < endYear; year++) {
      anneesScolaires.add('$year-${year + 1}');
    }
  }

  Future<void> _fetchNumerosClasses() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .orderBy('numeroClasse')
          .get();

      setState(() {
        numerosClasses = querySnapshot.docs
            .map((doc) => doc.data()['numeroClasse'] as int)
            .toList();
      });
    } catch (e) {
      print('Erreur lors de la récupération des classes: $e');
    }
  }

  @override
  void dispose() {
    filterStreamController.close();
    searchController.dispose();
    super.dispose();
  }

  void _updateFilters() {
    filterStreamController.add(true);
  }

  void _clearFilters() {
    setState(() {
      searchController.clear();
      _updateFilters();
    });
  }

  void _showFullEditDialog(BuildContext context, Map<String, dynamic> prof) {
    final matiereController =
        TextEditingController(text: prof["matiere"] ?? '');
    final nameController = TextEditingController(text: prof["nom"] ?? '');
    final prenomController = TextEditingController(text: prof["prenom"] ?? '');
    final emailController = TextEditingController(text: prof["email"] ?? '');
    final niveauClasseController = TextEditingController(
        text: prof["niveauClasse"] is List
            ? (prof["niveauClasse"] as List).join(', ')
            : prof["niveauClasse"]?.toString() ?? '');

    // Initialiser les valeurs sélectionnées
    selectedAnneeScolaire = prof["anneeScolaire"] ?? '2025-2026';
    selectedNumeroClasse = prof["numeroClasse"] ?? prof["numeroClasses"];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Modification Complète du Professeur",
              style: TextStyle(
                  color: Colors.green[700], fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Nom*",
                      labelStyle: TextStyle(color: Colors.green[700]),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le nom est obligatoire';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: prenomController,
                    decoration: InputDecoration(
                      labelText: "Prénom*",
                      labelStyle: TextStyle(color: Colors.green[700]),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le prénom est obligatoire';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Colors.green[700]),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: matiereController,
                    decoration: InputDecoration(
                      labelText: "Matière*",
                      labelStyle: TextStyle(color: Colors.green[700]),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La matière est obligatoire';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedAnneeScolaire,
                    decoration: InputDecoration(
                      labelText: "Année Scolaire",
                      labelStyle: TextStyle(color: Colors.green[700]),
                    ),
                    items: anneesScolaires.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedAnneeScolaire = newValue;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: niveauClasseController,
                    decoration: InputDecoration(
                      labelText: "Niveau(x) de Classe",
                      labelStyle: TextStyle(color: Colors.green[700]),
                    ),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<int?>(
                    value: selectedNumeroClasse,
                    decoration: InputDecoration(
                      labelText: "Numéro de Classe",
                      labelStyle: TextStyle(color: Colors.green[700]),
                    ),
                    hint: Text('Sélectionnez une classe'),
                    items: numerosClasses.map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('Classe $value'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedNumeroClasse = newValue;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text("Annuler", style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              child:
                  Text("Mettre à jour", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _updateProfessorData(
                    context,
                    prof["idProf"] ?? prof["id"],
                    nameController.text,
                    prenomController.text,
                    emailController.text,
                    matiereController.text,
                    selectedAnneeScolaire!,
                    niveauClasseController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList(),
                    selectedNumeroClasse,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfessorData(
    BuildContext context,
    String idProf,
    String nom,
    String prenom,
    String email,
    String matiere,
    String anneeScolaire,
    List<String> niveauClasse,
    int? numeroClasse,
  ) async {
    setState(() {
      isLoading = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update in profs collection
      final profRef =
          FirebaseFirestore.instance.collection('profs').doc(idProf);
      batch.update(profRef, {
        "nom": nom,
        "prenom": prenom,
        "email": email.isNotEmpty ? email : FieldValue.delete(),
        "matiere": matiere,
        "anneeScolaire": anneeScolaire,
        "niveauClasse": niveauClasse,
        "numeroClasse": numeroClasse,
        "lastUpdated": FieldValue.serverTimestamp(),
        "displayText": "$prenom $nom - $matiere"
      });

      // Update in emplois_profs collection
      final emploisQuery = await FirebaseFirestore.instance
          .collection('emplois_profs')
          .where('prof.id', isEqualTo: idProf)
          .get();

      for (final doc in emploisQuery.docs) {
        batch.update(doc.reference, {
          'prof.nom': nom,
          'prof.prenom': prenom,
          'prof.matiere': matiere,
          'prof.displayText': "$prenom $nom - $matiere",
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // Handle class assignment changes
      await _handleClassAssignmentChanges(batch, idProf, nom, prenom, matiere, numeroClasse);

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "✅ Professeur mis à jour avec succès dans toutes les collections!"),
          backgroundColor: Colors.green[700],
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la mise à jour: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleClassAssignmentChanges(
    WriteBatch batch,
    String idProf,
    String nom,
    String prenom,
    String matiere,
    int? newNumeroClasse,
  ) async {
    // 1. Find all classes where this professor is currently assigned
    final currentClassesQuery = await FirebaseFirestore.instance
        .collection('classes')
        .where('profs', arrayContains: idProf)
        .get();

    // 2. Remove professor from old classes if number changed
    for (final doc in currentClassesQuery.docs) {
      final classData = doc.data();
      final currentClassNumber = classData['numeroClasse'] as int?;
      
      if (currentClassNumber != newNumeroClasse) {
        var profsList = List.from(classData['profs'] ?? []);
        profsList.removeWhere((p) => p is Map ? p['id'] == idProf : p == idProf);
        
        batch.update(doc.reference, {
          'profs': profsList,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }

    // 3. Add professor to new class if number is specified and different
    if (newNumeroClasse != null) {
      final newClassQuery = await FirebaseFirestore.instance
          .collection('classes')
          .where('numeroClasse', isEqualTo: newNumeroClasse)
          .limit(1)
          .get();

      if (newClassQuery.docs.isNotEmpty) {
        final newClassRef = newClassQuery.docs.first.reference;
        final newClassData = newClassQuery.docs.first.data();
        
        var profsList = List.from(newClassData['profs'] ?? []);
        
        // Check if professor is not already in this class
        if (!profsList.any((p) => p is Map ? p['id'] == idProf : p == idProf)) {
          profsList.add({
            'id': idProf,
            'nom': nom,
            'prenom': prenom,
            'matiere': matiere,
          });
          
          batch.update(newClassRef, {
            'profs': profsList,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        labelText: "Rechercher par nom/prénom/matière",
        labelStyle: TextStyle(color: Colors.green[700]),
        prefixIcon: Icon(Icons.search, color: Colors.green[700]),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.clear, color: Colors.red),
                onPressed: _clearFilters,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.green[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.green[700]!, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: (value) => _updateFilters(),
    );
  }

  Widget _buildProfessorCard(Map<String, dynamic> prof, String docId) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.green[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _showFullEditDialog(context, {...prof, "idProf": docId}),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${prof["prenom"]} ${prof["nom"]}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(
                      prof["matiere"] ?? 'Non spécifié',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green[700],
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (prof["email"] != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(prof["email"]),
                    ],
                  ),
                ),
              if (prof["niveauClasse"] != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.school, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(prof["niveauClasse"] is List
                          ? (prof["niveauClasse"] as List).join(', ')
                          : prof["niveauClasse"].toString()),
                    ],
                  ),
                ),
              if (prof["numeroClasse"] != null || prof["numeroClasses"] != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.class_, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                          "Classe: ${prof["numeroClasse"] ?? prof["numeroClasses"]}"),
                    ],
                  ),
                ),
              if (prof["anneeScolaire"] != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text("Année: ${prof["anneeScolaire"]}"),
                    ],
                  ),
                ),
              if (prof["lastUpdated"] != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "Dernière modification: ${_formatTimestamp(prof["lastUpdated"])}",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}";
    } else if (timestamp is String) {
      return timestamp;
    }
    return "Inconnu";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Text("Gestion des Professeurs",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            SizedBox(height: 20),

            Expanded(
              child: Stack(
                children: [
                  StreamBuilder<bool>(
                    stream: filterStreamController.stream,
                    builder: (context, _) {
                      return StreamBuilder<List<QueryDocumentSnapshot>>(
                        stream: _fetchProfs(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return Center(
                                child: CircularProgressIndicator(
                                    color: Colors.green[700]));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    "Aucun professeur trouvé",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                  if (searchController.text.isNotEmpty)
                                    TextButton(
                                      onPressed: _clearFilters,
                                      child: Text("Réinitialiser la recherche"),
                                    ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.data![index];
                              final prof = doc.data() as Map<String, dynamic>;
                              return _buildProfessorCard(prof, doc.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text("Mise à jour en cours...",
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<QueryDocumentSnapshot>> _fetchProfs() {
    Query query = FirebaseFirestore.instance.collection('profs').orderBy("nom");

    if (searchController.text.isNotEmpty) {
      String searchText = searchController.text.toLowerCase();
      return query.snapshots().map((snapshot) {
        return snapshot.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String nom = (data['nom'] ?? '').toLowerCase();
          String prenom = (data['prenom'] ?? '').toLowerCase();
          String matiere = (data['matiere'] ?? '').toLowerCase();
          return nom.contains(searchText) ||
              prenom.contains(searchText) ||
              matiere.contains(searchText);
        }).toList();
      });
    }

    return query.snapshots().map((snapshot) => snapshot.docs);
  }
}