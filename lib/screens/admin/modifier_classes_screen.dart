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
          title: Text("Modifier la Classe"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numeroClasseController,
                decoration: InputDecoration(labelText: "Numéro de Classe"),
              ),
              SizedBox(height: 10),

              // ✅ قائمة اختيار السنة الدراسية
              DropdownButtonFormField<String>(
                value: selectedAnneeScolaire,
                decoration: InputDecoration(labelText: "Année Scolaire"),
                items: schoolYears.map((year) {
                  return DropdownMenuItem(value: year, child: Text(year));
                }).toList(),
                onChanged: (value) {
                  selectedAnneeScolaire = value!;
                },
              ),
              SizedBox(height: 10),

              // ✅ قائمة اختيار المستوى الدراسي
              DropdownButtonFormField<String>(
                value: selectedNiveauEtude,
                decoration: InputDecoration(labelText: "Niveaux d'Étude"),
                items: levels.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) {
                  selectedNiveauEtude = value!;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Annuler"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text("Enregistrer"),
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

    // تحديث بيانات القسم في Firestore
    await firestore.collection('classes').doc(idClasse).update({
      "numeroClasse": numeroClasse,
      "anneeScolaire": anneeScolaire,
      "niveauxEtude": niveauEtude,
      "profs": {}, // 🛑 مسح جميع الأساتذة المرتبطين
      "eleves": {}, // 🛑 مسح جميع التلاميذ المرتبطين
    });

    // تحديث بيانات الأساتذة المرتبطين بهذا القسم
    await _updateRelatedDocs(
        firestore, 'profs', idClasse, anneeScolaire, niveauEtude);

    // تحديث بيانات التلاميذ المرتبطين بهذا القسم
    await _updateRelatedDocs(
        firestore, 'eleves', idClasse, anneeScolaire, niveauEtude);

    print("✅ تم تحديث القسم والتأكد من توافق الأساتذة والتلاميذ!");
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
          "classId": null, // إزالة القسم
          "niveau": null,
          "anneeScolaire": null,
        });
      }
    }
  }

  /// ✅ مسح جميع الفلاتر وإعادة تحميل البيانات
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
        backgroundColor: const Color.fromARGB(255, 41, 247, 0),
        title: Text("Modifier Classes"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearFilters, // ✅ زر إعادة تعيين كل الحقول
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ اختيار السنة الدراسية مع زر المسح
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                        labelText: "Sélectionner l'année scolaire",
                        border: OutlineInputBorder()),
                    value: selectedYear,
                    items: schoolYears.map((year) {
                      return DropdownMenuItem(value: year, child: Text(year));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value;
                        _updateFilters();
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      selectedYear = null;
                      _updateFilters();
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),

            // ✅ اختيار المستوى الدراسي مع زر المسح
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                        labelText: "Sélectionner le niveau d'étude",
                        border: OutlineInputBorder()),
                    value: selectedLevel,
                    items: levels.map((level) {
                      return DropdownMenuItem(value: level, child: Text(level));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLevel = value;
                        _updateFilters();
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      selectedLevel = null;
                      _updateFilters();
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),

            // ✅ البحث عن القسم مع زر المسح
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Rechercher par ID ou Numéro",
                      suffixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateFilters();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      _updateFilters();
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),

            // ✅ عرض الأقسام من Firestore
            Expanded(
              child: StreamBuilder<void>(
                stream: filterStreamController.stream,
                builder: (context, _) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _fetchClasses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "Aucun classe trouvé",
                            style: TextStyle(fontSize: 18, color: Colors.red),
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
                              : data[
                                  "niveauxEtude"], // إذا كان نصًا، يُستخدم كما هو

                          "anneeScolaire": data["anneeScolaire"],
                          "profs":
                              data.containsKey("profs") && data["profs"] != null
                                  ? (data["profs"] as Map).keys.toList()
                                  : [
                                      "Aucun prof"
                                    ], // ✅ إذا لم يوجد أستاذ، يظهر "Aucun prof"
                        };
                      }).toList();

                      return ListView.builder(
                        itemCount: classesList.length,
                        itemBuilder: (context, index) {
                          final classe = classesList[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text("Classe: ${classe["numeroClasse"]}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("ID: ${classe["idClasse"]}"),
                                  Text("Niveau: ${classe["niveauxEtude"]}"),
                                  Text("Année: ${classe["anneeScolaire"]}"),
                                  Text("Profs: ${classe["profs"].join(", ")}"),
                                ],
                              ),
                              trailing: Icon(Icons.edit, color: Colors.orange),
                              onTap: () {
                                _showEditDialog(context, classe);
                              },
                            ),
                          );
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

  // ✅ استعلام Firestore مع التحسينات
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
