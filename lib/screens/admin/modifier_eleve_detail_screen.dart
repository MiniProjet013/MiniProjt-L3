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
  
  // Colors to match the ModifierScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);
  
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
        backgroundColor: greenColor,
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

  // Custom input field to maintain consistent design
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    Icon? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor.withOpacity(0.7),
              ),
            ),
            TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              style: TextStyle(
                fontSize: 16,
                color: darkColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixIcon: suffixIcon,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom dropdown field to maintain consistent design
  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor.withOpacity(0.7),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: greenColor),
                style: TextStyle(
                  fontSize: 16,
                  color: darkColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar
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
                          'Modifier l\'élève',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          idController.text.isNotEmpty 
                              ? "ID: ${idController.text}" 
                              : "Données de l'élève",
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
          ),
          
          // Loading indicator or Form content
          isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Chargement des données...",
                          style: TextStyle(
                            fontSize: 16,
                            color: darkColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Form Section Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: orangeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: orangeColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Informations personnelles",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Personal Information Fields
                              _buildInputField(
                                controller: nameController,
                                label: "Nom",
                              ),
                              _buildInputField(
                                controller: surnameController,
                                label: "Prénom",
                              ),
                              _buildInputField(
                                controller: TextEditingController(text: selectedDate),
                                label: "Date de naissance",
                                readOnly: true,
                                suffixIcon: Icon(Icons.calendar_today, color: greenColor),
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: greenColor,
                                            onPrimary: Colors.white,
                                            onSurface: darkColor,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      selectedDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                    });
                                  }
                                },
                              ),
                              _buildInputField(
                                controller: idController,
                                label: "ID Élève",
                                readOnly: true,
                              ),
                            ],
                          ),
                        ),
                        
                        // Academic Information Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: greenColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.school,
                                      color: greenColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Informations académiques",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Academic Fields
                              _buildDropdownField<String>(
                                label: "Niveau d'étude",
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
                              _buildDropdownField<String>(
                                label: "Année scolaire",
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
                              
                              // Class Selection
                              Container(
                                margin: EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10.0),
                                      child: Text(
                                        "Sélectionner une classe",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: darkColor,
                                        ),
                                      ),
                                    ),
                                    availableClasses.isEmpty
                                      ? Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.warning_amber_rounded, color: Colors.red),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  "Aucune classe disponible pour ce niveau et cette année!",
                                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Wrap(
                                          spacing: 10.0,
                                          runSpacing: 10.0,
                                          children: availableClasses.map((classe) {
                                            bool isSelected = selectedClass != null && 
                                                selectedClass!["idClasse"] == classe["idClasse"];
                                            return InkWell(
                                              onTap: () {
                                                setState(() {
                                                  selectedClass = classe;
                                                  if (originalClassId != classe["idClasse"]) {
                                                    classChanged = true;
                                                  }
                                                });
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: isSelected 
                                                      ? greenColor 
                                                      : Colors.grey.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: Text(
                                                  "CLASSE ${classe["numeroClasse"]}",
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : darkColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Save Button
                        Container(
                          height: 55,
                          margin: EdgeInsets.only(bottom: 30),
                          child: ElevatedButton(
                            onPressed: _updateEleve,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              "Enregistrer les modifications",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}