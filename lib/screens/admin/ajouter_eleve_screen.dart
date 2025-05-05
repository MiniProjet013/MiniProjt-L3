import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AjouterEleveScreen extends StatefulWidget {
  const AjouterEleveScreen({Key? key}) : super(key: key);

  @override
  _AjouterEleveScreenState createState() => _AjouterEleveScreenState();
}

class _AjouterEleveScreenState extends State<AjouterEleveScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  
  String? selectedDate;
  String? selectedLevel;
  String? selectedYear;
  Map<String, dynamic>? selectedClass;
  List<Map<String, dynamic>> availableClasses = [];
  bool isLoading = false;
  
  // Couleurs pour correspondre au ModifierEleveScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);
  
  // Listes de la même interface
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
    // Générer automatiquement un ID unique
    _generateUniqueId();
  }

  void _generateUniqueId() {
    // Générer un ID composé de l'année actuelle + un nombre aléatoire
    final DateTime now = DateTime.now();
    final String year = now.year.toString();
    final String randomDigits = (10000 + now.millisecondsSinceEpoch % 90000).toString();
    idController.text = "$randomDigits";
  }

  Future<void> _fetchClassesForSelectedLevelAndYear() async {
    if (selectedLevel == null || selectedYear == null) {
      setState(() {
        availableClasses = [];
      });
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
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
        selectedClass = null; // Réinitialiser la sélection
      });
    } catch (e) {
      print("❌ Erreur lors du chargement des classes: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec du chargement des classes!"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _saveEleve() async {
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
    
    setState(() {
      isLoading = true;
    });
    
    try {
      // 1. Vérifier si l'élève existe déjà
      DocumentSnapshot existingEleve = await _db.collection('eleves').doc(idEleve).get();
      if (existingEleve.exists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("⚠️ Un élève avec cet ID existe déjà!"),
          backgroundColor: Colors.amber,
        ));
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // 2. Créer l'élève dans la collection eleves
      Map<String, dynamic> eleveData = {
        "idEleve": idEleve,
        "nom": name,
        "prenom": surname,
        "dateNaissance": selectedDate,
        "niveau": selectedLevel,
        "anneeScolaire": selectedYear,
        "classeId": selectedClass!["idClasse"],
        "numeroClasse": selectedClass!["numeroClasse"],
        "dateCreation": FieldValue.serverTimestamp(),
      };
      
      await _db.collection('eleves').doc(idEleve).set(eleveData);
      
      // 3. Ajouter l'élève à la classe sélectionnée
      await _db.collection('classes').doc(selectedClass!["idClasse"]).set({
        "eleves": {
          idEleve: {
            "nom": name,
            "prenom": surname,
          }
        }
      }, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Élève ajouté avec succès!"),
        backgroundColor: greenColor,
      ));
      
      // Réinitialiser le formulaire ou revenir à l'écran précédent
      Navigator.pop(context, true);
    } catch (e) {
      print("❌ Erreur lors de l'ajout de l'élève: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec de l'ajout! Réessayez."),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Widget de champ de saisie personnalisé avec cadre
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
        border: Border.all(
          color: darkColor.withOpacity(0.2),
          width: 1.0,
        ),
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

  // Widget de menu déroulant personnalisé avec cadre
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
        border: Border.all(
          color: darkColor.withOpacity(0.2),
          width: 1.0,
        ),
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
          // AppBar avec gradient
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
                          'Ajouter un élève',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Nouvel élève",
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
          
          // Formulaire ou indicateur de chargement
          isLoading && availableClasses.isEmpty
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
                        // Section des informations personnelles
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
                                      Icons.person_add,
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
                              
                              // Champs des informations personnelles
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
                                label: "ID Élève (généré automatiquement)",
                                readOnly: true,
                              ),
                            ],
                          ),
                        ),
                        
                        // Section des informations académiques
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
                              
                              // Champs académiques
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
                              
                              // Sélection de classe
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
                                    isLoading && selectedLevel != null && selectedYear != null
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(greenColor),
                                          ),
                                        )
                                      : availableClasses.isEmpty && selectedLevel != null && selectedYear != null
                                        ? Container(
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.red.withOpacity(0.3),
                                                width: 1.0,
                                              ),
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
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: isSelected 
                                                        ? greenColor 
                                                        : Colors.grey.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(30),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? greenColor
                                                          : darkColor.withOpacity(0.2),
                                                      width: 1.0,
                                                    ),
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
                        
                        // Bouton d'enregistrement
                        Container(
                          height: 55,
                          margin: EdgeInsets.only(bottom: 30),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _saveEleve,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Ajouter l'élève",
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