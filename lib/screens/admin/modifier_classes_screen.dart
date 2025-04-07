import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ModifierClassesScreen extends StatefulWidget {
  @override
  _ModifierClassesScreenState createState() => _ModifierClassesScreenState();
}

class _ModifierClassesScreenState extends State<ModifierClassesScreen> {
  String? selectedYear;
  String? selectedLevel;
  final TextEditingController searchController = TextEditingController();
  StreamController<void> filterStreamController =
      StreamController<void>.broadcast();

  final List<String> schoolYears = [
    "2023-2024",
    "2024-2025",
    "2025-2026",
    "2026-2027",
    "2027-2028"
  ];

  final List<String> levels = [
    "1ère année",
    "2ème année",
    "3ème année",
    "4ème année",
    "5ème année",
    "6ème année"
  ];

  @override
  void dispose() {
    filterStreamController.close();
    searchController.dispose();
    super.dispose();
  }

  void _updateFilters() {
    filterStreamController.add(null);
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> classe) {
    TextEditingController numeroClasseController =
        TextEditingController(text: classe["numeroClasse"]);
    String selectedAnneeScolaire = classe["anneeScolaire"];
    String selectedNiveauEtude = classe["niveauxEtude"];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Modifier la Classe",
              style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numeroClasseController,
                  decoration: InputDecoration(
                    labelText: "Numéro de Classe",
                    labelStyle: TextStyle(color: Colors.green[700]),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedAnneeScolaire,
                  decoration: InputDecoration(
                    labelText: "Année Scolaire",
                    labelStyle: TextStyle(color: Colors.green[700]),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                    ),
                  ),
                  dropdownColor: Colors.green[50],
                  items: schoolYears.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year,
                          style: TextStyle(color: Colors.green[800])),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedAnneeScolaire = value!;
                  },
                ),
                SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedNiveauEtude,
                  decoration: InputDecoration(
                    labelText: "Niveaux d'Étude",
                    labelStyle: TextStyle(color: Colors.green[700]),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                    ),
                  ),
                  dropdownColor: Colors.green[50],
                  items: levels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level,
                          style: TextStyle(color: Colors.green[800])),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedNiveauEtude = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Annuler",
                  style: TextStyle(color: Colors.red, fontSize: 16)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Enregistrer",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () {
                _updateClassData(
                    classe["idClasse"],
                    numeroClasseController.text,
                    selectedAnneeScolaire,
                    selectedNiveauEtude);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateClassData(String idClasse, String numeroClasse,
      String anneeScolaire, String niveauEtude) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('classes').doc(idClasse).update({
      "numeroClasse": numeroClasse,
      "anneeScolaire": anneeScolaire,
      "niveauxEtude": niveauEtude,
      "profs": {},
      "eleves": {},
    });

    await _updateRelatedDocs(
        firestore, 'profs', idClasse, anneeScolaire, niveauEtude);

    await _updateRelatedDocs(
        firestore, 'eleves', idClasse, anneeScolaire, niveauEtude);
  }

  Future<void> _updateRelatedDocs(
      FirebaseFirestore firestore,
      String collection,
      String idClasse,
      String anneeScolaire,
      String niveauEtude) async {
    QuerySnapshot snapshot = await firestore
        .collection(collection)
        .where("classId", isEqualTo: idClasse)
        .get();

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (data["niveau"] != niveauEtude ||
          data["anneeScolaire"] != anneeScolaire) {
        await firestore.collection(collection).doc(doc.id).update({
          "classId": null,
          "niveau": null,
          "anneeScolaire": null,
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      selectedYear = null;
      selectedLevel = null;
      searchController.clear();
      _updateFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Text("Modifier Classes",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: 26),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtre Année Scolaire
            _buildFilterDropdown(
              value: selectedYear,
              hint: "Sélectionner l'année scolaire",
              items: schoolYears,
              onChanged: (value) {
                setState(() {
                  selectedYear = value;
                  _updateFilters();
                });
              },
              onClear: () {
                setState(() {
                  selectedYear = null;
                  _updateFilters();
                });
              },
            ),
            SizedBox(height: 12),

            // Filtre Niveau d'Étude
            _buildFilterDropdown(
              value: selectedLevel,
              hint: "Sélectionner le niveau d'étude",
              items: levels,
              onChanged: (value) {
                setState(() {
                  selectedLevel = value;
                  _updateFilters();
                });
              },
              onClear: () {
                setState(() {
                  selectedLevel = null;
                  _updateFilters();
                });
              },
            ),
            SizedBox(height: 12),

            // Barre de recherche
            _buildSearchBar(),
            SizedBox(height: 20),

            // Liste des classes
            Expanded(
              child: StreamBuilder<void>(
                stream: filterStreamController.stream,
                builder: (context, _) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _fetchClasses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                            child: CircularProgressIndicator(
                                color: Colors.green[700]));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.class_, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                "Aucune classe trouvée",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      }

                      final classesList = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return {
                          "idClasse": data["idClasse"],
                          "numeroClasse": data["numeroClasse"],
                          "niveauxEtude": data["niveauxEtude"] is List
                              ? (data["niveauxEtude"] as List).join(", ")
                              : data["niveauxEtude"],
                          "anneeScolaire": data["anneeScolaire"],
                          "profs":
                              data.containsKey("profs") && data["profs"] != null
                                  ? (data["profs"] as Map).keys.toList()
                                  : ["Aucun prof"],
                        };
                      }).toList();

                      return ListView.builder(
                        itemCount: classesList.length,
                        itemBuilder: (context, index) {
                          final classe = classesList[index];
                          return _buildClassCard(classe);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[700]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green[100]!,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                labelText: hint,
                labelStyle: TextStyle(color: Colors.green[700]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: value != null
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20, color: Colors.red),
                        onPressed: onClear,
                      )
                    : null,
              ),
              dropdownColor: Colors.green[50],
              icon: Icon(Icons.arrow_drop_down, color: Colors.green[700]),
              style: TextStyle(color: Colors.green[800], fontSize: 16),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[700]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green[100]!,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Rechercher par ID ou Numéro",
          labelStyle: TextStyle(color: Colors.green[700]),
          prefixIcon: Icon(Icons.search, color: Colors.green[700]),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      _updateFilters();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) => _updateFilters(),
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classe) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditDialog(context, classe),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Classe ${classe["numeroClasse"]}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Text(
                      "ID: ${classe["idClasse"]}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              _buildInfoRow(Icons.calendar_today, "Année:", classe["anneeScolaire"]),
              _buildInfoRow(Icons.school, "Niveau:", classe["niveauxEtude"]),
              _buildInfoRow(
                Icons.people,
                "Professeurs:",
                classe["profs"].join(", "),
                isLast: true,
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.green[700]),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: "$label ",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _fetchClasses() {
    Query query = FirebaseFirestore.instance.collection('classes');

    if (selectedYear != null) {
      query = query.where("anneeScolaire", isEqualTo: selectedYear);
    }

    if (selectedLevel != null) {
      query = query.where("niveauxEtude", arrayContains: selectedLevel);
    }

    if (searchController.text.isNotEmpty) {
      String searchQuery = searchController.text.trim();

      query = query.where(Filter.or(
        Filter("numeroClasse", isEqualTo: searchQuery),
        Filter("idClasse", isEqualTo: searchQuery),
      ));
    }

    return query.snapshots();
  }
}