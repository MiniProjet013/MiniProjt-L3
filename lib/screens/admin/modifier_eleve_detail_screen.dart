import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModifierEleveScreen extends StatefulWidget {
  final String eleveId;

  const ModifierEleveScreen({Key? key, required this.eleveId}) : super(key: key);

  @override
  _ModifierEleveScreenState createState() => _ModifierEleveScreenState();
}

class _ModifierEleveScreenState extends State<ModifierEleveScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  
  String? selectedDate;
  String? selectedLevel;
  String? selectedYear;
  String? originalClassId;
  Map<String, dynamic>? selectedClass;
  List<Map<String, dynamic>> availableClasses = [];
  bool isLoading = true;
  bool classChanged = false;
  
  // Las mismas listas de la interfaz original
  final List<String> levels = [
    "1ère année", "2ème année", "3ème année",
    "4ème année", "5ème année", "6ème année"
  ];
  
  final List<String> schoolYears = [
    "2023-2024", "2024-2025", "2025-2026",
    "2026-2027", "2027-2028"
  ];

  @override
  void initState() {
    super.initState();
    _loadEleveData();
  }

  Future<void> _loadEleveData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      DocumentSnapshot eleveDoc = await _db.collection('eleves').doc(widget.eleveId).get();
      
      if (eleveDoc.exists) {
        Map<String, dynamic> data = eleveDoc.data() as Map<String, dynamic>;
        
        setState(() {
          nameController.text = data['nom'] ?? '';
          surnameController.text = data['prenom'] ?? '';
          idController.text = data['idEleve'] ?? widget.eleveId;
          selectedDate = data['dateNaissance'];
          selectedLevel = data['niveau'];
          selectedYear = data['anneeScolaire'];
          originalClassId = data['classeId'];
          
          // Determinar la clase actual
          if (data['classeId'] != null && data['numeroClasse'] != null) {
            selectedClass = {
              "idClasse": data['classeId'],
              "numeroClasse": data['numeroClasse'],
            };
          }
        });
        
        // Obtener clases disponibles después de definir nivel y año
        await _fetchClassesForSelectedLevelAndYear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("⚠️ Données de l'élève non trouvées!"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des données: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Erreur lors du chargement des données!"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchClassesForSelectedLevelAndYear() async {
    if (selectedLevel == null || selectedYear == null) {
      setState(() {
        availableClasses = [];
      });
      return;
    }
    
    try {
      QuerySnapshot snapshot = await _db
          .collection('classes')
          .where("niveauxEtude", arrayContains: selectedLevel)
          .where("anneeScolaire", isEqualTo: selectedYear)
          .get();
          
      List<Map<String, dynamic>> classes = snapshot.docs.map((doc) {
        return {
          "idClasse": doc.id,
          "numeroClasse": doc["numeroClasse"],
        };
      }).toList();
      
      setState(() {
        availableClasses = classes;
        
        // Si la clase seleccionada no está en la nueva lista, desactivamos la selección
        if (selectedClass != null) {
          bool classExists = availableClasses.any((c) => c["idClasse"] == selectedClass!["idClasse"]);
          if (!classExists) {
            selectedClass = null;
          }
        }
      });
    } catch (e) {
      print("❌ Erreur lors du chargement des classes: $e");
    }
  }
  
  Future<void> _updateEleve() async {
    String idEleve = idController.text.trim();
    String name = nameController.text.trim();
    String surname = surnameController.text.trim();
    
    if (name.isEmpty || surname.isEmpty || selectedDate == null ||
        selectedLevel == null || selectedYear == null || selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("⚠️ Veuillez remplir tous les champs!"),
        backgroundColor: Colors.red,
      ));
      return;
    }
    
    try {
      // 1. Actualizar datos del alumno en la colección eleves
      Map<String, dynamic> eleveData = {
        "idEleve": idEleve,
        "nom": name,
        "prenom": surname,
        "dateNaissance": selectedDate,
        "niveau": selectedLevel,
        "anneeScolaire": selectedYear,
        "classeId": selectedClass!["idClasse"],
        "numeroClasse": selectedClass!["numeroClasse"],
      };
      
      await _db.collection('eleves').doc(idEleve).update(eleveData);

      // 2. Si se cambió la clase, eliminamos al alumno de la antigua y lo añadimos a la nueva
      if (originalClassId != selectedClass!["idClasse"]) {
        // Eliminar de la clase antigua
        if (originalClassId != null) {
          await _db.collection('classes').doc(originalClassId).update({
            "eleves.${idEleve}": FieldValue.delete()
          });
        }
        
        // Añadir a la nueva clase
        await _db.collection('classes').doc(selectedClass!["idClasse"]).set({
          "eleves": {
            idEleve: {
              "nom": name,
              "prenom": surname,
            }
          }
        }, SetOptions(merge: true));
      } else {
        // Actualizar datos del alumno en la misma clase
        await _db.collection('classes').doc(selectedClass!["idClasse"]).set({
          "eleves": {
            idEleve: {
              "nom": name,
              "prenom": surname,
            }
          }
        }, SetOptions(merge: true));
      }

      // 3. Actualizar datos del alumno en todas las demás colecciones donde aparece
      await _updateEleveInOtherCollections(idEleve, name, surname);
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Données de l'élève modifiées avec succès!"),
        backgroundColor: Colors.green,
      ));
      
      Navigator.pop(context, true); // Volver con señal de éxito
    } catch (e) {
      print("❌ Erreur lors de la modification: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec de la modification des données! Réessayez."),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _updateEleveInOtherCollections(String idEleve, String nom, String prenom) async {
    // Actualizar en la colección de observaciones
    try {
      QuerySnapshot remarquesSnapshot = await _db
          .collection('remarques')
          .where("eleve", isEqualTo: idEleve)
          .get();
          
      WriteBatch batch = _db.batch();
      for (var doc in remarquesSnapshot.docs) {
        batch.update(doc.reference, {
          "nom": nom,
          "prenom": prenom
        });
      }
      
      // Actualizar en la colección de asistencia
      QuerySnapshot attendanceSnapshot = await _db
          .collection('attendance')
          .where("eleveId", isEqualTo: idEleve)
          .get();
          
      for (var doc in attendanceSnapshot.docs) {
        batch.update(doc.reference, {
          "eleveName": nom + " " + prenom
        });
      }
      
      // Actualizar en la colección de resultados
      QuerySnapshot resultsSnapshot = await _db
          .collection('results')
          .where("eleveId", isEqualTo: idEleve)
          .get();
          
      for (var doc in resultsSnapshot.docs) {
        batch.update(doc.reference, {
          "eleveName": nom + " " + prenom
        });
      }
      
      await batch.commit();
    } catch (e) {
      print("⚠️ Erreur lors de la mise à jour des autres collections: $e");
      // Continuamos con el proceso incluso si falla la actualización de colecciones secundarias
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Modifier les données de l'élève"),
      ),
      body: isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Chargement des données...", style: TextStyle(fontSize: 16)),
              ],
            ),
          )
        : Padding(
          padding: EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextField(
                controller: nameController, 
                decoration: InputDecoration(
                  labelText: "Nom", 
                  border: OutlineInputBorder()
                )
              ),
              SizedBox(height: 10),
              TextField(
                controller: surnameController, 
                decoration: InputDecoration(
                  labelText: "Prénom", 
                  border: OutlineInputBorder()
                )
              ),
              SizedBox(height: 10),
              Text("Date de naissance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                decoration: InputDecoration(
                  hintText: "Sélectionner une date",
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                controller: TextEditingController(text: selectedDate),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    });
                  }
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: idController, 
                decoration: InputDecoration(
                  labelText: "ID Élève", 
                  border: OutlineInputBorder()
                ), 
                readOnly: true
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Niveau d'étude", 
                  border: OutlineInputBorder()
                ),
                value: selectedLevel,
                items: levels.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedLevel = value;
                    _fetchClassesForSelectedLevelAndYear();
                  });
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Année scolaire", 
                  border: OutlineInputBorder()
                ),
                value: selectedYear,
                items: schoolYears.map((year) {
                  return DropdownMenuItem(value: year, child: Text(year));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                    _fetchClassesForSelectedLevelAndYear();
                  });
                },
              ),
              SizedBox(height: 10),
              Text("Sélectionner un Classe", style: TextStyle(fontWeight: FontWeight.bold)),
              availableClasses.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("⚠️ Aucune classe disponible pour ce niveau et cette année!",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  )
                : Wrap(
                    spacing: 8.0,
                    children: availableClasses.map((classe) {
                      return ChoiceChip(
                        label: Text("CLASSE ${classe["numeroClasse"]}"),
                        selected: selectedClass != null && selectedClass!["idClasse"] == classe["idClasse"],
                        onSelected: (selected) {
                          setState(() {
                            selectedClass = selected ? classe : selectedClass;
                            if (selected && originalClassId != classe["idClasse"]) {
                              classChanged = true;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateEleve,
                child: Text("Enregistrer les modifications", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
              ),
            ],
          ),
        ),
    );
  }
}